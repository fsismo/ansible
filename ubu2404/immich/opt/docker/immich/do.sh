#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

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

case $1 in
    start)   start_docker ;;
    stop)    stop_docker ;;
    upgrade) upgrade_dockers ;;
    *)
        echo "Usage: $0 [start|stop|upgrade]"
        exit 1
esac
