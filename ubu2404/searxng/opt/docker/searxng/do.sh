#!/bin/bash
# Author: Fernando Sismonda

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to start docker compose
function start_docker() {
    echo -e "${BLUE}Starting Docker Compose...${NC}"
    docker compose up -d && 
        echo "${GREEN}Docker services started successfully!${NC}" || 
        echo "${RED}Error starting Docker services.${NC}"
}

# Function to stop docker compose
function stop_docker() {
    echo -e "${BLUE}Stopping Docker Compose...${NC}"
    docker compose down && 
        echo "${GREEN}Docker services stopped successfully!${NC}" || 
        echo "${RED}Error stopping Docker services.${NC}"
}

# Function to upgrade the dockers
function upgrade_dockers() {
    echo -e "${BLUE}Upgrading the dockers...${NC}"
    docker compose pull && 
        docker compose up -d --force-recreate && 
        echo "${GREEN}Docker services upgraded successfully!${NC}" || 
        echo "${RED}Error upgrading Docker services.${NC}"
}

# Main logic
case $1 in
    start)
        start_docker ;;
    stop)
        stop_docker ;;
    upgrade)
        upgrade_dockers ;;
    *)
        echo "Usage: $0 [start|stop|upgrade]"
        exit 1
esac