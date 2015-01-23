#!/bin/bash

#MK5 Internet Connection Sharing for Apple
#v1.6
SCVER="1.6"
#By TGYK
#Special thanks to Bl1tz3dShad0w for testing and feedback for me
#This script is distributed without any warranty, and is not guarenteed to work. Feel free to modify and redistribute, but please give credit to the original author.

#####CHANGELOG####
#1.4.3:
#	Added changelog
#	Added functionality to detect lock and click if not unlocked
#1.5:
#	Attempt to make compatible for OSX yosemite 10.10.1, test results on my machine are successful, need more results to push stable.
#	Fixed some typos
#	Moved to use of functions
#1.6:
#	Added configurability, bugfixes, and command-line options
##################

##TODO##
#Make applescript more robust and compatible, need to be able to handle for multiple ethernet ports, as well as bluetooth PAN/DUN.
#May make something which collects the available options and displays them in a box, for someone to choose from


#Notes:
#En0 is ethernet port 0
#En3 is ethernet port 2
#En1 is Wifi
#En2 is usually bluetooth PAN


#Functions

function validateIP()
{
	local  ip=$1
	local  stat=1
	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
			&& ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi
	return $stat
}

function disableICS {
osascript << 'END'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preferences.sharing"
end tell
tell application "System Events" to tell process "System Preferences"
	--Find lock and click if not unlocked
	repeat with x in buttons of window "Sharing"
		try
			if (value of attribute "AXTitle" of x) is equal to "Click the lock to make changes." then
				click x
			end if
		end try
	end repeat
	delay 1

	--disable Internet Sharing
	repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
		if (value of static text of r as text) starts with "Internet" then
			set sharingBool to value of checkbox of r as boolean
			select r
			if sharingBool is true then click checkbox of r
		end if
	end repeat
	delay 1
end tell
ignoring application responses
	tell application "System Preferences" to quit
end ignoring
END
}


function enableICS {
osascript << 'END2'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preferences.sharing"
end tell
tell application "System Events" to tell process "System Preferences"
	--find lock and click it if it is not unlocked
	repeat with x in buttons of window "Sharing"
		try
			if (value of attribute "AXTitle" of x) is equal to "Click the lock to make changes." then
				click x
			end if
		end try
	end repeat
	delay 5
	--find the checkbox for Internet Sharing and select the row so script can enable sharing through ethernet
	repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
		if (value of static text of r as text) starts with "Internet" then
			select r
		end if
	end repeat
	delay 1
	
	--Select WiFi from dropdown
	click (pop up buttons of group 1 of window "Sharing")
	click menu item "Wi-Fi" of menu of (pop up buttons of group 1 of window "Sharing")
	
	--find and select ethernet for sharing
	repeat with r2 in rows of table 0 of scroll area 2 of group 1 of window "Sharing"
		if (value of text field of r2 as text) starts with "Ethernet" then
			set enetBool to value of checkbox of r2 as boolean
			select r2
			if enetBool is false then click checkbox of r2
		end if
	end repeat
	delay 2
	
	--enable Internet Sharing
	repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
		if (value of static text of r as text) starts with "Internet" then
			set sharingBool to value of checkbox of r as boolean
			select r
			if sharingBool is false then click checkbox of r
		end if
	end repeat
	delay 1
	
	if (exists sheet 1 of window "Sharing") then
		click button "Start" of sheet 1 of window "Sharing"
	end if
	delay 1
end tell
ignoring application responses
	tell application "System Preferences" to quit
end ignoring
END2
}


function toggleICS {
osascript << 'END3'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preferences.sharing"
end tell
tell application "System Events" to tell process "System Preferences"
	--find lock and click if not unlocked
	repeat with x in buttons of window "Sharing"
		try
			if (value of attribute "AXTitle" of x) is equal to "Click the lock to make changes." then
				click x
			end if
		end try
	end repeat
	delay 1
	--find the checkbox for Internet Sharing and select the row so script can enable sharing through ethernet
	repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
		if (value of static text of r as text) starts with "Internet" then
			select r
		end if
	end repeat
	delay 1
	
	--Select WiFi from dropdown
	click (pop up buttons of group 1 of window "Sharing")
	click menu item "Wi-Fi" of menu of (pop up buttons of group 1 of window "Sharing")
	
	--find and select ethernet for sharing
	repeat with r2 in rows of table 0 of scroll area 2 of group 1 of window "Sharing"
		if (value of text field of r2 as text) equals "Ethernet" then
			set enetBool to value of checkbox of r2 as boolean
			select r2
			if enetBool is false then click checkbox of r2
		end if
	end repeat
	delay 1
	
	--enable Internet Sharing
	repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
		if (value of static text of r as text) starts with "Internet" then
			select r
			click checkbox of r
			if (exists sheet 1 of window "Sharing") then
				click button "Start" of sheet 1 of window "Sharing"
			end if
			delay 1
			click checkbox of r
		end if
	end repeat
	delay 1
	
end tell
ignoring application responses
	tell application "System Preferences" to quit
end ignoring
END3
}


#Check for root
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

#Set Version variable, periods removed for easy comparing.
VERSION=$(sw_vers -productVersion | tr -d '.')

#Check for versions less than 10.7.5
if [ $VERSION == "106"* ]; then
	echo "This script is unsupported on your OS version"
	exit 2
fi


GATEWAYIP="172.16.42.42"
NETWORKIP="172.16.42.0"
NETWORKEND="172.16.42.254"
DNSIP="8.8.8.8"
DNSALT="8.8.4.4"
USEWPP=true

while getopts ":rhvng:d:a:" opt; do
	case $opt in
		h)
			echo "Options:"
			echo "-g		Specify gateway"
			echo "-d		Specify DNS"
			echo "-a		Specify alternate DNS"
			echo "-h		Display brief help"
			echo "-v		Display version info and exit"
			echo "-n		Do not use completed configs (Generate new)"
			echo "-r		Removes modified files, attempt to restore from backups"
			exit 0			
			;;
		v)
			echo "System version code: $VERSION"
			echo "Script version: $SCVER"
			exit 0
			;;
		n)
			USEWPP=false
			;;
		g)
			if validateIP $OPTARG; then 
				GATEWAYIP=$OPTARG
			else
				echo "Invallid gateway IP... EXITING!"
				exit 1
			fi
			temp=`echo $GATEWAYIP | cut -d"." -f1-3`
			NETWORKIP=`echo $temp".0"`
			NETWORKEND=`echo $temp".254"`
			;;
		d)
			if validateIP $OPTARG; then 
				DNSIP=$OPTARG
			else
				echo "Invallid DNS IP... EXITING!"
				exit 1
			fi
			;;
		a)
			if validateIP $OPTARG; then 
				DNSALT=$OPTARG
			else
				echo "Invallid Alternate DNS IP... EXITING!"
				exit 1
			fi
			;;
		r)
			ICSPID=$(pgrep InternetSharing)
			if [ $? == "0" ]; then
				echo "Killing ICS"
				disableICS
				sleep 1
			fi
			if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.plist ]; then
				rm /Library/Preferences/SystemConfiguration/com.apple.nat.plist
				echo "Removed old NAT file"
			fi
			if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile ]; then
				rm /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile
				echo "Removed old NAT lock file"
			fi
			if [ $VERSION != "1010"* ]; then
				if [ -e /etc/bootpd.plist ]; then
					rm /etc/bootpd.plist
					echo "Removed old bootpd file"
				fi
			fi
			if [ -d /wpplist/ ]; then
				rm -r /wpplist/
				echo "Removed completed configs directory"
			fi
			if [ -d /plistbackups/ ]; then
				if [ -e /plistbackups/com.apple.nat.plist ]; then
					cp /plistbackups/com.apple.nat.plist /Library/Preferences/SystemConfiguration/
					echo "Restored NAT file from backup"
				fi
				if [ -e /plistbackups/com.apple.nat.plist.lockfile ]; then
					cp /plistbackups/com.apple.nat.plist.lockfile /Library/Preferences/SystemConfiguration/
					echo "Restored NAT lockfile from backup"
				fi
				if [ -e /plistbackups/bootpd.plist ]; then
					cp /plistbackups/bootpd.plist /etc/
					echo "Restored bootpd file from backup"
				fi
			else
				echo "No plist backups found to restore from, this is usually not an issue, as enabling ICS manually or running this script usually generates them."
			fi
			exit 0
			;;
	  	\?)
			echo "Invalid option: -$OPTARG" >&2
			;;
	esac
done


#Get netrange from GWIP
IFS=. read ip1 ip2 ip3 ip4 <<< "$GATEWAYIP"
temp=`echo $GATEWAYIP | cut -d"." -f1-3`
temp2=`expr $ip4 + 1`
NETRANGE=`echo $temp"."$temp2`


#Check for plist backup dir and if not there, create it and backup default configs, but do not overwrite them
if [ ! -d /plistbackups ]; then
	echo "Backing up default plists"
	mkdir /plistbackups
	disableICS
	if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.plist ]; then
		cp /Library/Preferences/SystemConfiguration/com.apple.nat.plist /plistbackups/
		echo "Backed up old NAT file"
	fi
	if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile ]; then
		cp /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile /plistbackups/
		echo "Backed up old NAT lock file"
	fi
	if [ $VERSION != "1010"* ]; then
		if [ -e /etc/bootpd.plist ]; then
			cp /etc/bootpd.plist /plistbackups/
			echo "Backed up old bootpd file"
		fi
	fi
	sleep 1
fi

#Check for and kill ICS if it's already running
ICSPID=$(pgrep InternetSharing)
if [ $? == "0" ]; then
	echo "Killing ICS"
	disableICS
	sleep 1
fi

#If completed configs exist, use them
if [ -d /wpplist ] && [ $USEWPP == true ]; then
	if [ ! -e /wpplist/params ]; then
		echo "No /wpplist/params file... EXITING!"
		exit 1
	fi
	i="0"
	while read line; do
		file[$i]=$line
		i=`expr $i + 1`
	done < /wpplist/params
	WPGATEWAY=${file[0]}
	WPDNS=${file[1]}
	WPALT=${file[2]}
	if ! validateIP $WPGATEWAY; then 
		echo "Invallid gateway IP from wpparams... EXITING!"
		exit 1
	fi
	if ! validateIP $WPDNS; then 
		echo "Invallid DNS IP from wpparams... EXITING!"
		exit 1
	fi
	if ! validateIP $WPALT; then 
		echo "Invallid Alternate DNS IP from wpparams... EXITING!"
		exit 1
	fi

	#Copy nat config
	cp /wpplist/com.apple.nat.plist /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	echo "Restored from previous completed configs"

	#Start ICS
	enableICS
	sleep 1
	echo "ICS started"

	#Check for existence of bridge100 and if it's there, use it, otherwise, use en0
	junk=$(ifconfig bridge100 2>&1)
	if [ $? == 0 ]; then
		ifconfig bridge100 $WPGATEWAY netmask 255.255.255.0 up
		echo "IP on bridge100 set to $WPGATEWAY"
		sleep 1
	else
		ifconfig en0 $WPGATEWAY netmask 255.255.255.0 up
		echo "IP on en0 set to $WPGATEWAY"
		sleep 1
	fi

	#Set DNS
	networksetup -setdnsservers Ethernet $WPDNS $WPALT
	echo "Set Primary DNS to $WPDNS Alternate to $WPALT"
	sleep 1

	#Copy bootpd
	if [ $VERSION != "10101" ]; then
		cp /wpplist/bootpd.plist /etc/bootpd.plist
		#Reload bootpd
		kill -HUP $(pgrep bootpd)
		sleep 1
		echo "Reloaded bootpd file for DHCP"
	fi
	exit
fi


#Use applescript to reliably create NAT file
toggleICS
echo "NAT file created"

#Write the NAT parameters to the file using the defaults command
defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkNumberStart $NETWORKIP
if [ $VERSION == "1010"* ]; then
	defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkNumberEnd $NETWORKEND
	defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkMask 255.255.255.0
fi
sleep 1
echo "NAT file edited"

#Start sharing again
enableICS
sleep 1
echo "ICS started"

#Check for existence of bridge100 and if it's there, use it, otherwise, use en0
	junk=$(ifconfig bridge100 2>&1)
	if [ $? == 0 ]; then
		ifconfig bridge100 $GATEWAYIP netmask 255.255.255.0 up
		echo "IP on bridge100 set to $GATEWAYIP"
		sleep 1
	else
		ifconfig en0 $GATEWAYIP netmask 255.255.255.0 up
		echo "IP on en0 set to $GATEWAYIP"
		sleep 1
	fi

#Set DNS
networksetup -setdnsservers Ethernet $DNSIP $DNSALT
echo "Set Primary DNS to $DNSIP Alternate to $DNSALT"
sleep 1

#Edit bootpd
if [ $VERSION != "1010"* ]; then
	/usr/libexec/PlistBuddy -c "set :Subnets:0:dhcp_domain_name_server:0 '$GATEWEAYIP'" /etc/bootpd.plist
	/usr/libexec/PlistBuddy -c "set :Subnets:0:dhcp_router '$GATEWAYIP'" /etc/bootpd.plist
	/usr/libexec/PlistBuddy -c "Set :Subnets:0:net_range:0 '$NETRANGE'" /etc/bootpd.plist
sleep 1
echo "Rewritten bootpd file for DHCP"
fi

#Make backup of configured files for future use
if [ ! -d /wpplist ]; then
	mkdir /wpplist
	touch /wpplist/params
	sleep 1
	echo "Made backup directory for completed config files"
fi
cp /Library/Preferences/SystemConfiguration/com.apple.nat.plist /wpplist
cp /etc/bootpd.plist /wpplist
echo $GATEWAYIP > /wpplist/params
echo $DNSIP >> /wpplist/params
echo $DNSALT >> /wpplist/params
sleep 1
echo "Copied completed config files"

#Reload bootpd process
if [ $VERSION != "1010"* ]; then
	kill -HUP $(pgrep bootpd)
	sleep 1
	echo "Reloaded bootpd file for DHCP"
fi
