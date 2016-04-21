# check_overlandstorage
Nagios &amp; Icinga 2 plugin for Overland Storage SnapServer N2000 and others

This plugin have been tested on Overland Storage SnapServer N2000.
You may need to modify OID for your snap server if it's a different model or
running a version of GuardianOS other than 6.5. Check GOS documentation for 
supported MIBs.

Tested with icinga2. It should also work with Nagios and its forks.


Usage:

check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t disk
DISK OK - 12 disks found, no problems
check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t raid
DISK OK - 3 raids found, no problems
check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t nic
NIC OK - 9 nics found, no problems
check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t info
ARRAYNAME, Uptime: 305 days, 16:34:52.58

Help:

Usage: ./check_overlandstorage -H host -C community -t type [-w warning] [-c critical]
Requirements: snmpwalk, sed, cut, echo, grep, 

Options:        -H hostname
                -C community (to be defined in snmpv2 settings on OverlandStorage SnapServer)
                -t Type to check, see list below
                -w Warning Threshold (optional)
                -c Critical Threshold (optional)

Types:          disk -> Checks hard disks for their current status
                raid -> Checks the RAID status
                cpu -> Check current CPU load (thresholds possible)
                info -> Outputs some general information of the device
