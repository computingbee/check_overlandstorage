# check_overlandstorage
Nagios &amp; Icinga 2 plugin for Overland Storage SnapServer N2000 and others

This plugin have been tested on Overland Storage SnapServer N2000.
You may need to modify OID for your snap server if it's a different model or
running a version of GuardianOS other than 6.5. Check GOS documentation for 
supported MIBs.

Tested with icinga2. It should also work with Nagios and its forks.


Example:

check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t disk

DISK OK - 12 disks found, no problems

check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t raid

DISK OK - 3 raids found, no problems

check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t nic

NIC OK - 9 nics found, no problems

check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t info

ARRAYNAME, Uptime: 305 days, 16:34:52.58


Requirements: snmpwalk, sed, cut, echo, grep, 

Help: check_overlandstorage --help
