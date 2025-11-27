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
    docker compose up -d && \
        echo -e "${GREEN}Docker services started successfully!${NC}" || \
        echo -e "${RED}Error starting Docker services.${NC}"
}

# Function to stop docker compose
function stop_docker() {
    echo -e "${BLUE}Stopping Docker Compose...${NC}"
    docker compose down && \
        echo -e "${GREEN}Docker services stopped successfully!${NC}" || \
        echo -e "${RED}Error stopping Docker services.${NC}"
}

# Function to upgrade the dockers
function upgrade_dockers() {
    echo -e "${BLUE}Upgrading the dockers...${NC}"
    docker compose pull && \
        docker compose up -d --force-recreate && \
        echo -e "${GREEN}Docker services upgraded successfully!${NC}" || \
        echo -e "${RED}Error upgrading Docker services.${NC}"
}

# Function to display usage
function show_usage() {
    echo -e "Usage: $0 [COMMAND]
Available commands:
  start            Start Docker services
  stop             Stop Docker services
  upgrade          Upgrade Docker services
"
}

# Main logic
case $1 in
    "start")
        start_docker ;;
    "stop")
        stop_docker ;;
    "upgrade")
        upgrade_dockers ;;
    *)
        show_usage ;;
esac
