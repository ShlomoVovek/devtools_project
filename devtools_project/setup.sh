#!/bin/bash

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo snap install docker
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo apt install -y docker-compose
fi

# Install MySQL server and client tools
echo "Installing MySQL server and client tools..."
sudo apt update
sudo apt install -y mysql-server mysql-client-core-8.0

# Create a Docker network for the containers
echo "Creating Docker network..."
sudo docker network create drupal_network || echo "Network already exists"

# Create docker-compose.yml file
echo "Creating docker-compose.yml file..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  db:
    image: mysql:8.0
    container_name: mysql_container
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: my-secret-pw
      MYSQL_DATABASE: drupal
      MYSQL_USER: drupaluser
      MYSQL_PASSWORD: my-secret-pw
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - drupal_network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  drupal:
    image: drupal:latest
    container_name: drupal_container
    restart: always
    ports:
      - "8080:80"
    depends_on:
      db:
        condition: service_healthy
    environment:
      DRUPAL_DATABASE_DRIVER: mysql
      DRUPAL_DATABASE_HOST: db
      DRUPAL_DATABASE_NAME: drupal
      DRUPAL_DATABASE_USERNAME: drupaluser
      DRUPAL_DATABASE_PASSWORD: my-secret-pw
    volumes:
      - drupal_data:/var/www/html
    networks:
      - drupal_network

volumes:
  db_data:
    name: drupal_db_data
  drupal_data:
    name: drupal_site_data

networks:
  drupal_network:
EOF

# Run the Docker containers using docker-compose
echo "Starting Docker containers..."
sudo docker compose up -d

echo "Setup complete. Docker containers are running."
echo "Drupal website is available at http://localhost:8080"
echo "Please allow a few moments for Drupal and MySQL to fully initialize."
