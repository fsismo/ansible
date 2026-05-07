#!/bin/bash
set -e
HOSTNAME=$(hostname)
mkdir -p /mnt/storage/backups/$HOSTNAME
rsync --delete -av /etc /mnt/storage/backups/$HOSTNAME/ >> /mnt/storage/backups/log.rbpi-backup 2>&1
rsync --delete -av /home /mnt/storage/backups/$HOSTNAME/ >> /mnt/storage/backups/log.rbpi-backup 2>&1
rsync --delete -av /root /mnt/storage/backups/$HOSTNAME/ >> /mnt/storage/backups/log.rbpi-backup 2>&1
rsync --delete -av /opt /mnt/storage/backups/$HOSTNAME/	--exclude=/opt/containerd
[ -d /opt/docker/ ] && rsync --delete -av /opt/docker /mnt/storage/backups/$HOSTNAME/ >> /mnt/storage/backups/log.rbpi-backup 2>&1
[ -d /var/docker-data/ ] && rsync --delete -av /var/docker-data /mnt/storage/backups/$HOSTNAME/ >> /mnt/storage/backups/log.rbpi-backup 2>&1
[ -d /opt/containerd/ ] && rsync --delete -av /opt/containerd /mnt/storage/backups/$HOSTNAME/ >> /mnt/storage/backups/log.rbpi-backup 2>&1
[ -d /var/containerd-data/ ] && rsync --delete -av /var/containerd-data /mnt/storage/backups/$HOSTNAME/ >> /mnt/storage/backups/log.rbpi-backup 2>&1
