#!/bin/bash
mount /mnt/storage


#!/bin/bash

# Function to start the application
start_app() {
    mount /mnt/storage
    if [ -d /mnt/storage/Downloads/transmission/ ]; then
        docker compose up -d
    else
        echo "El storage no pudo ser montado"
    fi
}

# Function to stop the application
stop_app() {
    docker compose stop
}

# Function to restart the application
restart_app() {
    stop_app
    sleep 2  # Wait for 2 seconds before starting again
    start_app
}

upgrade_app() {
    stop_app
    sleep 2  # Wait for 2 seconds before upgrade
    docker compose pull
    sleep 2  # Wait for 2 seconds before starting again
    start_app
}

# Main script logic
case "$1" in
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    restart)
        restart_app
        ;;
    upgrade)
        upgrade_app
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|upgrade}"
        exit 1
        ;;
esac

exit 0
