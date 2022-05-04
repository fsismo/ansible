#!/bin/sh
# default samba .conf file
SMB_CONF=/etc/samba/smb.conf
# samba directory to store samba configuration files individually
SMB_CONF_DIR=/etc/samba/smb.conf.d/
# first need to create individual .conf files with desired sambs configuration into path defined above

# file which contains all includes to samba configuration files individually
SMB_INCLUDES=/etc/samba/includes.conf
# adds includes.conf file existance to smb.conf file
if ! grep -q 'include = '"${SMB_INCLUDES}" $SMB_CONF ; then
   echo 'include = '"${SMB_INCLUDES}" | tee -a $SMB_CONF > /dev/null
fi

# create directory smb.conf.d to store samba .conf files
mkdir -p $SMB_CONF_DIR

# populates includes.conf with files in smb.conf.d directory
ls "${SMB_CONF_DIR}"* | sed -e 's/^/include = /' > $SMB_INCLUDES
systemctl restart smbd.service
