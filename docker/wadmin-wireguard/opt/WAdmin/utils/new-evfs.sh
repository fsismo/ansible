#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Por favor ejecutar como root o con sudo"
  exit
fi

function GETSIZE {
	echo "Ingrese el tambaño en GB que le quiere asignar a la unidad"
	read SIZE
	if ! [ "$SIZE" -ge 0 ] 2> /dev/null; then
		echo "Solo enteros"
		GETSIZE
	fi
	SIZE=$((1024000 * $SIZE))
}

function CREATEDIR {
        mkdir -p /var/sambashare/backup
        mkdir -p /var/sambashare/compartido
        mkdir -p /var/sambashare/gestion
	chown 1001.1001 -R /var/sambashare/
}

if [ -f /var/fs/encrypted.fs ]; then
	echo "Ya existe un disco virtual creado en /var/fs/encrypted.fs debe renombrarlo o borrarlo para crear uno nuevo".
else
	mkdir -p /var/fs/g
	GETSIZE	
	echo "Creando disco virtual!"
	dd if=/dev/zero bs=1024 count=$SIZE 2> /dev/null | pv  | dd of=/var/fs/encrypted.fs 2> /dev/null
	sleep 5
	LOOP=$(losetup -f)
	losetup $LOOP /var/fs/encrypted.fs
	cryptsetup --verbose --verify-passphrase luksFormat $LOOP
	cryptsetup luksOpen $LOOP encryptedfs0
	mkfs.ext4 /dev/mapper/encryptedfs0
	mkdir -p /var/sambashare/
	echo NO > /var/sambashare/.status
	CREATEDIR
	mount /dev/mapper/encryptedfs0 /var/sambashare/
	echo SI > /var/sambashare/.status
	CREATEDIR
	LOOP=$(losetup -l |grep encrypted | awk '{print $1}')
	umount /dev/mapper/encryptedfs0
	cryptsetup luksClose encryptedfs0
	losetup -d $LOOP
fi

