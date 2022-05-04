#!/bin/bash
#Samba Module File
#Don't edit it!
echo "Executing actions on Power module"
ModDo="$(cat $WorkingDir/$Do)"
Action=$(echo $ModDo | cut -d '|' -f 1)
Param=$(echo $ModDo | cut -d '|' -f 2)
[ -n "Action" ] && [ "$Action" == "restart" ] && echo "The system is going down for REBOOT NOW!." && /opt/WAdmin/scripts/powerdown.sh && /sbin/shutdown -r 0
[ -n "Action" ] && [ "$Action" == "shutdown" ] && echo "The system is going down for SHUTDOWN NOW!." && /opt/WAdmin/scripts/powerdown.sh && /sbin/shutdown -P 0
#echo "Action -> $Action"
#echo "Parameter -> $Param"
#rm $WorkingDir/$Do
