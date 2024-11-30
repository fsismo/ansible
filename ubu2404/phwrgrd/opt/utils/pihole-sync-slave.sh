#!/bin/bash

NFS_MOUNT_POINT="/mnt/storage"  # Replace with your actual NFS mount point

if ! mountpoint -q $NFS_MOUNT_POINT; then
    echo "NFS is not mounted. Attempting to mount..."
    sudo mount $NFS_MOUNT_POINT
    if ! mountpoint -q $NFS_MOUNT_POINT; then
        echo "Failed to mount NFS. Exiting."
        exit 1
    fi
fi

CHGPH=$(rsync -az -i --files-from=/opt/utils/pihole-sync-slave.conf /mnt/storage/pihole /opt/docker/phwrgrd/pihole/etc/pihole |grep 'f')

if [ -n "$CHGDM" ] || [ -n "$CHGPH" ]; then
	echo "restart dns"
	#find /etc/pihole/ -name whitelist.txt -cmin -3
	#	pihole restartdns reload-lists
	#pihole -w --nuke
	systemctl restart phwrgrd.service
fi
