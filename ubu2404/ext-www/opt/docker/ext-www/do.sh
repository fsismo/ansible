#!/bin/bash

# Check if at least one parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 {update|ncld-upgrade|ncld-maintenance-off|ncld-maintenance-on}"
    exit 1
fi

# Function to check if Docker Compose is installed
check_docker_compose() {
    if ! command -v docker &> /dev/null; then
        echo "Docker could not be found. Please install it first."
        exit 1
    fi
}

# Function to check if docker-compose.yml exists
check_docker_compose_file() {
    if [ ! -f docker-compose.yml ]; then
        echo "docker-compose.yml file not found in the current directory."
        exit 1
    fi
}

# Loop through all provided parameters
for param in "$@"; do
    case $param in
        update)
            # Check for Docker Compose and docker-compose.yml
            check_docker_compose
            check_docker_compose_file

            # Pull the latest images and restart containers with a 2-second wait time
            echo "Upgrading the dockers..."
            docker compose pull
            docker compose up -d --force-recreate
            ;;
        ncld-upgrade)
            # Check for Docker Compose and docker-compose.yml
            check_docker_compose
            check_docker_compose_file

            # Execute the upgrade command
            echo "Executing NC LD Upgrade..."
            docker exec -i -u 33 ext-www_nextcloud_1 php /var/www/html/updater/updater.phar
            ;;
        ncld-maintenance-off)
            # Check for Docker Compose and docker-compose.yml
            check_docker_compose
            check_docker_compose_file

            # Execute the maintenance off command
            echo "Turning off NC LD Maintenance..."
            docker exec -i -u 33 ext-www_nextcloud_1 php /var/www/html/occ maintenance:mode --off
            ;;
        ncld-maintenance-on)
            # Check for Docker Compose and docker-compose.yml
            check_docker_compose
            check_docker_compose_file

            # Execute the maintenance on command
            echo "Turning on NC LD Maintenance..."
            docker exec -i -u 33 ext-www_nextcloud_1 php /var/www/html/occ maintenance:mode --on
            ;;
        *)
            echo "Unknown parameter: $param"
            exit 1
            ;;
    esac
done

echo "Script execution completed."