#!/bin/bash
# Author: Fernando Sismonda

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to list available Ollama models
function model_list() {
    echo -e "${BLUE}Available Models:${NC}"
    docker exec ollama ollama list
}

# Function to pull a new model from Ollama repository
function model_pull() {
    if [ $# -lt 2 ]; then
        read -p "Enter the model name you want to download: " MODEL
    else
        MODEL=$2
    fi

    echo -e "${BLUE}Pulling model: $MODEL${NC}"
    docker exec -it ollama ollama pull "$MODEL" && \
    echo -e "${GREEN}Model pulled successfully!${NC}" || \
    echo -e "${RED}Error pulling model. Check if the model exists.${NC}"
}

# Function to remove a model from Ollama
function model_rm() {
    local model_list=$(docker exec ollama ollama list)
    
    # Check if no models are installed
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Could not retrieve the list of models from Ollama.${NC}"
        return 1
    fi

    # Display the model list with numbers
    echo -e "\n${BLUE}Available Models:${NC}"
    docker exec ollama ollama list | awk 'NR>1 {print NR-1 " " $1 " (" $2 ")"}'

    # Prompt the user to enter the number of the model they want to remove
    read -p "Enter the number of the model you want to remove: " model_number
    
    if ! [[ "$model_number" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid input. Please enter a number.${NC}"
        return 1
    fi

    # Get the model name based on the selected number
    local model_name=$(docker exec ollama ollama list | awk -v n="$model_number" 'NR==n+1 {print $1}')

    if [ -z "$model_name" ]; then
        echo -e "${RED}Error: Invalid model number selected.${NC}"
        return 1
    fi

    # Confirm the removal with the user
    read -p "Are you sure you want to remove '$model_name'? (y/n): " confirmation

    if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
        echo -e "${BLUE}Removing model: $model_name...${NC}"
        docker exec ollama ollama rm "$model_name" && \
            echo -e "${GREEN}Model '$model_name' removed successfully.${NC}" || \
            echo -e "${RED}Error removing model '$model_name'.${NC}"
    else
        echo -e "${YELLOW}Removal cancelled.${NC}"
    fi
}

# Function to upgrade models
function models_update() {
    echo -e "${BLUE}Updating Ollama models...${NC}"
    local updated=0
    local failed=0
    
    # Get the list of installed models without TTY
    models=$(docker exec ollama ollama list 2>/dev/null | sed '1d' | awk '{print $1}')
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to retrieve Ollama models.${NC}"
        return 1
    fi

    # Update each model
    for model in $models; do
        echo -e "\n${BLUE}Updating model: $model${NC}"
        if docker exec ollama ollama pull "$model" > /dev/null; then
            ((updated++))
            echo -e "${GREEN}Success${NC}"
        else
            ((failed++))
            echo -e "${RED}Failure${NC}"
        fi
    done

    # Print summary
    echo -e "\nUpdate summary:
    ${GREEN}Updated models: $updated${NC}
    ${RED}Failed updates: $failed${NC}"
}

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
  models_list       List available Ollama models
  model_pull MODEL Pull a new model from Ollama repository
  model_rm         Remove a model from Ollama
  models_update    Update all installed Ollama models
  start            Start Docker services
  stop             Stop Docker services
  upgrade          Upgrade Docker services
"
}

# Main logic
case $1 in
    "model_pull")
        model_pull "$@" ;;
    "model_rm")
        model_rm ;;
    "models_list")
        model_list ;;
    "models_update")
        models_update ;;
    "start")
        start_docker ;;
    "stop")
        stop_docker ;;
    "upgrade")
        upgrade_dockers ;;
    *)
        show_usage ;;
esac