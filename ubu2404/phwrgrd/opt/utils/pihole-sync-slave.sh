#!/bin/bash

NFS_MOUNT_POINT="/mnt/storage"

if ! mountpoint -q "$NFS_MOUNT_POINT"; then
    echo "NFS is not mounted. Attempting to mount..."
    mount "$NFS_MOUNT_POINT"
    if ! mountpoint -q "$NFS_MOUNT_POINT"; then
        echo "Failed to mount NFS. Exiting."
        exit 1
    fi
fi

CHANGES=$(rsync -az -i --files-from=/opt/utils/pihole-sync-slave.conf /mnt/storage/pihole /var/docker-data/phwrgrd/pihole/etc/pihole | grep '^[<>]f')

if [ -n "$CHANGES" ]; then
    echo "Cambios detectados, reiniciando phwrgrd.service"
    systemctl restart phwrgrd.service
fi
