#!/bin/bash
LOOP=$(losetup -l |grep encrypted | awk '{print $1}')
[ -f /etc/init.d/code42 ] && /etc/init.d/code42 stop
docker-compose -f /opt/docker/wadmin-wireguard/docker-compose.yml stop
docker-compose -f /opt/docker/ubuntu-16.04-samba/docker-compose.yml stop 
umount /dev/mapper/encryptedfs0
cryptsetup luksClose encryptedfs0
losetup -d $LOOP
dmsetup remove_all
