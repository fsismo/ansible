#!/bin/bash
cd /opt/WAdmin  
if [ "$1" != "" ]; then
	if [ "$1" == "start" ]; then
		echo "Starting WAdmin Services"
		./daemon.sh &
	elif [ "$1" == "restart" ]; then
		echo "Stoping WAdmin Services"
		kill $(cat /var/run/WAdmin/WAdmin.pid)
		rm /var/run/WAdmin/WAdmin.pid 
		sleep 5
		echo "Starting WAdmin Services"
		./daemon.sh &
	elif [ "$1" == "stop" ]; then
		echo "Stoping WAdmin Services"
		kill $(cat /var/run/WAdmin/WAdmin.pid)
		rm /var/run/WAdmin/WAdmin.pid 
	elif [ "$1" == "status" ]; then
		if [ -f '/var/run/WAdmin/WAdmin.pid' ]; then
			echo "The process is running"
			ps ax | grep $(cat /var/run/WAdmin/WAdmin.pid) | grep -v "grep" 
		else
			echo "The process is not running"
		fi
	else
		echo "Usage"
	fi
else
	echo "Usage"
fi
