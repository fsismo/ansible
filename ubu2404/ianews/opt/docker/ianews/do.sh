#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="{{ scraper_output_dir }}"
PIEZAS=(scraper processor)

# Todas las piezas de ianews son de corrida única (docker compose run --rm),
# no servicios que se dejen corriendo: no hay start/stop, solo disparar una
# corrida y ver logs. run/logs/pull toman la pieza como argumento porque
# comparten este mismo /opt/docker/ianews/.

function _validar_pieza() {
    for p in "${PIEZAS[@]}"; do [ "$p" = "$1" ] && return 0; done
    echo -e "${RED}Pieza inválida: '$1'. Opciones: ${PIEZAS[*]}${NC}"
    exit 1
}

function run_now() {
    _validar_pieza "$1"
    echo -e "${BLUE}Corriendo ${1} (systemctl start ianews-${1}.service)...${NC}"
    sudo systemctl start "ianews-${1}.service" &&
        echo -e "${GREEN}Corrida terminada.${NC}" ||
        echo -e "${RED}La corrida falló, ver: $0 logs ${1}${NC}"
}

function logs() {
    _validar_pieza "$1"
    journalctl -u "ianews-${1}.service" -n "${2:-100}" --no-pager
}

function status() {
    for p in "${PIEZAS[@]}"; do
        echo -e "${BLUE}== ${p} ==${NC}"
        systemctl status "ianews-${p}.timer" --no-pager
        echo
    done
    if [ -f "$DATA_DIR/.last_run.json" ]; then
        echo -e "${BLUE}Última corrida scraper:${NC}"
        cat "$DATA_DIR/.last_run.json"
        echo
    fi
    if [ -f "$DATA_DIR/.last_run_processor.json" ]; then
        echo -e "${BLUE}Última corrida processor:${NC}"
        cat "$DATA_DIR/.last_run_processor.json"
        echo
    fi
}

function pull() {
    _validar_pieza "$1"
    echo -e "${BLUE}Pulleando imagen nueva de ${1}...${NC}"
    cd "$SCRIPT_DIR" && docker compose -f compose.yml -f compose.override.yml pull "$1" &&
        echo -e "${GREEN}Listo. Se usa en la próxima corrida del timer (o '$0 run ${1}' ahora).${NC}" ||
        echo -e "${RED}Error al pullear.${NC}"
}

case $1 in
    run)    run_now "$2" ;;
    logs)   logs "$2" "$3" ;;
    status) status ;;
    pull)   pull "$2" ;;
    *)
        echo "Usage: $0 [run <scraper|processor>|logs <scraper|processor> [N]|status|pull <scraper|processor>]"
        exit 1
esac
