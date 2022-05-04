#!/bin/bash
HOSTNAME=$(hostname)
mkdir -p /mnt/storage/backups/$HOSTNAME
rsync -av --delete /etc /mnt/storage/backups/$HOSTNAME/
rsync -av --delete /home /mnt/storage/backups/$HOSTNAME/
rsync -av --detele /root /mnt/storage/backups/$HOSTNAME/
rsync -av --delete /opt /mnt/storage/backups/$HOSTNAME/	--exclude=/opt/containerd
