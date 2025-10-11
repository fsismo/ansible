#/bin/bash

# Case will evaluate the imput $1 i will execute options or if null explain usage
# list will list ollama models
# start will star docker compose
# stop will stop docker compopse
# update will update ollama models
# upgrade will update the dockers
case $1 in
    "list")
        echo "Listing Ollama models..."
        # Add command to list ollama models here
        docker exec -it ollama ollama list
        ;;
    "start")
        echo "Starting Docker Compose..."
        docker compose up -d
        ;;
    "stop")
        echo "Stopping Docker Compose..."
        docker compose down
        ;;
    "update")
        echo "Updating Ollama models..."
        for model in $(docker exec -it ollama ollama list | sed '1d' | awk '{print $1}')
	do
            echo "Updating model: $model"
            docker exec -it ollama ollama pull $model
        done 
        ;;
    "upgrade")
        echo "Upgrading the dockers..."
        docker compose pull
        docker compose up -d --force-recreate
        ;;
    *)
        echo "Usage: $0 {list|start|stop|update|upgrade}"
        exit 1
        ;;
esac
