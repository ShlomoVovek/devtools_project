#!/bin/bash

# Define backup directory
BACKUP_DIR="./backups"

# Define how many days of backups to keep
DAYS_TO_KEEP=7

echo "=== Starting cleanup process ==="

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory not found. Nothing to clean up."
else
    # Count total backups before cleanup
    TOTAL_BACKUPS=$(find $BACKUP_DIR -type f | wc -l)
    
    echo "Found $TOTAL_BACKUPS backup files in $BACKUP_DIR"
    
    # Remove old database backups (older than $DAYS_TO_KEEP days)
    echo "Cleaning up old database backups..."
    OLD_DB_BACKUPS=$(find $BACKUP_DIR -name "drupal-db-backup-*.sql.gz" -type f -mtime +$DAYS_TO_KEEP)
    if [ -z "$OLD_DB_BACKUPS" ]; then
        echo "  No old database backups to remove."
    else
        find $BACKUP_DIR -name "drupal-db-backup-*.sql.gz" -type f -mtime +$DAYS_TO_KEEP -delete
        echo "  Removed old database backups successfully."
    fi
    
    # Remove old file backups (older than $DAYS_TO_KEEP days)
    echo "Cleaning up old Drupal files backups..."
    OLD_FILES_BACKUPS=$(find $BACKUP_DIR -name "drupal-files-backup-*.tar.gz" -type f -mtime +$DAYS_TO_KEEP)
    if [ -z "$OLD_FILES_BACKUPS" ]; then
        echo "  No old file backups to remove."
    else
        find $BACKUP_DIR -name "drupal-files-backup-*.tar.gz" -type f -mtime +$DAYS_TO_KEEP -delete
        echo "  Removed old file backups successfully."
    fi
    
    # Count remaining backups
    REMAINING_BACKUPS=$(find $BACKUP_DIR -type f | wc -l)
    REMOVED_BACKUPS=$((TOTAL_BACKUPS - REMAINING_BACKUPS))
    
    echo "Removed $REMOVED_BACKUPS old backup files. $REMAINING_BACKUPS backups remaining."
fi

# Clean up Docker system
echo "Cleaning up Docker resources..."

# Remove unused containers
echo "Removing stopped containers..."
sudo docker container prune -f

# Remove unused images
echo "Removing dangling images..."
sudo docker image prune -f

# Remove unused volumes (with caution)
echo "Checking for unused volumes (excluding drupal volumes)..."
UNUSED_VOLUMES=$(sudo docker volume ls -qf dangling=true | grep -v "drupal")
if [ -z "$UNUSED_VOLUMES" ]; then
    echo "  No unused volumes to remove."
else
    sudo docker volume rm $UNUSED_VOLUMES
    echo "  Removed unused volumes."
fi

# Remove unused networks (with caution to avoid removing drupal_network)
echo "Checking for unused networks (excluding drupal_network)..."
UNUSED_NETWORKS=$(sudo docker network ls -qf dangling=true | grep -v "drupal_network")
if [ -z "$UNUSED_NETWORKS" ]; then
    echo "  No unused networks to remove."
else
    sudo docker network rm $UNUSED_NETWORKS
    echo "  Removed unused networks."
fi

# Clean Docker build cache
echo "Cleaning Docker build cache..."
sudo docker builder prune -f

# Display Docker disk usage after cleanup
echo "Current Docker disk usage:"
sudo docker system df

echo "=== Cleanup process completed ==="
