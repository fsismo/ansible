#!/bin/bash
# Variables
WorkingDir='/dev/shm/WAdmin'
function gdate {
	echo "$(/bin/date +%Y%m%d%H%M)"
	}
mkdir -p $WorkingDir 
mkdir -p /var/run/WAdmin
chown -R www-data.www-data $WorkingDir 
[ ! -L "/tmp/WAdmin" ] && ln -s $WorkingDir /tmp/WAdmin
echo $$ > /var/run/WAdmin/WAdmin.pid
while [ 1 ]
do
	#echo "Running ..." $(gdate)
	ToDo=$(find "$WorkingDir" -type f -name "*.do"  -printf '%f\n')
	if [ -n "$ToDo" ]; then
		for Do in $ToDo
		do
			[ "$Do" == "power.do" ] && source ./modules/power.mod.sh
			[ "$Do" == "samba.do" ] && source ./modules/samba.mod.sh
		done
		#echo $ToDo
	fi
	sleep 2
done
