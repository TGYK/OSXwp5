#!/bin/bash
#MKV ICS for Apple
#v1.2
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
	click checkbox 1 of row 11 of table 1 of scroll area 1 of group 1 of window "Sharing"
	delay 1
	if (exists sheet 1 of window "Sharing") then
		click button "Start" of sheet 1 of window "Sharing"
	end if
	delay 1
end tell
ignoring application responses
	tell application "System Preferences" to quit
end ignoring
END
	sleep 1
fi

#Remove old NAT files and bootpd
if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.plist ]; then
	rm /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	echo "Removed old NAT file"
fi
if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile ]; then
	rm /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile
	echo "Removed old NAT lock file"
fi
if [ -e /etc/bootpd.plist ]; then
	rm /etc/bootpd.plist
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
	tell table 0 of scroll area 2 of group 1 of window "Sharing"
		select row 2
	end tell
	set theCheckbox to checkbox 1 of row 2 of table 1 of scroll area 2 of group 1 of window "Sharing"
	tell theCheckbox
		set theCheckboxBool to value of theCheckbox as boolean
		if theCheckboxBool is false then click theCheckbox
	end tell
	delay 1
	click checkbox 1 of row 11 of table 1 of scroll area 1 of group 1 of window "Sharing"
	delay 1
	if (exists sheet 1 of window "Sharing") then
		click button "Start" of sheet 1 of window "Sharing"
	end if
	delay 1
	click checkbox of row 11 of table 1 of scroll area 1 of group 1 of window "Sharing"
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
	click checkbox 1 of row 11 of table 1 of scroll area 1 of group 1 of window "Sharing"
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
