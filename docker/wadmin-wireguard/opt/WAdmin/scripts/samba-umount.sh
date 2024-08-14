#!/bin/bash
LOOP=$(losetup -l |grep encrypted | awk '{print $1}')
docker-compose -f /opt/docker/wadmin-wireguard/docker-compose.yml stop ubu2004_apache_wadmin
docker-compose -f /opt/docker/ubuntu-16.04-samba/docker-compose.yml stop
[ -f /etc/init.d/code42 ] && /etc/init.d/code42 stop
umount /dev/mapper/encryptedfs0
cryptsetup luksClose encryptedfs0
losetup -d $LOOP
dmsetup remove_all
docker-compose -f /opt/docker/ubuntu-16.04-samba/docker-compose.yml start
docker-compose -f /opt/docker/wadmin-wireguard/docker-compose.yml start ubu2004_apache_wadmin
