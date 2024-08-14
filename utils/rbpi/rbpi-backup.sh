#!/bin/bash
HOSTNAME=$(hostname)
mkdir -p /mnt/storage/backups/$HOSTNAME
rsync -av --delete /etc /mnt/storage/backups/$HOSTNAME/
rsync -av --delete /home /mnt/storage/backups/$HOSTNAME/
rsync -av --detele /root /mnt/storage/backups/$HOSTNAME/
rsync -av --delete /opt /mnt/storage/backups/$HOSTNAME/	--exclude=/opt/containerd
[ -d /opt/docker/ ] && -av --delete /opt/docker /mnt/storage/backups/$HOSTNAME/
[ -d /var/docker-data/ ] && rsync -av --delete /var/docker-data /mnt/storage/backups/$HOSTNAME/
[ -d /opt/containerd/ ] && -av --delete /opt/containerd /mnt/storage/backups/$HOSTNAME/
[ -d /var/containerd-data/ ] && rsync -av --delete /var/containerd-data /mnt/storage/backups/$HOSTNAME/
