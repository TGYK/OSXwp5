#!/bin/bash
#MKV ICS for Apple
#v0.1
#By TGYK

#Check for root
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

ICSPID=$(pgrep InternetSharing)
if [ $? == "0" ]; then
	echo "Killing ICS"
	launchctl unload -w /System/Library/LaunchDaemons/com.apple.InternetSharing.plist
	sleep 1
fi

#Load, then unload ICS to create file
launchctl load -w /System/Library/LaunchDaemons/com.apple.InternetSharing.plist
sleep 1
launchctl unload -w /System/Library/LaunchDaemons/com.apple.InternetSharing.plist
sleep 1
echo "NAT file created"

#Write the NAT default to the file
x
sleep 1
echo "NAT file edited"

#Start sharing again
launchctl load -w /System/Library/LaunchDaemons/com.apple.InternetSharing.plist
sleep 1
echo "ICS started"

#Set en0 to be 172.16.42.42
ifconfig en0 172.16.42.42 netmask 255.255.255.0 up
sleep 1
echo "IP on en0 set tp 172.16.42.42"

#rewrite bootpd.plist
cat /etc/bootpd.plist | sed s/172.16.42.1/172.16.42.42/g | sed s/172.16.42.2/172.16.42.43/g > /etc/bootpd.plist
sleep 1
echo "Rewritten bootpd file for DHCP"

#reload bootpd process
kill -HUP $(pgrep bootpd)
sleep 1
echo "Reloaded bootpd file for DHCP"
