#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTPASSWD="${SCRIPT_DIR}/htpasswd"
HTPASSWD_IMAGE="httpd:2.4-alpine"

function start_docker() {
    echo -e "${BLUE}Starting Docker Compose...${NC}"
    docker compose up -d &&
        echo -e "${GREEN}Docker services started successfully!${NC}" ||
        echo -e "${RED}Error starting Docker services.${NC}"
}

function stop_docker() {
    echo -e "${BLUE}Stopping Docker Compose...${NC}"
    docker compose down &&
        echo -e "${GREEN}Docker services stopped successfully!${NC}" ||
        echo -e "${RED}Error stopping Docker services.${NC}"
}

function upgrade_dockers() {
    echo -e "${BLUE}Upgrading the dockers...${NC}"
    docker compose pull &&
        docker compose up -d --force-recreate &&
        echo -e "${GREEN}Docker services upgraded successfully!${NC}" ||
        echo -e "${RED}Error upgrading Docker services.${NC}"
}

# adduser <nombre> [password]  — alta o cambio de contraseña (bcrypt).
# Si no se pasa el password, lo pide por stdin. zot recarga el htpasswd en caliente.
function add_user() {
    local user="$1" pass="$2" pass2 create=""

    if [ -z "$user" ]; then
        echo -e "${RED}Uso: $0 adduser <nombre> [password]${NC}"
        exit 1
    fi

    if [ -z "$pass" ]; then
        read -rsp "Password para '${user}': " pass;  echo
        read -rsp "Repetir password: "        pass2; echo
        if [ "$pass" != "$pass2" ]; then
            echo -e "${RED}Las contraseñas no coinciden.${NC}"
            exit 1
        fi
    fi
    if [ -z "$pass" ]; then
        echo -e "${RED}El password no puede estar vacío.${NC}"
        exit 1
    fi

    [ -f "$HTPASSWD" ] || create="-c"

    if docker run --rm -v "${SCRIPT_DIR}:/data" "$HTPASSWD_IMAGE" \
            htpasswd -Bb $create /data/htpasswd "$user" "$pass"; then
        chmod 0644 "$HTPASSWD"
        echo -e "${GREEN}Usuario '${user}' agregado/actualizado.${NC} zot recarga el htpasswd solo."
    else
        echo -e "${RED}Error al agregar el usuario.${NC}"
        exit 1
    fi
}

# rmuser <nombre>  — baja de usuario. Sin argumento, lista los usuarios.
function rm_user() {
    local user="$1"

    if [ ! -f "$HTPASSWD" ]; then
        echo -e "${RED}No existe ${HTPASSWD}.${NC}"
        exit 1
    fi

    if [ -z "$user" ]; then
        echo -e "${BLUE}Usuarios actuales:${NC}"
        cut -d: -f1 "$HTPASSWD"
        echo -e "${RED}Uso: $0 rmuser <nombre>${NC}"
        exit 1
    fi

    if ! cut -d: -f1 "$HTPASSWD" | grep -qx "$user"; then
        echo -e "${RED}El usuario '${user}' no existe.${NC}"
        exit 1
    fi

    if [ "$(grep -c . "$HTPASSWD")" -le 1 ]; then
        echo -e "${RED}'${user}' es el último usuario del htpasswd; borrarlo dejaría el push sin acceso. Abortando.${NC}"
        exit 1
    fi

    if docker run --rm -v "${SCRIPT_DIR}:/data" "$HTPASSWD_IMAGE" \
            htpasswd -D /data/htpasswd "$user"; then
        chmod 0644 "$HTPASSWD"
        echo -e "${GREEN}Usuario '${user}' eliminado.${NC} zot recarga el htpasswd solo."
    else
        echo -e "${RED}Error al eliminar el usuario.${NC}"
        exit 1
    fi
}

case $1 in
    start)   start_docker ;;
    stop)    stop_docker ;;
    upgrade) upgrade_dockers ;;
    adduser) add_user "$2" "$3" ;;
    rmuser)  rm_user "$2" ;;
    *)
        echo "Usage: $0 [start|stop|upgrade|adduser <nombre> [password]|rmuser <nombre>]"
        exit 1
esac
