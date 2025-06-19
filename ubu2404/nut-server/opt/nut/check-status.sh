#!/bin/bash
# Scrtip to check with systemctl if the nut-server service is running if not it will restart it    
if [ "$(systemctl status nut-server | grep -c 'active (running)')" != "1" ]; then
    echo "nut-server is not active, restarting..."
    sudo systemctl restart nut-server
fi

