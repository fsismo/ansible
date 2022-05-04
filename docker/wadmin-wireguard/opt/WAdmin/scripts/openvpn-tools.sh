#!/bin/bash

#####
# HELP

ADD=0
REV=0

usage() {
cat << EOF
openvpn_tool [Action] [Params] 
[Acciones]
	-a (Creación de certificados para usuario)
		[Parámetros]
			-u Nombre de usuario
			-m Dirección de correo
			-e expiración (en días más de 0 menos de 3650)
	-r (revocar un usaurio)
		[Parámetros]
			-u Nombre de usuario

[Ejemplo]
	Para crear un certificado de usuario válido por 60 días
		openvpn-tools.sh -a -u nombreusuario -m napellido@ejemplo.com -e 60
	Para revocar un certificado de un usuario
		openvpn-tools.sh -r -u nombreusuario
EOF
}

newcert() {
	HOST=$(cat /etc/hostname)
	VALID=$(date +%Y-%m-%d -d "+$KEY_EXPIRE days")
	export KEY_EXPIRE=$KEY_EXPIRE
	export KEY_EMAIL=$KEY_EMAIL
	cd /etc/openvpn/easy-rsa
	source ./vars
	./build-key --batch $USR nopass 
	#./build-key --batch  $USR nopass
	cd /etc/openvpn/easy-rsa/keys
	GPWD=$(makepasswd --chars 8)	
	echo "Clave para encriptar llaves $GPWD"
	#read -n 1 -s -r -p "Presione cualquier tecla para continuar"
	openssl rsa -in $USR.key -des3 --passout pass:$GPWD -out $USR.3des.key
	
	# Default Variable Declarations 
	DEFAULT="/opt/WAdmin/config/openvpn-tools.config" 
	FILEHELPEXT=".html"
	FILEEXT=".ovpn" 
	CRT=".crt" 
	KEY=".3des.key" 
	CA="ca.crt" 
	TA="ta.key" 
	 	 	 
	#Ready to make a new .opvn file - Start by populating with the default file 
	cat $DEFAULT > $HOST-$USR$FILEEXT 
	 
	#Now, append the CA Public Cert 
	echo "<ca>" >> $HOST-$USR$FILEEXT 
	cat $CA >> $HOST-$USR$FILEEXT 
	echo "</ca>" >> $HOST-$USR$FILEEXT

	#Next append the client Public Cert 
	echo "<cert>" >> $HOST-$USR$FILEEXT 
	cat $USR$CRT | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' >> $HOST-$USR$FILEEXT 
	echo "</cert>" >> $HOST-$USR$FILEEXT 
	 
	#Then, append the client Private Key 
	echo "<key>" >> $HOST-$USR$FILEEXT 
	cat $USR$KEY >> $HOST-$USR$FILEEXT 
	echo "</key>" >> $HOST-$USR$FILEEXT 
	 
	#Finally, append the TA Private Key 
	echo "<tls-auth>" >> $HOST-$USR$FILEEXT 
	cat $TA >> $HOST-$USR$FILEEXT 
	echo "</tls-auth>" >> $HOST-$USR$FILEEXT 
	sed "s/xpwdx/$GPWD/g" /opt/WAdmin/scripts/openvpn-tools.readme.html > $HOST-$USR$FILEHELPEXT
	echo "Done! $HOST-$USR$FILEEXT Successfully Created."
	tar -czf /var/OpenVPNClients/$USR.tar.gz  $HOST-$USR$FILEEXT $HOST-$USR$FILEHELPEXT
}


revokecert() {
	./revoke-full $1
	echo "Entre a revokecert"
	echo "Usuario = $USR"
}

cd /etc/openvpn/easy-rsa
. ./vars


while getopts “har::u:m:e:” OPTION
do
	case $OPTION in
		a)
			ADD=1
			;;
		h)
			usage
        	exit 1
        	;;
		e)
			KEY_EXPIRE=$OPTARG
			;;
		m)
			KEY_EMAIL=$OPTARG
			;;
		r)
			REV=1
			;;
		u)
			USR=$OPTARG
			;;
		?)
			usage
			exit
			;;
	esac
done

clear
#echo "ADD = $ADD"
#echo "REV = $REV"

if [ $ADD == 1 ] || [ $REV == 1 ]; then
	echo "VOY a hacer algo"
	if [ $ADD == 1 ] && [ -n $USR ] && [ -n $KEY_EMAIL ] && [ -n $KEY_EXPIRE ]; then 
		# && $KEY_EXPIRE -gt '0' && $KEY_EXPIRE -le '36500'
		newcert
	elif [ $REV == 1 ] && [ -n $USR ]; then
		revokecert
	else
		usage
		exit 1
	fi
else 
	usage
	exit 1
fi
