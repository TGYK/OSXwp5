#OSX Internet Connection Sharing, made automatic.
##Current version: 1.7(Beta)
 
Be sure to enable access for assistive devices(10.8 and lower)
System Preferences > Accessibility > Check "Enable access for assistive devices" at bottom of window
 
On newer machines(10.9 and up), add Terminal to the Accessibility section of the Privacy tab of the Security and Privacy settings instead
System Preferences > Security & Privacy > Select "Privacy" tab at top of window > Select "Accessibility" Tab at left side of window > Click the lock and log in to allow changes > Click the "+" sign below the table > Navigate to /Applications/Utilities/Terminal and select "Open" in the bottom, right hand corner

USAGE:

sudo chmod +x scriptname

sudo ./scriptname [options]

Options:
* -g		Specify gateway IP
* -d		Specify DNS IP
* -a		Specify alternate DNS IP
* -h		Display brief help
* -v		Display version info and exit
* -n		Do not use completed configs (Generate new)
* -r		Removes modified files, attempt to restore from backups

##IMPORTANT NOTES:
* If you run the script on OS X 10.10 Yosemite and get messages saying osascript is not allowed assistive access, please follow the instructions above, and enable assistive access for the Terminal, or however you run the script.
* If you run the script on OS X 10.10 Yosemite and get messages claiming that the IP was changed on an enX interface, please manually disable sharing, run the script with the -r option, then again with the -n option.
* If you ran the script before adding it to assistive devices/allowing to control computer, OR you used a script version prior to 1.6, you must remove the /wpplist folder. This can be achieved with 1.6+ by running with the -r or the -n options. -r will restore backed up configs, -n will simply generate new configs.
