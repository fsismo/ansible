#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="{{ scraper_output_dir }}"
PIEZAS=(scraper processor)

# scraper es de corrida única (docker compose run --rm). processor, desde la
# cola de trabajos (2026-09-24): su timer solo encola y lo ejecuta
# ianews-processor-worker (contenedor de larga vida) — `run processor`
# encola, `cola` muestra los últimos trabajos y `logs worker` la salida de
# los pasos. run/logs/pull toman la pieza como argumento porque comparten
# este mismo /opt/docker/ianews/.

function _validar_pieza() {
    for p in "${PIEZAS[@]}"; do [ "$p" = "$1" ] && return 0; done
    echo -e "${RED}Pieza inválida: '$1'. Opciones: ${PIEZAS[*]}${NC}"
    exit 1
}

function run_now() {
    _validar_pieza "$1"
    echo -e "${BLUE}Corriendo ${1} (systemctl start ianews-${1}.service)...${NC}"
    sudo systemctl start "ianews-${1}.service" &&
        echo -e "${GREEN}Listo (processor: queda encolado, seguirlo con '$0 cola').${NC}" ||
        echo -e "${RED}La corrida falló, ver: $0 logs ${1}${NC}"
}

function logs() {
    if [ "$1" = "worker" ]; then
        journalctl -u ianews-processor-worker.service -n "${2:-100}" --no-pager
        return
    fi
    _validar_pieza "$1"
    journalctl -u "ianews-${1}.service" -n "${2:-100}" --no-pager
}

function cola() {
    cd "$SCRIPT_DIR" && docker compose -f compose.yml -f compose.override.yml run --rm processor cola --limite "${1:-30}"
}

function status() {
    for p in "${PIEZAS[@]}"; do
        echo -e "${BLUE}== ${p} ==${NC}"
        systemctl status "ianews-${p}.timer" --no-pager
        echo
    done
    for w in ianews-processor-worker ianews-builder-worker; do
        echo -e "${BLUE}== ${w} ==${NC}"
        systemctl status "${w}.service" --no-pager -n 0
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
    cola)   cola "$2" ;;
    status) status ;;
    pull)   pull "$2" ;;
    *)
        echo "Usage: $0 [run <scraper|processor>|logs <scraper|processor|worker> [N]|cola [N]|status|pull <scraper|processor>]"
        exit 1
esac
