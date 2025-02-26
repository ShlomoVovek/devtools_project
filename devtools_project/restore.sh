#!/bin/bash

# Define backup directory
BACKUP_DIR="./backups"

# Function to list available backups
list_available_backups() {
    echo -e "\nAvailable backups:"
    echo "Database backups:"
    ls -lh $BACKUP_DIR/drupal-db-backup*.sql* 2>/dev/null | sort || echo "  No database backups found."
    echo "Files backups:"
    ls -lh $BACKUP_DIR/drupal-files-backup*.tar* 2>/dev/null | sort || echo "  No file backups found."
}

# Check arguments and show available backups if none provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [database-backup-file] [drupal-files-backup] [--pull-git] [git-repo-path]"
    echo "Default: Uses most recent backup if available"
    
    list_available_backups
    
    echo -e "\nChoose backup format to restore:"
    echo "1. Standard names (drupal-db-backup.sql.gz, drupal-files-backup.tar.gz)"
    echo "2. Most recent timestamped backup"
    echo "3. Specify files manually"
    read -p "Enter your choice (1-3): " FORMAT_CHOICE
    
    case $FORMAT_CHOICE in
        1) 
            # Check for standard filenames
            if [ -f "$BACKUP_DIR/drupal-db-backup.sql.gz" ]; then
                echo -e "\nFound compressed database backup. Using drupal-db-backup.sql.gz"
                DB_BACKUP_FILE="drupal-db-backup.sql.gz"
            elif [ -f "$BACKUP_DIR/drupal-db-backup.sql" ]; then
                echo -e "\nFound uncompressed database backup. Using drupal-db-backup.sql"
                DB_BACKUP_FILE="drupal-db-backup.sql"
            else
                echo "Standard database backup not found."
                exit 1
            fi
            
            # Check for files backup
            if [ -f "$BACKUP_DIR/drupal-files-backup.tar.gz" ]; then
                echo "Found compressed files backup. Using drupal-files-backup.tar.gz"
                FILES_BACKUP_FILE="drupal-files-backup.tar.gz"
            elif [ -f "$BACKUP_DIR/drupal-files-backup.tar" ]; then
                echo "Found uncompressed files backup. Using drupal-files-backup.tar"
                FILES_BACKUP_FILE="drupal-files-backup.tar"
            else
                echo "No standard files backup found. Skipping files restoration."
                FILES_BACKUP_FILE=""
            fi
            ;;
        2) 
            # Find most recent timestamped database backup
            LATEST_DB=$(ls -t $BACKUP_DIR/drupal-db-backup-*.sql.gz 2>/dev/null | head -n 1)
            if [ -z "$LATEST_DB" ]; then
                LATEST_DB=$(ls -t $BACKUP_DIR/drupal-db-backup-*.sql 2>/dev/null | head -n 1)
            fi
            
            if [ -z "$LATEST_DB" ]; then
                echo "No timestamped database backup found."
                exit 1
            else
                DB_BACKUP_FILE=$(basename "$LATEST_DB")
                echo -e "\nUsing most recent database backup: $DB_BACKUP_FILE"
            fi
            
            # Find most recent timestamped files backup
            LATEST_FILES=$(ls -t $BACKUP_DIR/drupal-files-backup-*.tar.gz 2>/dev/null | head -n 1)
            if [ -z "$LATEST_FILES" ]; then
                LATEST_FILES=$(ls -t $BACKUP_DIR/drupal-files-backup-*.tar 2>/dev/null | head -n 1)
            fi
            
            if [ -z "$LATEST_FILES" ]; then
                echo "No timestamped files backup found. Skipping files restoration."
                FILES_BACKUP_FILE=""
            else
                FILES_BACKUP_FILE=$(basename "$LATEST_FILES")
                echo "Using most recent files backup: $FILES_BACKUP_FILE"
            fi
            ;;
        3)
            # Ask user to specify files
            list_available_backups
            echo ""
            read -p "Enter database backup filename: " DB_BACKUP_FILE
            read -p "Enter files backup filename (leave empty to skip): " FILES_BACKUP_FILE
            ;;
        *) 
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    # Use provided filenames
    DB_BACKUP_FILE=$1
    FILES_BACKUP_FILE=$2
fi

# Check if provided database backup file exists
if [ ! -f "$BACKUP_DIR/$DB_BACKUP_FILE" ]; then
    echo "Error: Database backup file $BACKUP_DIR/$DB_BACKUP_FILE not found!"
    exit 1
fi

echo "=== Starting restoration process ==="

# Restore MySQL database
echo "Restoring MySQL database from $DB_BACKUP_FILE..."
# Handle both compressed and non-compressed files
if [[ "$DB_BACKUP_FILE" == *.gz ]]; then
    # For compressed .sql.gz files
    gunzip < $BACKUP_DIR/$DB_BACKUP_FILE | sudo docker exec -i mysql_container sh -c "exec mysql -uroot -p'my-secret-pw' --force"
else
    # For uncompressed .sql files
    cat $BACKUP_DIR/$DB_BACKUP_FILE | sudo docker exec -i mysql_container sh -c "exec mysql -uroot -p'my-secret-pw' --force"
fi

if [ $? -eq 0 ]; then
    echo "Database restoration completed successfully."
else
    echo "Database restoration failed!"
    exit 1
fi

# Restore Drupal files if provided
if [ ! -z "$FILES_BACKUP_FILE" ]; then
    if [ ! -f "$BACKUP_DIR/$FILES_BACKUP_FILE" ]; then
        echo "Error: Drupal files backup $BACKUP_DIR/$FILES_BACKUP_FILE not found!"
        exit 1
    fi
    
    echo "Restoring Drupal files from $FILES_BACKUP_FILE..."
    sudo docker stop drupal_container
    
    # Handle both compressed and non-compressed tar files
    if [[ "$FILES_BACKUP_FILE" == *.gz ]]; then
        # For compressed .tar.gz files
        sudo docker run --rm --volumes-from drupal_container -v $(pwd)/$BACKUP_DIR:/backup ubuntu bash -c "cd / && tar xzvf /backup/$FILES_BACKUP_FILE"
    else
        # For uncompressed .tar files
        sudo docker run --rm --volumes-from drupal_container -v $(pwd)/$BACKUP_DIR:/backup ubuntu bash -c "cd / && tar xvf /backup/$FILES_BACKUP_FILE"
    fi
    
    if [ $? -eq 0 ]; then
        echo "Drupal files restoration completed successfully."
    else
        echo "Drupal files restoration failed!"
        sudo docker start drupal_container
        exit 1
    fi
    
    # Restart Drupal container
    sudo docker start drupal_container
    echo "Drupal container restarted."
else
    echo "No Drupal files backup specified, skipping files restoration."
fi

# Check if we need to run Drupal updates
echo "Note: You may need to run Drupal database updates if you've restored from an older backup."
echo "Visit http://localhost:8080/update.php in your browser if necessary."

# Check for --pull-git flag
shift 2 2>/dev/null  # Shift past the backup filenames
if [ "$1" = "--pull-git" ]; then
    GIT_REPO_PATH=${2:-"/path/to/drupal/git/repo"}
    
    if [ -d "$GIT_REPO_PATH/.git" ]; then
        echo "Pulling latest code from Git repository..."
        cd $GIT_REPO_PATH
        git pull origin main
        echo "Git pull completed."
        
        # Copy updated files to Drupal container if needed
        # sudo docker cp $GIT_REPO_PATH/. drupal_container:/var/www/html/
    else
        echo "Git repository not found at $GIT_REPO_PATH"
    fi
fi

echo "=== Restoration process completed ==="
echo "Drupal website should be available at http://localhost:8080"
