#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAST_RUN="{{ data_dir }}/.last_run.json"

# El scraper es de corrida única (docker compose run --rm), no un servicio que
# se deje corriendo: no hay start/stop, solo disparar una corrida y ver logs.

function run_now() {
    echo -e "${BLUE}Corriendo el scraper (systemctl start ianews-scraper.service)...${NC}"
    sudo systemctl start ianews-scraper.service &&
        echo -e "${GREEN}Corrida terminada.${NC}" ||
        echo -e "${RED}La corrida falló, ver: $0 logs${NC}"
}

function logs() {
    journalctl -u ianews-scraper.service -n "${1:-100}" --no-pager
}

function status() {
    echo -e "${BLUE}Timer:${NC}"
    systemctl status ianews-scraper.timer --no-pager
    echo
    if [ -f "$LAST_RUN" ]; then
        echo -e "${BLUE}Última corrida (${LAST_RUN}):${NC}"
        cat "$LAST_RUN"
        echo
    else
        echo -e "${RED}Todavía no hay ${LAST_RUN}.${NC}"
    fi
}

function pull() {
    echo -e "${BLUE}Pulleando imagen nueva...${NC}"
    cd "$SCRIPT_DIR" && docker compose -f compose.yml -f compose.override.yml pull &&
        echo -e "${GREEN}Listo. Se usa en la próxima corrida del timer (o '$0 run' ahora).${NC}" ||
        echo -e "${RED}Error al pullear.${NC}"
}

case $1 in
    run)    run_now ;;
    logs)   logs "$2" ;;
    status) status ;;
    pull)   pull ;;
    *)
        echo "Usage: $0 [run|logs [N]|status|pull]"
        exit 1
esac
