#!/bin/bash

# Define backup directory
BACKUP_DIR="./backups"

# Check if a database backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <database-backup-file.sql.gz> [drupal-files-backup.tar.gz]"
    echo "Example: $0 drupal-db-backup-20240226123456.sql.gz drupal-files-backup-20240226123456.tar.gz"
    
    echo -e "\nAvailable backups:"
    echo "Database backups:"
    ls -lh $BACKUP_DIR/drupal-db-backup-*.sql.gz 2>/dev/null || echo "  No database backups found."
    echo "Files backups:"
    ls -lh $BACKUP_DIR/drupal-files-backup-*.tar.gz 2>/dev/null || echo "  No file backups found."
    
    exit 1
fi

DB_BACKUP_FILE=$1
FILES_BACKUP_FILE=$2

# Check if provided database backup file exists
if [ ! -f "$BACKUP_DIR/$DB_BACKUP_FILE" ]; then
    echo "Error: Database backup file $BACKUP_DIR/$DB_BACKUP_FILE not found!"
    exit 1
fi

echo "=== Starting restoration process ==="

# Restore MySQL database
echo "Restoring MySQL database from $DB_BACKUP_FILE..."
gunzip < $BACKUP_DIR/$DB_BACKUP_FILE | sudo docker exec -i mysql_container sh -c "exec mysql -uroot -p'my-secret-pw' --force"

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
    
    # Restore files
    sudo docker run --rm --volumes-from drupal_container -v $(pwd)/$BACKUP_DIR:/backup ubuntu bash -c "cd / && tar xzvf /backup/$FILES_BACKUP_FILE"
    
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

# Optional: Pull latest code from Git repository
if [ ! -z "$3" ] && [ "$3" = "--pull-git" ]; then
    GIT_REPO_PATH=${4:-"/path/to/drupal/git/repo"}
    
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
