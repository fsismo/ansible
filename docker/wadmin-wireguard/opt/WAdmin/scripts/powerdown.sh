#!/bin/bash
LOOP=$(losetup -l |grep encrypted | awk '{print $1}')
docker-compose -f /opt/docker/wadmin-wireguard/docker-compose.yml stop ubu2004_apache_wadmin
[ -f /etc/init.d/code42 ] && /etc/init.d/code42 stop
[ -f /etc/init.d/smbd ] && /etc/init.d/smbd stop
umount /dev/mapper/encryptedfs0
cryptsetup luksClose encryptedfs0
losetup -d $LOOP
dmsetup remove_all
