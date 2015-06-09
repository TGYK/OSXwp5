#!/bin/bash
#MKV ICS for Apple
#v1.3.2
#By TGYK

#Check for root
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

ifconfig en0 down

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
	mv /Library/Preferences/SystemConfiguration/com.apple.nat.plist /plistbackups
	echo "Removed old NAT file"
fi
if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile ]; then
	mv /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile /plistbackups
	echo "Removed old NAT lock file"
fi
if [ -e /etc/bootpd.plist ]; then
	mv /etc/bootpd.plist /plistbackups
	echo "Removed old bootpd file"
fi
sleep 1

#Use applescript to reliably create NAT file
osascript << 'END2'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preferences.sharing"
end tell
tell application "System Events" to tell process "System Preferences"
	
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
END2
echo "NAT file created"

#Write the NAT default to the file
defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkNumberStart 172.16.42.0
sleep 1
echo "NAT file edited"

#Start sharing again
osascript << 'END3'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preferences.sharing"
end tell
tell application "System Events" to tell process "System Preferences"
	
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
END3
sleep 1
echo "ICS started"

#Set en0 to be 172.16.42.42
junk=$(ifconfig bridge100 2>&1)
if [ $? == 1 ]; then
	ifconfig en0 172.16.42.42 netmask 255.255.255.0 up
	sleep 1
	echo "IP on en0 set tp 172.16.42.42"
else
	ifconfig bridge100 172.16.42.42 netmask 255.255.255.0 up
	sleep 1
	echo "IP on bridge100 set tp 172.16.42.42"
fi

cat /etc/bootpd.plist | sed s/172.16.42.1\</172.16.42.42\</g | sed s/172.16.42.2\</172.16.42.43\</g > /etc/bootpd.plist
sleep 1
echo "Rewritten bootpd file for DHCP"

#reload bootpd process
kill -HUP $(pgrep bootpd)
sleep 1
echo "Reloaded bootpd file for DHCP"
