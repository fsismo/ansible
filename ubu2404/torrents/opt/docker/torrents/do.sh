#!/bin/bash
NFS_MOUNT_POINT="/mnt/storage"  # Replace with your actual NFS mount point

if ! mountpoint -q $NFS_MOUNT_POINT; then
    echo "NFS is not mounted. Attempting to mount..."
    sudo mount $NFS_MOUNT_POINT
    if ! mountpoint -q $NFS_MOUNT_POINT; then
        echo "Failed to mount NFS. Exiting."
        exit 1
    fi
fi

# Function to start the application
start_app() {
        docker compose up -d
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
    echo "Upgrading the dockers..."
    docker compose pull
    docker compose up -d --force-recreate
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
