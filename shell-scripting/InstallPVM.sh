#!/bin/bash
#Author: Dorin Barboiu
#Mail: dorin-vasile.barboiu@atos.net
#
# This script install DataProtect VM Encryption Manager and configure
# it to be able to comunicate with DataProtect KMS Key Manager. After 
# configuration, all the clients should be able to connect to DataProtect
# VM Encryption Manager and the encryption should start  automatically.
#
# Deploy DataProtect VM Encryption Manager
#	1. On vSphere Clinet, go to File > Deploy OVF Template > Browse > Add the OVA File  and deploy the VM with minimum requirements
#	2. Log in the VM
#	3. Change IP adddress
#	4. Restart the network connection
#	5. Verify the changes
#
# NOTE: This script install and config JUST one DataProtect VM Encryption Manager
# For more details please send an email to $Mail adddresses. 
# Usage: ./InstallPVM <STATIC_IP> <GATEWAY> <NETMASK> <INTEFACE> <DNS1> <DNS1> <KSTOKEN> <KSCA>
##########################################################################

STATIC_IP="$1"
GATEWAY="$2"
NETMASK="$3"
INTERFACE="$4"
DNS1="$5"
DNS2="$6"

KSCLIENTCN="KSCLIENTCN"
KSCLIENTCSR="KSCLIENTCSR"
PASSPHRASE="PASSPHRASE"
KSIP="193.251.82.208"
KSPORT="9000"
KSUSER="admin"
KSCACERT="/home/pvadmin/ca.crt"
KSPASS="JCsomPW13k"
KSCLIENTCERT="/home/pvadmin/certificate.crt"

#Check for manadatory parameters
if [ -z "$STATIC_IP" ]; then
	echo "Warning: IP variable is not set. Will use the default value."
	IP="172.16.1.195"
fi
if [ -z "$GATEWAY" ]; then
    echo "Warning: GATEWAY variable is not set. Will use the default value."
    GATEWAY="172.16.0.1"
fi
if [ -z "$NETMASK" ]; then
    echo "Warning: NETMASK variable is not set. Will use the default value."
    NETMASK="255.255.254.0"
fi
if [ -z "$INTERFACE" ]; then
    echo "Warning: INTERFACE variable is not set. Will use the default value."
    INTERFACE="eth0"
fi
if [ -z "$DNS1" ]; then
    echo "Warning: DNS variable is not set. Will use the default value."
    DNS1="172.16.0.5"
fi
if [ -z "$DNS2" ]; then
    echo "Warning: DNS variable is not set. Will use the default value."
    DNS2="172.16.0.1"
fi

function CONFIG_ENCRYPTION_MANAGER {
	#After the VM was deployed, let's config. it
	echo "Config. DataProtect VM Encryption Manager network interface."
	sudo pvmctl networkpvm static --interface=$INTERFACE --ipaddr=$STATIC_IP --nwmask=$NETMASK --gateway=$GATEWAY --defaultgw=yes
	if [ $? -ne 0 ]; then
		echo "ERROR: Unable to config. $INTERFACE with STATIC IP."
		exit 1
	else 
		echo "$INTERFACE was configured. Restarting the network service ...."
		sudo pvmctl networkpvm start 
	fi
	echo "Network details:"
	sudo pvmctl networkpvm show 
	if [ $? -ne 0 ]; then
		echo "ERROR: Network inteface does not start."
		exit 1
	else 
		echo "Network interface was restarted."
	fi
	#Create DataProtect VM Encryption Manager certificate which will be signed on DataProtect KMS Key Manager
	#Make sure that you MUST CHANGE
	sudo pvmctl createcsr --ksclientcsr=$KSCLIENTCSR --ksclientcn=$KSCLIENTCN --passphrase="$PASSPHRASE" 
	if [ $? -ne 0 ]; then
		echo "ERROR: Unable to create DataProtect VM Encryption Manager certificate. Exiting ...."
		exit 1
	else 
		echo "DataProtect VM Encryption Manager certificate was created."
	fi
	#After all the certificate was signed by KeySecure and copied in the DataProtect VM Encryption Manager
	#the following commnad connets it to DataProtect KMS Key Manager
	sudo pvmctl configks --ksip=$KSIP --ksport=$KSPORT --ksuser=$KSUSER --kscacert=$KSCACERT --kspass="$KSPASS" --ksclientcert=$KSCLIENTCERT
	if [ $? -ne 0 ]; then
		echo "ERROR: Unable to connect DataProtect VM Encryption Manager on DataProtect KMS Key Manager. Exiting ...."
		exit 1
	else 
		echo "DataProtect VM Encryption Manager successfully connected on  DataProtect KMS Key Manager."
		sudo pvmctl startpvm --prikeypass="$PASSPHRASE" 
	fi 
}









