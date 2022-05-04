#!/bin/bash
if [ -d /var/sambashare/backup ]; then
	echo "Ejecutando backup en unidad encriptada"
	rsync -a /var/sambashare/gestion/ /var/sambashare/backup --delete
	/bin/date +%Y/%m/%d-%H:%M > /var/sambashare/backup/lastbackup.txt
fi
