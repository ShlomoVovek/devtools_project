# devtools_project
Final Project In Devtools Course

TL;DR: 

    1) Ensure that the scripts have execute permissions (chmod +x scriptname.sh).
    2) Download the project
    3) Begin with the "setup.sh" script and then "restore.sh" if you want to load our exsiting data


a. We are Amit Bar-Kama, Software Engineering student and Shlomi Vovek, Computer Science student.

b. Project Overview:
  
    This project utilizes Docker to containerize a Drupal website and its MySQL database, creating a portable and reproducible environment. The setup is automated using bash scripts for ease of use. We've included backup and restore functionality to ensure data integrity.
   
c. We devided the work between us, created this project by the instruction and used some help from youtube.com videos and Generative AI tools as well as Docker documentation for its functions, special flags and interfacing with MySQL and Drupal.

d. Technologies Used:

    Docker: Containerization platform.
    Drupal: Open-source content management system.
    MySQL: Database management system.
    Ubuntu: Operating system.
    Bash: Scripting language for automation.
    Git/GitHub: Version control.
    Discord: Communication and collaboration.
    Claude.ai: Debugging assistance.
    Afeka Vlab: Ubuntu Virtual Machine environment.

Prerequisites:

    An Ubuntu machine (virtual or physical).
    Basic familiarity with the command line.
    
e. Drupal Website Setup with Docker: User Guide:

    This guide will walk you through setting up a Drupal website using Docker containers on an Ubuntu machine, including initialization, backups, restoration, and cleanup.To use these scripts, you'll need to follow these steps:
  
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

    To create a backup of your Drupal database and files, execute the backup script:
      ./backup.sh
      
    This script will:
    Create a timestamped backup of the MySQL database. Create a timestamped backup of the Drupal files directory. Store the backups in the "backups" directory within your project folder.
    
  3. Restoring Your Website (restore.sh):

    To restore your website from backups, execute the restore script with the backup filenames:
      ./restore.sh drupal-db-backup-YYYYMMDDHHMMSS.sql.gz drupal-files-backup-YYYYMMDDHHMMSS.tar.gz

    Replace YYYYMMDDHHMMSS with the actual timestamp of your backups.
If you execute the restore.sh script without arguments, the script will display a list of available backups in the backups directory.
The script will:

    Stop the drupal and mysql docker containers. Restore the mysql database from the provided sql backup file. Restore the drupal files from the provided tar.gz file. Start the drupal and mysql docker containers.
    
  4. Cleaning Up (cleanup.sh):

    To remove old backups and clean up Docker resources, execute the cleanup script:
      ./cleanup.sh
    
    This script will:
    Remove backups older than 7 days from the "backups" directory. Run docker system prune -a to remove unused docker images, containers and networks.
    
  5. Automated Backups with Cron:

    To schedule regular backups, use cron:
      crontab -e
      
    Add a line like this to run backups daily at 2 AM:
     0 2 * * * /path/to/your/project/backup.sh

    Replace /path/to/your/project/ with the actual path to your project directory. Save and close the crontab file.
    
f. Important Notes:

    Ensure that the scripts have execute permissions (chmod +x scriptname.sh).
    Adjust the paths in the scripts and cron job as needed.
    When moving the project to a new machine, ensure that docker is installed, and then run the setup.sh script.
    When restoring a database, the database that is being restored to must be empty.
    When restoring files, make sure that the files directory is empty.
    The setup.sh script should contain the database credentials that are used by drupal, and mysql.

This detailed guide should help you manage your Drupal website effectively using Docker containers and your provided scripts.

   
