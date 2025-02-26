#!/bin/bash

# Define backup directory
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Define how many days of backups to keep (default: 7)
DAYS_TO_KEEP=${1:-7}

# Define containers to completely remove
REMOVE_CONTAINERS="drupal_container mysql_container"

echo "=== Starting cleanup process ==="
echo "Current date and time: $(date)"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory not found. Creating one..."
    mkdir -p $BACKUP_DIR
    echo "Backup directory created at: $BACKUP_DIR"
else
    # Count total backups before cleanup
    TOTAL_BACKUPS=$(find $BACKUP_DIR -type f | wc -l)
    
    echo "Found $TOTAL_BACKUPS backup files in $BACKUP_DIR"
    
    # Ask user what type of cleanup to perform
    echo -e "\nChoose cleanup type:"
    echo "1. Remove backups older than $DAYS_TO_KEEP days (default)"
    echo "2. Keep only the most recent N backups"
    echo "3. Remove specific backup file(s)"
    echo "4. Skip backup file cleanup"
    read -p "Enter your choice (1-4): " CLEANUP_CHOICE
    
    case $CLEANUP_CHOICE in
        1) 
            echo -e "\nRemoving backups older than $DAYS_TO_KEEP days..."
            
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
            ;;
        2)
            read -p "How many recent backups would you like to keep? " NUM_TO_KEEP
            
            echo -e "\nKeeping only the $NUM_TO_KEEP most recent backups..."
            
            # Handle database backups
            DB_BACKUPS_COUNT=$(find $BACKUP_DIR -name "drupal-db-backup*.sql*" -type f | wc -l)
            if [ $DB_BACKUPS_COUNT -gt $NUM_TO_KEEP ]; then
                echo "Found $DB_BACKUPS_COUNT database backups, keeping most recent $NUM_TO_KEEP"
                find $BACKUP_DIR -name "drupal-db-backup*.sql*" -type f | sort | head -n -$NUM_TO_KEEP | xargs rm -f
                echo "  Removed $(($DB_BACKUPS_COUNT - $NUM_TO_KEEP)) old database backups."
            else
                echo "  Only $DB_BACKUPS_COUNT database backups found. Nothing to remove."
            fi
            
            # Handle files backups
            FILES_BACKUPS_COUNT=$(find $BACKUP_DIR -name "drupal-files-backup*.tar*" -type f | wc -l)
            if [ $FILES_BACKUPS_COUNT -gt $NUM_TO_KEEP ]; then
                echo "Found $FILES_BACKUPS_COUNT file backups, keeping most recent $NUM_TO_KEEP"
                find $BACKUP_DIR -name "drupal-files-backup*.tar*" -type f | sort | head -n -$NUM_TO_KEEP | xargs rm -f
                echo "  Removed $(($FILES_BACKUPS_COUNT - $NUM_TO_KEEP)) old file backups."
            else
                echo "  Only $FILES_BACKUPS_COUNT file backups found. Nothing to remove."
            fi
            ;;
        3)
            # List available backups
            echo -e "\nAvailable backups:"
            echo "Database backups:"
            ls -lh $BACKUP_DIR/drupal-db-backup*.sql* 2>/dev/null | sort || echo "  No database backups found."
            echo -e "\nFiles backups:"
            ls -lh $BACKUP_DIR/drupal-files-backup*.tar* 2>/dev/null | sort || echo "  No file backups found."
            
            echo -e "\nEnter the filename(s) you want to delete (space-separated):"
            read -p "> " FILES_TO_REMOVE
            
            for file in $FILES_TO_REMOVE; do
                if [ -f "$BACKUP_DIR/$file" ]; then
                    rm -f "$BACKUP_DIR/$file"
                    echo "Deleted: $BACKUP_DIR/$file"
                else
                    echo "File not found: $BACKUP_DIR/$file"
                fi
            done
            ;;
        4)
            echo "Skipping backup file cleanup."
            ;;
        *)
            echo "Invalid choice. Using default (option 1)."
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
            ;;
    esac
    
    # Count remaining backups
    REMAINING_BACKUPS=$(find $BACKUP_DIR -type f | wc -l)
    REMOVED_BACKUPS=$((TOTAL_BACKUPS - REMAINING_BACKUPS))
    
    echo -e "\nRemoved $REMOVED_BACKUPS backup files. $REMAINING_BACKUPS backups remaining."
    
    # Display backup information
    if [ $REMAINING_BACKUPS -gt 0 ]; then
        echo -e "\nRemaining backups:"
        echo "Database backups:"
        ls -lh $BACKUP_DIR/drupal-db-backup*.sql.gz 2>/dev/null | sort || echo "  No database backups found."
        echo -e "\nFiles backups:"
        ls -lh $BACKUP_DIR/drupal-files-backup*.tar.gz 2>/dev/null | sort || echo "  No file backups found."
    fi
fi

# Ask if user wants to proceed with Docker cleanup
echo -e "\n=== Docker Cleanup ==="
echo "Do you want to proceed with Docker cleanup?"
echo "1. Full cleanup (containers, volumes, and Docker system)"
echo "2. System cleanup only (keep containers and volumes)"
echo "3. Skip Docker cleanup entirely"
read -p "Enter your choice (1-3): " DOCKER_CLEANUP_CHOICE

case $DOCKER_CLEANUP_CHOICE in
    1)
        # Clean up Docker containers
        echo -e "\n=== Docker container cleanup ==="
        
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
            echo "Deletion cancelled. No container changes were made."
        else
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
        fi
        
        # Clean up other Docker resources (proceed with system cleanup)
        echo -e "\n=== Docker system cleanup ==="
        ;;
    2)
        # Skip container cleanup but proceed with system cleanup
        echo -e "\nSkipping container cleanup."
        echo -e "\n=== Docker system cleanup ==="
        ;;
    3)
        # Skip all Docker cleanup
        echo -e "\nSkipping all Docker cleanup."
        echo -e "\n=== Cleanup process completed ==="
        echo "Backup cleanup: $REMOVED_BACKUPS files removed. $REMAINING_BACKUPS backups remaining."
        echo "Docker cleanup: Skipped"
        echo "Completed at: $(date)"
        exit 0
        ;;
    *)
        echo "Invalid choice. Skipping Docker cleanup."
        echo -e "\n=== Cleanup process completed ==="
        echo "Backup cleanup: $REMOVED_BACKUPS files removed. $REMAINING_BACKUPS backups remaining."
        echo "Docker cleanup: Skipped"
        echo "Completed at: $(date)"
        exit 0
        ;;
esac

# Only proceed with system cleanup if options 1 or 2 were selected
if [[ "$DOCKER_CLEANUP_CHOICE" == "1" || "$DOCKER_CLEANUP_CHOICE" == "2" ]]; then
    echo -e "Cleaning up Docker system resources..."
    
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
fi

echo -e "\n=== Cleanup Summary ==="
echo "Backup cleanup: $REMOVED_BACKUPS files removed. $REMAINING_BACKUPS backups remaining."
echo "Docker cleanup: Completed"
echo "Completed at: $(date)"

# Show running containers after cleanup
echo -e "\nRemaining running containers:"
sudo docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
