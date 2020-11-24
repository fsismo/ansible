#!/bin/bash
HOSTNAME=$(hostname)
mkdir -p /mnt/storage/backups/$HOSTNAME
rsync -av /etc /mnt/storage/backups/$HOSTNAME/
rsync -av /home /mnt/storage/backups/$HOSTNAME/
rsync -av /root /mnt/storage/backups/$HOSTNAME/
rsync -av /opt/utils /mnt/storage/backups/$HOSTNAME/opt
