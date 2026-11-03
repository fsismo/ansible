#!/bin/bash

# Se accede por el automount en vez de montar a mano: un mount manual puede
# trabarse minutos y deja el automount en failed hasta el próximo reinicio.
if ! timeout 20 stat /mnt/storage/pihole > /dev/null; then
    echo "NFS no disponible, se omite el sync."
    exit 1
fi

CHANGES=$(rsync -az -i --files-from=/opt/utils/pihole-sync-slave.conf /mnt/storage/pihole /var/docker-data/phwrgrd/pihole/etc/pihole | grep '^[<>]f')

if [ -n "$CHANGES" ]; then
    echo "Cambios detectados, reiniciando phwrgrd.service"
    systemctl restart phwrgrd.service
fi
