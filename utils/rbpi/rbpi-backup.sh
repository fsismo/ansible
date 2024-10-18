#!/bin/bash
HOSTNAME=$(hostname)
mkdir -p /mnt/storage/backups/$HOSTNAME
rsync --delete -av /etc /mnt/storage/backups/$HOSTNAME/
rsync --delete -av /home /mnt/storage/backups/$HOSTNAME/
rsync --delete -av /root /mnt/storage/backups/$HOSTNAME/
rsync --delete -av /opt /mnt/storage/backups/$HOSTNAME/	--exclude=/opt/containerd
[ -d /opt/docker/ ] && rsync --delete -av /opt/docker /mnt/storage/backups/$HOSTNAME/
[ -d /var/docker-data/ ] && rsync --delete -av /var/docker-data /mnt/storage/backups/$HOSTNAME/
[ -d /opt/containerd/ ] && rsync --delete -av /opt/containerd /mnt/storage/backups/$HOSTNAME/
[ -d /var/containerd-data/ ] && rsync --delete -av /var/containerd-data /mnt/storage/backups/$HOSTNAME/
