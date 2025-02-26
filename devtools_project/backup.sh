#!/bin/bash

# Define backup directory
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

echo "=== Starting backup process ==="

# Ask user which backup naming format to use
echo "Choose backup naming format:"
echo "1. Standard names (drupal-db-backup.sql.gz, drupal-files-backup.tar.gz)"
echo "2. Timestamped names (drupal-db-backup-$TIMESTAMP.sql.gz, drupal-files-backup-$TIMESTAMP.tar.gz)"
echo "3. Both formats (create backups with both naming conventions)"
read -p "Enter your choice (1-3): " FORMAT_CHOICE

case $FORMAT_CHOICE in
    1) 
        DB_BACKUP_FILE="drupal-db-backup.sql.gz"
        FILES_BACKUP_FILE="drupal-files-backup.tar.gz"
        ;;
    2) 
        DB_BACKUP_FILE="drupal-db-backup-$TIMESTAMP.sql.gz"
        FILES_BACKUP_FILE="drupal-files-backup-$TIMESTAMP.tar.gz"
        ;;
    3) 
        BOTH_FORMATS=true
        DB_BACKUP_FILE="drupal-db-backup-$TIMESTAMP.sql.gz"
        FILES_BACKUP_FILE="drupal-files-backup-$TIMESTAMP.tar.gz"
        DB_STANDARD_FILE="drupal-db-backup.sql.gz"
        FILES_STANDARD_FILE="drupal-files-backup.tar.gz"
        ;;
    *) 
        echo "Invalid choice. Using timestamped format as default."
        DB_BACKUP_FILE="drupal-db-backup-$TIMESTAMP.sql.gz"
        FILES_BACKUP_FILE="drupal-files-backup-$TIMESTAMP.tar.gz"
        ;;
esac

# Backup MySQL database (compressed)
echo "Backing up MySQL database..."
if sudo docker exec mysql_container sh -c 'exec mysqldump --single-transaction --quick --lock-tables=false --all-databases -uroot -p"my-secret-pw"' | gzip > $BACKUP_DIR/$DB_BACKUP_FILE; then
    echo "MySQL database backup created: $BACKUP_DIR/$DB_BACKUP_FILE"
    
    # Create standard format backup if both formats are requested
    if [ "$BOTH_FORMATS" = true ]; then
        cp $BACKUP_DIR/$DB_BACKUP_FILE $BACKUP_DIR/$DB_STANDARD_FILE
        echo "Additional standard format backup created: $BACKUP_DIR/$DB_STANDARD_FILE"
    fi
    
    # Verify the compressed backup
    echo "Verifying MySQL backup..."
    if gzip -t $BACKUP_DIR/$DB_BACKUP_FILE; then
        echo "MySQL backup is valid."
    else
        echo "MySQL backup verification failed!"
        exit 1
    fi
else
    echo "MySQL backup failed!"
    exit 1
fi

# Backup Drupal files
echo "Backing up Drupal files..."
if sudo docker run --rm --volumes-from drupal_container -v $(pwd)/$BACKUP_DIR:/backup ubuntu tar czvf /backup/$FILES_BACKUP_FILE /var/www/html; then
    echo "Drupal files backup created: $BACKUP_DIR/$FILES_BACKUP_FILE"
    
    # Create standard format backup if both formats are requested
    if [ "$BOTH_FORMATS" = true ]; then
        cp $BACKUP_DIR/$FILES_BACKUP_FILE $BACKUP_DIR/$FILES_STANDARD_FILE
        echo "Additional standard format backup created: $BACKUP_DIR/$FILES_STANDARD_FILE"
    fi
    
    echo "Drupal files backup completed successfully."
else
    echo "Drupal files backup failed!"
    exit 1
fi

# Display backup information
if [ "$BOTH_FORMATS" = true ]; then
    # Get sizes for both formats
    DBSIZE=$(du -h $BACKUP_DIR/$DB_BACKUP_FILE | cut -f1)
    FILESSIZE=$(du -h $BACKUP_DIR/$FILES_BACKUP_FILE | cut -f1)
    
    echo ""
    echo "=== Backup Summary ==="
    echo "Timestamped backups:"
    echo "  Database: $BACKUP_DIR/$DB_BACKUP_FILE ($DBSIZE)"
    echo "  Files: $BACKUP_DIR/$FILES_BACKUP_FILE ($FILESSIZE)"
    echo ""
    echo "Standard backups (symlinks to current backups):"
    echo "  Database: $BACKUP_DIR/$DB_STANDARD_FILE"
    echo "  Files: $BACKUP_DIR/$FILES_STANDARD_FILE"
    echo ""
    echo "Backup completed at: $(date)"
    echo "======================"
else
    # Get sizes for single format
    DBSIZE=$(du -h $BACKUP_DIR/$DB_BACKUP_FILE | cut -f1)
    FILESSIZE=$(du -h $BACKUP_DIR/$FILES_BACKUP_FILE | cut -f1)
    
    echo ""
    echo "=== Backup Summary ==="
    echo "Database backup: $BACKUP_DIR/$DB_BACKUP_FILE ($DBSIZE)"
    echo "Files backup: $BACKUP_DIR/$FILES_BACKUP_FILE ($FILESSIZE)"
    echo "Backup completed at: $(date)"
    echo "======================"
fi

# List all backups in the backup directory
echo ""
echo "All available backups:"
echo "Database backups:"
ls -lh $BACKUP_DIR/drupal-db-backup*.sql.gz | sort
echo ""
echo "Files backups:"
ls -lh $BACKUP_DIR/drupal-files-backup*.tar.gz | sort
