Drupal Docker Setup
A comprehensive solution for setting up, backing up, restoring, and cleaning up a Drupal website using Docker containers.

TL;DR:

    Ensure that the scripts have execute permissions (chmod +x scriptname.sh)
    Download the project
    Run ./setup.sh to initialize the Docker containers
    Access your Drupal site at http://localhost:8080
    Use ./backup.sh for creating backups
    Use ./restore.sh for restoring from backups
    Use ./cleanup.sh to remove old backups and clean Docker resources

a. We are Amit Bar-Kama, Software Engineering student and Shlomi Vovek, Computer Science student.

b. Project Overview
This project utilizes Docker to containerize a Drupal website and its MySQL database, creating a portable and reproducible environment. The setup is automated using bash scripts for ease of use. It includes backup and restore functionality to ensure data integrity.
   
c. We devided the work between us, created this project by the instruction and used some help from youtube.com videos and Generative AI tools as well as Docker documentation for its functions, special flags and interfacing with MySQL and Drupal.

d. Technologies Used

    * Docker: Containerization platform
    * Drupal: Open-source content management system
    * MySQL: Database management system
    * Ubuntu: Operating system
    * Bash: Scripting language for automation

Prerequisites

    * Ubuntu machine (virtual or physical)
    * Basic familiarity with the command line
    
e. Drupal Website Setup with Docker: User Guide:

    This guide will walk you through setting up a Drupal website using Docker containers on an Ubuntu machine,
    including initialization,backups, restoration, and cleanup.To use these scripts, you'll need to follow these steps:
  
  1. Initial Setup (setup.sh):

    Open a terminal in the directory containing your project scripts.
    Execute the setup script:
    
      ./setup.sh

    This script will:
    Install Docker if it's not already installed. Create a Docker network for the containers to communicate. Start the Drupal and MySQL containers. It will pull the necessary docker images.
    
    Accessing and Configuring Your Drupal Website:

    Determine the Drupal Container IP:
        Run docker ps to find the name of your drupal container.
        Run docker inspect <drupal_container_name> and find the IP address within the network settings.
        Alternatively, if you mapped the drupal port to your host machine you can access it through localhost.
    Open a Web Browser:
        Navigate to the IP address or localhost port of your Drupal container in your web browser.
    Drupal Installation:
        You'll be presented with the Drupal installation wizard.
        Follow the on-screen instructions to:
            Choose a language.
            Select an installation profile (e.g., Standard).
            Configure the database settings:
                Database Type: MySQL, Postgers, or equivalent.
                Database Name: The name of the database that was created by the setup.sh script.
                Database Username: The username that was set by the setup.sh script.
                Database Password: The password that was set by the setup.sh script.
                Host: The name of the mysql docker container.
                Port: 3306.
            Configure site information (site name, admin account).
    Post-Installation:
        Log in to your Drupal site as the administrator.
        Configure your site as needed (themes, modules, content).
    
  2. Backing Up Your Website (backup.sh):
     Create a backup of your Drupal website by running:
     
          ./backup.sh
When running the backup script, you'll be prompted to choose a backup naming format:
Standard names (drupal-db-backup.sql.gz, drupal-files-backup.tar.gz)
Timestamped names (drupal-db-backup-YYYYMMDDHHMMSS.sql.gz, drupal-files-backup-YYYYMMDDHHMMSS.tar.gz)
Both formats (creates backups with both naming conventions)

The script will:
Create a backup of the MySQL database
Create a backup of the Drupal files
Store the backups in the "./backups" directory
Verify the integrity of the backups
Display a summary of the backup operation
    
  3. Restoring Your Website (restore.sh):
Restore your website from existing backups:

    ./restore.sh [database-backup-file] [drupal-files-backup]
If you run the script without arguments, it will:

Display available backups
Prompt you to choose a backup format:

Standard names
Most recent timestamped backup
Specify files manually
The script handles both compressed and uncompressed backup files and provides feedback throughout the restoration process.

  4. Cleaning Up (cleanup.sh):
 To remove old backups and clean up Docker resources, execute the cleanup script:

      ./cleanup.sh

The default retention period is 7 days if not specified.
The script will prompt you to choose:

The type of backup cleanup:

Remove backups older than X days
Keep only the most recent N backups
Remove specific backup file(s)
Skip backup file cleanup


The type of Docker cleanup:

Full cleanup (containers, volumes, and Docker system)
System cleanup only (keep containers and volumes)
Skip Docker cleanup entirely



Warning: The full cleanup option will permanently delete your Drupal website and MySQL database!
    
  5. Automated Backups with Cron:

    To schedule regular backups, use cron:
      crontab -e
      
    Add a line like this to run backups daily at 2 AM:
     0 2 * * * /path/to/your/project/backup.sh

    Replace /path/to/your/project/ with the actual path to your project directory. Save and close the crontab file.
    
f. Important Notes

Ensure that the scripts have execute permissions (chmod +x scriptname.sh)
The Drupal website runs on port 8080 by default (http://localhost:8080)
MySQL uses "my-secret-pw" as the root password (you may want to change this in a production environment)
When restoring a database, the database being restored to must be empty
When restoring files, the files directory should be empty

Troubleshooting

If you encounter permission issues, ensure you have appropriate privileges (use sudo if needed)
Visit http://localhost:8080/update.php in your browser if you restore from an older backup
Check Docker logs if containers fail to start: docker logs drupal_container or docker logs mysql_container
