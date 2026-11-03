#!/bin/bash

# Se accede por el automount en vez de montar a mano: un mount manual puede
# trabarse minutos y deja el automount en failed hasta el próximo reinicio.
# Sin este control, Docker podría crear las rutas en el disco local y los
# contenedores arrancarían con las carpetas vacías.
require_nfs() {
    if ! timeout 30 stat /mnt/storage/Downloads/transmission > /dev/null; then
        echo "NFS no disponible. Exiting."
        exit 1
    fi
}

# Function to start the application
start_app() {
    require_nfs
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
    require_nfs
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
