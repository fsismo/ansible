#!/bin/bash
# Author: Fernando Sismonda

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function start_docker() {
    echo -e "${BLUE}Starting Docker Compose...${NC}"
    docker compose up -d && \
        echo -e "${GREEN}Docker services started successfully!${NC}" || \
        echo -e "${RED}Error starting Docker services.${NC}"
}

function stop_docker() {
    echo -e "${BLUE}Stopping Docker Compose...${NC}"
    docker compose down && \
        echo -e "${GREEN}Docker services stopped successfully!${NC}" || \
        echo -e "${RED}Error stopping Docker services.${NC}"
}

function upgrade_dockers() {
    echo -e "${BLUE}Upgrading the dockers...${NC}"
    docker compose pull && \
        docker compose up -d --force-recreate && \
        echo -e "${GREEN}Docker services upgraded successfully!${NC}" || \
        echo -e "${RED}Error upgrading Docker services.${NC}"
}

function show_status() {
    echo -e "${BLUE}Hermes Agent status:${NC}"
    docker exec hermes hermes status 2>/dev/null || \
        echo -e "${YELLOW}Container not running or hermes CLI unavailable.${NC}"
    echo ""
    echo -e "${BLUE}Container state:${NC}"
    docker compose ps
}

function show_logs() {
    echo -e "${BLUE}Following Hermes Agent logs (Ctrl+C to exit)...${NC}"
    docker logs -f hermes
}

function show_usage() {
    echo -e "Usage: $0 [COMMAND]
Available commands:
  start    Start Docker services
  stop     Stop Docker services
  upgrade  Upgrade Docker services (pull + recreate)
  status   Show Hermes Agent and container status
  logs     Follow container logs
"
}

case $1 in
    "start")   start_docker ;;
    "stop")    stop_docker ;;
    "upgrade") upgrade_dockers ;;
    "status")  show_status ;;
    "logs")    show_logs ;;
    *)         show_usage ;;
esac
