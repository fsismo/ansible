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

# Internal: create context-sized variants of selected models
# Usage: _prepare_ctx <CTX> <suffix>
function _prepare_ctx() {
    local CTX=$1
    local SUFFIX=$2

    local models
    models=$(docker exec ollama ollama list 2>/dev/null | sed '1d' | awk '{print $1}' | grep -v "\-${SUFFIX}$")

    if [ -z "$models" ]; then
        echo -e "${RED}No models available to prepare.${NC}"
        return 1
    fi

    echo -e "\n${BLUE}Available models:${NC}"
    echo "$models" | awk '{print NR"  "$1}'

    read -p "Enter model number to prepare (or 'all'): " selection

    local selected
    if [ "$selection" = "all" ]; then
        selected="$models"
    elif [[ "$selection" =~ ^[0-9]+$ ]]; then
        selected=$(echo "$models" | sed -n "${selection}p")
        if [ -z "$selected" ]; then
            echo -e "${RED}Invalid selection.${NC}"
            return 1
        fi
    else
        echo -e "${RED}Invalid input.${NC}"
        return 1
    fi

    local ok=0 fail=0
    for model in $selected; do
        local base tag saved
        if [[ "$model" == *":"* ]]; then
            base="${model%%:*}"
            tag="${model##*:}"
            saved="${base}:${tag}-${SUFFIX}"
        else
            saved="${model}:latest-${SUFFIX}"
        fi

        echo -e "\n${BLUE}Preparing ${model} → ${saved} (num_ctx=${CTX})${NC}"

        local modelfile="/tmp/Modelfile_ctx_$$"
        if printf "FROM %s\nPARAMETER num_ctx %d\n" "$model" "$CTX" | \
                docker exec -i ollama bash -c "cat > ${modelfile} && ollama create '${saved}' -f ${modelfile}; rm -f ${modelfile}"; then
            echo -e "${GREEN}Saved as ${saved}${NC}"
            ((++ok))
        else
            echo -e "${RED}Error preparing ${model}${NC}"
            ((++fail))
        fi
    done

    echo -e "\nDone — ${GREEN}prepared: $ok${NC}  ${RED}failed: $fail${NC}"
}

# Prepare models for offline use with OpenCode (sets num_ctx=32768, saves with -32k suffix)
function models_opencode() {
    _prepare_ctx 32768 "32k"
}

# Prepare models for Hermes Agent (sets num_ctx=65536, saves with -64k suffix)
function models_hermes() {
    _prepare_ctx 65536 "64k"
}

# Function to upgrade models
function models_update() {
    echo -e "${BLUE}Updating Ollama models...${NC}"
    local updated=0 failed=0 rebuilt=0 rebuild_failed=0

    local all_models
    all_models=$(docker exec ollama ollama list 2>/dev/null | sed '1d' | awk '{print $1}')

    if [ -z "$all_models" ]; then
        echo -e "${RED}Error: Failed to retrieve Ollama models.${NC}"
        return 1
    fi

    # Separate base models from custom context variants (suffix -<N>k)
    local base_models custom_models
    base_models=$(echo "$all_models" | grep -v '\-[0-9]\+k$')
    custom_models=$(echo "$all_models" | grep '\-[0-9]\+k$')

    # Update base models via pull
    for model in $base_models; do
        echo -e "\n${BLUE}Updating model: $model${NC}"
        if docker exec ollama ollama pull "$model" > /dev/null; then
            ((updated++))
            echo -e "${GREEN}Success${NC}"
        else
            ((failed++))
            echo -e "${RED}Failure${NC}"
        fi
    done

    # Rebuild custom variants from their updated base model
    for model in $custom_models; do
        local modelfile_content base_model num_ctx
        modelfile_content=$(docker exec ollama ollama show --modelfile "$model" 2>/dev/null)
        base_model=$(echo "$modelfile_content" | grep '^FROM' | awk '{print $2}')
        num_ctx=$(echo "$modelfile_content" | grep 'num_ctx' | awk '{print $3}')

        if [ -z "$base_model" ] || [ -z "$num_ctx" ]; then
            echo -e "\n${RED}Cannot determine base model for ${model}, skipping.${NC}"
            ((rebuild_failed++))
            continue
        fi

        echo -e "\n${BLUE}Rebuilding ${model} from ${base_model} (num_ctx=${num_ctx})${NC}"
        local tmpfile="/tmp/Modelfile_update_$$"
        if printf "FROM %s\nPARAMETER num_ctx %d\n" "$base_model" "$num_ctx" | \
                docker exec -i ollama bash -c "cat > ${tmpfile} && ollama create '${model}' -f ${tmpfile}; rm -f ${tmpfile}"; then
            echo -e "${GREEN}Rebuilt ${model}${NC}"
            ((rebuilt++))
        else
            echo -e "${RED}Failed to rebuild ${model}${NC}"
            ((rebuild_failed++))
        fi
    done

    echo -e "\nUpdate summary:
    ${GREEN}Updated base models:     $updated${NC}
    ${RED}Failed base updates:     $failed${NC}
    ${GREEN}Rebuilt custom variants: $rebuilt${NC}
    ${RED}Failed rebuilds:         $rebuild_failed${NC}"
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
  models_list      List available Ollama models
  model_pull       Pull a new model from Ollama repository
  model_rm         Remove a model from Ollama
  models_update    Update base models and rebuild custom context variants
  models_opencode  Prepare models for OpenCode (num_ctx=32768, -32k suffix)
  models_hermes    Prepare models for Hermes Agent (num_ctx=65536, -64k suffix)
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
    "models_opencode")
        models_opencode ;;
    "models_hermes")
        models_hermes ;;
    "start")
        start_docker ;;
    "stop")
        stop_docker ;;
    "upgrade")
        upgrade_dockers ;;
    *)
        show_usage ;;
esac