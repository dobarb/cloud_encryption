#!/bin/bash
#Author: Dorin Barboiu
#Mail: dorin-vasile.barboiu@atos.net
#
# This script detect which linux distro is using and install the 
# requirements and dependencies to be able to install ProtectV   
# on the host.
# 
################################################################
IP="$1"
GATEWAY="$2"
NETMASK="$3"
INTERFACE="$4"
TOKEN="$5"
CA="$6"

if [ -z "$IP" ]; then
	echo "Warning: IP variable is not set. Will use the default value."
	IP="172.16.1.200"
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
if [ -z "$TOKEN" ]; then
         echo "Error: TOKEN variable is not set. Aborting..."
         exit 1
fi
if [ -z "$CA" ]; then
         echo "Error: Certificate path is not set. Aborting..."
         exit 1
fi

declare os_VENDOR os_RELEASE os_UPDATE os_PACKAGE os_CODENAME

#################################################################
# Determine what OS is running
#################################################################
# GetOSVersion
function GetOSVersion {
#k Figure out which vendor we are
if [[ -x $(which lsb_release 2>/dev/null) ]]; then
	os_VENDOR=$(lsb_release -i -s)
	os_RELEASE=$(lsb_release -r -s)
	os_UPDATE=""
	os_PACKAGE="rpm"
	if [[ "Debian,Ubuntu,LinuxMint" =~ $os_VENDOR ]]; then
		os_PACKAGE="deb"
	elif [[ "SUSE LINUX" =~ $os_VENDOR ]]; then
		lsb_release -d -s | grep -q openSUSE
		if [[ $? -eq 0 ]]; then
			os_VENDOR="openSUSE"
		fi
	elif [[ $os_VENDOR == "openSUSE project" ]]; then
		os_VENDOR="openSUSE"
	elif [[ $os_VENDOR =~ Red.*Hat ]]; then
		os_VENDOR="Red Hat"
	fi
		os_CODENAME=$(lsb_release -c -s)
elif [[ -r /etc/redhat-release ]]; then
# Red Hat Enterprise Linux Server release 5.5 (Tikanga)
# Red Hat Enterprise Linux Server release 7.0 Beta (Maipo)
# CentOS release 5.5 (Final)
# CentOS Linux release 6.0 (Final)
# Fedora release 16 (Verne)
# XenServer release 6.2.0-70446c (xenenterprise)
# Open Suse  Sles *
	os_CODENAME=""
	for r in "Red Hat" CentOS Fedora XenServer; do
		os_VENDOR=$r
		if [[ -n "`grep \"$r\" /etc/redhat-release`" ]]; then
			ver=`sed -e 's/^.* \([0-9].*\) (\(.*\)).*$/\1\|\2/' /etc/redhat-release`
			os_CODENAME=${ver#*|}
			os_RELEASE=${ver%|*}
			os_UPDATE=${os_RELEASE##*.}
			os_RELEASE=${os_RELEASE%.*}
			break
		fi
		os_VENDOR=""
	done
	os_PACKAGE="rpm"
elif [[ -r /etc/SuSE-release ]]; then
	for r in openSUSE "SUSE Linux"; do
	if [[ "$r" = "SUSE Linux" ]]; then
		os_VENDOR="SUSE LINUX"
	else
		os_VENDOR=$r
	fi
	if [[ -n "`grep \"$r\" /etc/SuSE-release`" ]]; then
		os_CODENAME=`grep "CODENAME = " /etc/SuSE-release | sed 's:.* = ::g'`
		os_RELEASE=`grep "VERSION = " /etc/SuSE-release | sed 's:.* = ::g'`
		os_UPDATE=`grep "PATCHLEVEL = " /etc/SuSE-release | sed 's:.* = ::g'`
	break
	fi
	os_VENDOR=""
	done
os_PACKAGE="rpm"
# If lsb_release is not installed, we should be able to detect Debian OS
elif [[ -f /etc/debian_version ]] && [[ $(cat /proc/version) =~ "Debian" ]]; then
	os_VENDOR="Debian"
	os_PACKAGE="deb"
	os_CODENAME=$(awk '/VERSION=/' /etc/os-release | sed 's/VERSION=//' | sed -r 's/\"|\(|\)//g' | awk '{print $2}')
	os_RELEASE=$(awk '/VERSION_ID=/' /etc/os-release | sed 's/VERSION_ID=//' | sed 's/\"//g')
fi
export os_VENDOR os_RELEASE os_UPDATE os_PACKAGE os_CODENAME
}

########################################################################
# Determine if current distribution is a Fedora-based distribution
########################################################################
function is_fedora {
if [[ -z "$os_VENDOR" ]]; then
	GetOSVersion
fi

[ "$os_VENDOR" = "Fedora" ] || [ "$os_VENDOR" = "Red Hat" ] || \
[ "$os_VENDOR" = "CentOS" ] || [ "$os_VENDOR" = "OracleServer" ]
}

########################################################################
# Determine if current distribution is a SUSE-based distribution
########################################################################
function is_suse {
if [[ -z "$os_VENDOR" ]]; then
	GetOSVersion
fi

[ "$os_VENDOR" = "openSUSE" ] || [ "$os_VENDOR" = "SUSE LINUX" ]
}

########################################################################
# Determine if current distribution is an Ubuntu-based distribution
########################################################################
function is_ubuntu {
if [[ -z "$os_PACKAGE" ]]; then
	GetOSVersion
fi
[ "$os_PACKAGE" = "deb" ]
}

if is_fedora ; then
#Install stuff on FEDORA
echo "I'm FEDORA."
elif is_ubuntu ; then
# Install stuff on UBUNTU
	apt-get install gdebi-core python-crypto busybox -y
	if [ $? -ne 0 ]; then
		echo "Unable to install the dependencies. Aborting..."
		exit 1
	else
		echo "Dependencies were installed."
	fi
	apt-get update
	echo "Installing ProtectV on the machine"
	PV=$(ls | grep pvlinux*16*)
	gdebi $PV -n
	if [ $? -ne 0 ]; then
		echo "Error: Something gone wrong. Unable to install ProtectV. Exiting..."
		exit 1
	else
		echo "ProtectV was installed."
	fi
	echo "Configuring $INTERFACE static ip"
	pvsetip -i $IP -g $GATEWAY -n NETMASK -x $INTERFACE -f
	if [ $? -ne 0 ]; then
		echo  "Error: Unable to set static ip on $INTERFACE. Exiting..."
		exit 1
	else
		echo "$INTERFACE was configured."
		pvsetip -d
	fi
<<<<<<< HEAD
	echo "Connect Linux machine to DataProtect VM Encryption Manager"
=======
	echo "Connet Linux machine to DataProtect VM Encryption Manager"
>>>>>>> 5fa823903a048a77caac78de276c484a69798455
	cd /opt/protectv/bootagent
	bash pvreg $TOKEN $GATEWAY $CA
	if [ $? -ne 0 ]; then
		echo  "Error: Unable to register the client. Exiting..."
		exit 1
	else
		echo "The client was registred to DataProtect VM Encryption Manager. The VM will be rebooted in 1 minute"
		sleep 60
		sudo reboot	
	fi
elif is_suse ; then
#Install stuff on SUSE
echo "I'm SUSE."
fi

