#!/bin/bash

# Check if at least one parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 {update|ncld-upgrade|ncld-maintenance-off|ncld-maintenance-on|ncld-add-missing-indices}"
    exit 1
fi

# Function to check if Docker Compose is installed
check_docker_compose() {
    if ! command -v docker &> /dev/null; then
        echo "Docker could not be found. Please install it first."
        exit 1
    fi
}

# Function to check if compose.yml exists
check_docker_compose_file() {
    if [ ! -f compose.yml ]; then
        echo "compose.yml file not found in the current directory."
        exit 1
    fi
}

# Loop through all provided parameters
for param in "$@"; do
    case $param in
        update)
            # Check for Docker Compose and compose.yml
            check_docker_compose
            check_docker_compose_file

            # Pull the latest images and restart containers with a 2-second wait time
            echo "Pulling the latest images..."
            docker compose pull
            echo "Stopping containers..."
            docker compose down
            sleep 2
            echo "Starting containers..."
            docker compose up -d
            ;;
        ncld-upgrade)
            # Check for Docker Compose and compose.yml
            check_docker_compose
            check_docker_compose_file

            # Execute the upgrade command
            echo "Executing NC LD Upgrade..."
            docker exec -i -u 33 ext-www-nextcloud-1 php /var/www/html/updater/updater.phar
            ;;
        ncld-maintenance-off)
            # Check for Docker Compose and compose.yml
            check_docker_compose
            check_docker_compose_file

            # Execute the maintenance off command
            echo "Turning off NC LD Maintenance..."
            docker exec -i -u 33 ext-www-nextcloud-1 php /var/www/html/occ maintenance:mode --off
            ;;
        ncld-maintenance-on)
            # Check for Docker Compose and compose.yml
            check_docker_compose
            check_docker_compose_file

            # Execute the maintenance on command
            echo "Turning on NC LD Maintenance..."
            docker exec -i -u 33 ext-www-nextcloud-1 php /var/www/html/occ maintenance:mode --on
            ;;
        ncld-add-missing-indices)
            # Check for Docker Compose and compose.yml
            check_docker_compose
            check_docker_compose_file

            # Execute the add missing indices command
            echo "Adding missing database indices in NC LD..."
            docker exec -i -u 33 ext-www-nextcloud-1 php /var/www/html/occ db:add-missing-indices
            ;;
        *)
            echo "Unknown parameter: $param"
            exit 1
            ;;
    esac
done

echo "Script execution completed."
