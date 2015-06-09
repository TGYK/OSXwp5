#!/bin/bash

#MK5 Internet Connection Sharing for Apple
#v1.4.3
#By TGYK
#Special thanks to Bl1tz3dShad0w for testing and feedback on OS X 10.10 Yosemite for me
#This script is distributed without any warranty, and is not guarenteed to work. Feel free to modify and redistribute, but please give credit to the original author.

#####CHANGELOG####
#1.4.3:
#	added changelog
#	added functionality to detect lock and click if not unlocked
##################



#Check for root
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

#Set Version variable, periods removed for easy comparing.
VERSION=$(sw_vers -productVersion | tr -d '.')

#Check for versions less than 10.7.5
if [ $VERSION -lt "1075" ]; then
	echo "This script is unsupported on your OS version"
	exit 2
fi


#Check for plist backup dir and if not there, create it
if [ ! -d /plistbackups ]; then
        mkdir /plistbackups
fi

#Check for and kill ICS if it's already running
ICSPID=$(pgrep InternetSharing)
if [ $? == "0" ]; then
	echo "Killing ICS"
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
	sleep 1
fi

#Backup old NAT files and bootpd
if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.plist ]; then
	cp /Library/Preferences/SystemConfiguration/com.apple.nat.plist /plistbackups/
	echo "Backed up old NAT file"
fi
if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile ]; then
	cp /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile /plistbackups/
	echo "Backed up old NAT lock file"
fi
if [ -e /etc/bootpd.plist ]; then
	cp /etc/bootpd.plist /plistbackups/
	echo "Backed up old bootpd file"
fi
sleep 1

#If completed configs exist, use them
if [ -d /wpplist ]; then
	#Copy nat config
	cp /wpplist/com.apple.nat.plist /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	echo "Restored from previous completed configs"

	#Start ICS
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
		if (value of text field of r2 as text) starts with "Ethernet" then
			set enetBool to value of checkbox of r2 as boolean
			select r2
			if enetBool is false then click checkbox of r2
		end if
	end repeat
	delay 1
	
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
	sleep 1
	echo "ICS started"

	#Check for existance of bridge100 and if it's there, use it, otherwise, use en0
	junk=$(ifconfig bridge100 2>&1)
	if [ $? == 1 ]; then
		ifconfig en0 172.16.42.42 netmask 255.255.255.0 up
		echo "IP on en0 set to 172.16.42.42"
		sleep 1
	else
		ifconfig bridge100 172.16.42.42 netmask 255.255.255.0 up
		echo "IP on bridge100 set to 172.16.42.42"
		sleep 1
	fi

	#Set DNS to google public DNS because they're usually quicker and more reliable, feel free to comment out if you don't wish to use google public DNS
	networksetup -setdnsservers Ethernet 8.8.8.8 8.8.4.4
	echo "Set DNS to Google public DNS"
	sleep 1

	#Copy bootpd
	cp /wpplist/bootpd.plist /etc/bootpd.plist

	#Reload bootpd
	kill -HUP $(pgrep bootpd)
	sleep 1
	echo "Reloaded bootpd file for DHCP"
	exit
fi


#Use applescript to reliably create NAT file
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
		if (value of text field of r2 as text) starts with "Ethernet" then
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
echo "NAT file created"

#Write the NAT parameters to the file using the defaults command
defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkNumberStart 172.16.42.0
if [ $VERSION -gt "1075" ]; then
	defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkNumberEnd 172.16.42.254
	defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkMask 255.255.255.0
fi
sleep 1
echo "NAT file edited"

#Start sharing again
osascript << 'END4'
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
		if (value of text field of r2 as text) starts with "Ethernet" then
			set enetBool to value of checkbox of r2 as boolean
			select r2
			if enetBool is false then click checkbox of r2
		end if
	end repeat
	delay 1
	
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
END4
sleep 1
echo "ICS started"

#Check for existance of bridge100 and if it's there, use it, otherwise, use en0
junk=$(ifconfig bridge100 2>&1)
if [ $? == 1 ]; then
	ifconfig en0 172.16.42.42 netmask 255.255.255.0 up
	sleep 1
	echo "IP on en0 set to 172.16.42.42"
else
	ifconfig bridge100 172.16.42.42 netmask 255.255.255.0 up
	sleep 1
	echo "IP on bridge100 set to 172.16.42.42"
fi

#Set DNS to google public DNS because they're usually quicker and more reliable, feel free to comment out if you don't wish to use google public DNS
networksetup -setdnsservers Ethernet 8.8.8.8 8.8.4.4
echo "Set DNS to google public DNS"
sleep 1

#Edit bootpd
/usr/libexec/PlistBuddy -c "set :Subnets:0:dhcp_domain_name_server:0 '172.16.42.42'" /etc/bootpd.plist
/usr/libexec/PlistBuddy -c "set :Subnets:0:dhcp_router '172.16.42.42'" /etc/bootpd.plist
/usr/libexec/PlistBuddy -c "set :Subnets:0:net_range:0 '172.16.42.43'" /etc/bootpd.plist
sleep 1
echo "Rewritten bootpd file for DHCP"

#Make backup of configured files for future use
if [ ! -d /wpplist ]; then
	mkdir /wpplist
	sleep 1
	echo "Made backup directory for completed config files"
fi
cp /Library/Preferences/SystemConfiguration/com.apple.nat.plist /wpplist
cp /etc/bootpd.plist /wpplist
sleep 1
echo "Copied completed config files"

#Reload bootpd process
kill -HUP $(pgrep bootpd)
sleep 1
echo "Reloaded bootpd file for DHCP"
