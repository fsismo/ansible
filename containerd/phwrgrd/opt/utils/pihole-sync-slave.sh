#!/bin/bash
CHGPH=$(rsync -az -i --files-from=/opt/utils/pihole-sync-slave.conf /mnt/storage/pihole /opt/containerd/phwrgrd/pihole/etc/pihole |grep 'f')

if [ -n "$CHGDM" ] || [ -n "$CHGPH" ]; then
	echo "restart dns"
	#find /etc/pihole/ -name whitelist.txt -cmin -3
	#	pihole restartdns reload-lists
	#pihole -w --nuke
	systemctl restart phwrgrd.service
fi
