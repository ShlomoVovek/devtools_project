#!/bin/bash

# Define backup directory
BACKUP_DIR="./backups"

# Define how many days of backups to keep
DAYS_TO_KEEP=7

# Define containers to completely remove
REMOVE_CONTAINERS="drupal_container mysql_container"

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
    OLD_DB_BACKUPS=$(find $BACKUP_DIR -name "drupal-db-backup*.sql*" -type f -mtime +$DAYS_TO_KEEP)
    if [ -z "$OLD_DB_BACKUPS" ]; then
        echo "  No old database backups to remove."
    else
        find $BACKUP_DIR -name "drupal-db-backup*.sql*" -type f -mtime +$DAYS_TO_KEEP -delete
        echo "  Removed old database backups successfully."
    fi
    
    # Remove old file backups (older than $DAYS_TO_KEEP days)
    echo "Cleaning up old Drupal files backups..."
    OLD_FILES_BACKUPS=$(find $BACKUP_DIR -name "drupal-files-backup*.tar*" -type f -mtime +$DAYS_TO_KEEP)
    if [ -z "$OLD_FILES_BACKUPS" ]; then
        echo "  No old file backups to remove."
    else
        find $BACKUP_DIR -name "drupal-files-backup*.tar*" -type f -mtime +$DAYS_TO_KEEP -delete
        echo "  Removed old file backups successfully."
    fi
    
    # Count remaining backups
    REMAINING_BACKUPS=$(find $BACKUP_DIR -type f | wc -l)
    REMOVED_BACKUPS=$((TOTAL_BACKUPS - REMAINING_BACKUPS))
    
    echo "Removed $REMOVED_BACKUPS old backup files. $REMAINING_BACKUPS backups remaining."
fi

# Clean up Docker system
echo -e "\n=== Docker cleanup ==="

# Show current running containers
echo -e "\nCurrently running Docker containers:"
sudo docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}"

# Warning about data loss
echo -e "\n!!! WARNING !!!"
echo "You are about to PERMANENTLY DELETE the following containers and ALL THEIR DATA:"
for container in $REMOVE_CONTAINERS; do
    echo "  - $container"
done
echo "This will delete your Drupal website and MySQL database!"
echo "This action CANNOT BE UNDONE!"

# Confirm deletion
read -p "Are you ABSOLUTELY SURE you want to continue? Type 'DELETE ALL DATA' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE ALL DATA" ]; then
    echo "Deletion cancelled. No changes were made."
    exit 1
fi

echo -e "\nProceeding with container and data removal..."

# Stop and remove the specified containers
for container in $REMOVE_CONTAINERS; do
    # Check if container exists
    if sudo docker ps -a --format "{{.Names}}" | grep -q "^$container$"; then
        echo "Processing container: $container"
        
        # Check if container is running and stop it
        if sudo docker ps --format "{{.Names}}" | grep -q "^$container$"; then
            echo "  - Stopping container $container"
            sudo docker stop $container
        fi
        
        # Remove container with force option
        echo "  - Removing container $container"
        sudo docker rm -f $container
        echo "  ✓ Container $container removed"
    else
        echo "Container $container not found. Skipping."
    fi
done

# Remove associated volumes
echo -e "\nRemoving associated volumes..."

# Find and remove volumes related to drupal and mysql
DRUPAL_VOLUMES=$(sudo docker volume ls --format "{{.Name}}" | grep -E "drupal|mysql")
if [ -z "$DRUPAL_VOLUMES" ]; then
    echo "No Drupal or MySQL volumes found."
else
    echo "Found the following volumes to remove:"
    echo "$DRUPAL_VOLUMES"
    
    # Confirm volume deletion
    read -p "Remove these volumes? This will delete ALL DATA. Type 'YES' to confirm: " CONFIRM_VOLUMES
    
    if [ "$CONFIRM_VOLUMES" == "YES" ]; then
        for volume in $DRUPAL_VOLUMES; do
            echo "  - Removing volume: $volume"
            sudo docker volume rm $volume
        done
        echo "  ✓ All Drupal and MySQL volumes removed"
    else
        echo "Volume deletion cancelled."
    fi
fi

# Clean up other Docker resources
echo -e "\nCleaning up remaining Docker resources..."

# Remove all stopped containers
echo "Removing all stopped containers..."
sudo docker container prune -f

# Remove unused images
echo "Removing dangling images..."
sudo docker image prune -f

# Remove unused networks
echo "Removing unused networks..."
sudo docker network prune -f

# Clean Docker build cache
echo "Cleaning Docker build cache..."
sudo docker builder prune -f

# Option for deep cleaning
read -p "Do you want to perform a deep clean (remove ALL unused Docker resources)? (y/n): " DEEP_CLEAN
if [[ "$DEEP_CLEAN" == "y" || "$DEEP_CLEAN" == "Y" ]]; then
    echo "Performing deep clean of ALL unused Docker resources..."
    sudo docker system prune -a -f --volumes
    echo "Deep clean completed."
fi

# Display Docker disk usage after cleanup
echo -e "\nCurrent Docker disk usage:"
sudo docker system df

echo -e "\n=== Cleanup process completed ==="

# Show running containers after cleanup
echo -e "\nRemaining running containers:"
sudo docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
