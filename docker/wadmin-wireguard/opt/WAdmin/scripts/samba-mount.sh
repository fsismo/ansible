#!/bin/bash
docker-compose -f /opt/docker/wadmin-wireguard/docker-compose.yml stop ubu2004_apache_wadmin
[ -f /etc/init.d/smbd ] && /etc/init.d/smbd stop
LOOP=$(losetup -f)
losetup $LOOP /var/fs/encrypted.fs 
echo $1 |cryptsetup luksOpen $LOOP encryptedfs0
/bin/mount -n --source /dev/mapper/encryptedfs0 --target /var/sambashare/
[ -f /etc/init.d/smbd ] && /etc/init.d/smbd start
[ -f /etc/init.d/code42 ] && /etc/init.d/code42 start
docker-compose -f /opt/docker/wadmin-wireguard/docker-compose.yml start ubu2004_apache_wadmin
