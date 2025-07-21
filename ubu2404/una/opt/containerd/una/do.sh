#!/bin/bash

# Script to manage a Docker container defined in a compose.yml file.
# Must be in the same directory as the compose.yml file.

# Get the compose file path. Assumes it's in the same directory.
COMPOSE_FILE="compose.yml"

# Function to start the container
start_container() {
  echo "Starting container..."
  docker compose up -d
  if [ $? -eq 0 ]; then
    echo "Container started successfully."
  else
    echo "Error starting container."
    exit 1
  fi
}

# Function to stop the container
stop_container() {
  echo "Stopping container..."
  docker compose down
  if [ $? -eq 0 ]; then
    echo "Container stopped successfully."
  else
    echo "Error stopping container."
    exit 1
  fi
}

# Function to update the container (pull and restart)
update_container() {
  echo "Updating container..."
  docker compose pull
  docker compose up -d --force-recreate
  if [ $? -eq 0 ]; then
    echo "Container updated successfully."
  else
    echo "Error updating container."
    exit 1
  fi
}

# Main menu
while true; do
  echo "Choose an action:"
  echo "1. Start container"
  echo "2. Stop container"
  echo "3. Update container (pull and restart)"
  echo "4. Exit"

  read -p "Enter your choice (1-4): " choice

  case "$choice" in
    1)
      start_container
      ;;
    2)
      stop_container
      ;;
    3)
      update_container
      ;;
    4)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please enter a number between 1 and 4."
      ;;
  esac
done