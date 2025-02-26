#!/bin/bash

# Define backup directory
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

echo "Starting backup process..."

# Backup MySQL database (compressed)
echo "Backing up MySQL database..."
sudo docker exec mysql_container sh -c 'exec mysqldump --single-transaction --quick --lock-tables=false --all-databases -uroot -p"my-secret-pw"' | gzip > $BACKUP_DIR/drupal-db-backup-$TIMESTAMP.sql.gz

# Verify the compressed backup
echo "Verifying MySQL backup..."
if gzip -t $BACKUP_DIR/drupal-db-backup-$TIMESTAMP.sql.gz; then
    echo "MySQL backup is valid."
else
    echo "MySQL backup verification failed!"
    exit 1
fi

# Backup Drupal files
echo "Backing up Drupal files..."
sudo docker run --rm --volumes-from drupal_container -v $(pwd)/$BACKUP_DIR:/backup ubuntu tar czvf /backup/drupal-files-backup-$TIMESTAMP.tar.gz /var/www/html

# Check if Drupal files backup was successful
if [ $? -eq 0 ]; then
    echo "Drupal files backup completed successfully."
else
    echo "Drupal files backup failed!"
    exit 1
fi

# Display backup information
DBSIZE=$(du -h $BACKUP_DIR/drupal-db-backup-$TIMESTAMP.sql.gz | cut -f1)
FILESSIZE=$(du -h $BACKUP_DIR/drupal-files-backup-$TIMESTAMP.tar.gz | cut -f1)

echo ""
echo "=== Backup Summary ==="
echo "Database backup: $BACKUP_DIR/drupal-db-backup-$TIMESTAMP.sql.gz ($DBSIZE)"
echo "Files backup: $BACKUP_DIR/drupal-files-backup-$TIMESTAMP.tar.gz ($FILESSIZE)"
echo "Backup completed at: $(date)"
echo "======================"
