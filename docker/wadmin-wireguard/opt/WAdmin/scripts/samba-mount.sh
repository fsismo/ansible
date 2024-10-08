#!/bin/bash
docker-compose -f /opt/docker/wadmin-wireguard/docker-compose.yml stop ubu2004_apache_wadmin
docker-compose -f /opt/docker/ubuntu-16.04-samba/docker-compose.yml stop
LOOP=$(losetup -f)
losetup $LOOP /var/fs/encrypted.fs 
echo $1 |cryptsetup luksOpen $LOOP encryptedfs0
/bin/mount -n --source /dev/mapper/encryptedfs0 --target /var/sambashare/
docker-compose -f /opt/docker/ubuntu-16.04-samba/docker-compose.yml start
docker-compose -f /opt/docker/wadmin-wireguard/docker-compose.yml start ubu2004_apache_wadmin
[ -f /etc/init.d/code42 ] && /etc/init.d/code42 start

