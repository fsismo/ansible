#!/bin/bash
#Samba Module File
#Don't edit it!
echo "Executing actions on Samba module"
ModDo="$(cat $WorkingDir/$Do)"
Action=$(echo $ModDo | cut -d '|' -f 1)
Param=$(echo $ModDo | cut -d '|' -f 2)
[ -n "Action" ] && [ "$Action" == "backup" ] && ./scripts/samba-backup.sh
[ -n "Action" ] && [ "$Action" == "mount" ] && [ -n "$Param" ] && ./scripts/samba-mount.sh $Param 
[ -n "Action" ] && [ "$Action" == "umount" ] && ./scripts/samba-umount.sh 
#echo "Action -> $Action"
#echo "Parameter -> $Param"
rm $WorkingDir/$Do

