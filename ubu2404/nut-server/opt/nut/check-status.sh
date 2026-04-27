#!/bin/bash
if ! systemctl is-active --quiet nut-server; then
    echo "nut-server is not active, restarting..."
    systemctl restart nut-server
fi

