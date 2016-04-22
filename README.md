#### Nagios & Icinga 2 plugin for Overland Storage SnapServer N2000 and others

This plugin have been tested on Overland Storage SnapServer N2000. You may need to modify OID for your snap server if it's a different model or running a version of GuardianOS other than 6.5. Check GOS documentation for supported MIBs. At the time GOS 6.5 was responds to following MIBs:

* [https://tools.ietf.org/html/rfc2790.txt]
* [https://www.ietf.org/rfc/rfc1213.txt]
* [http://www.oidview.com/mibs/0/HOST-RESOURCES-MIB.html]
* [http://www.oidview.com/mibs/0/RFC1213-MIB.html]

Tested with icinga2. It should also work with Nagios and its forks.

#### Examples:
```sh
check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t disk
DISK OK - 12 disks found, no problems

check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t raid
DISK OK - 3 raids found, no problems

check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t nic
NIC OK - 9 nics found, no problems

check_overlandstorage.sh -H <hostname_or_ip> -C <community> -t info
Hostname, Uptime: 305 days, 16:34:52.58
```

#### Requirements
```sh
snmpwalk, sed, cut, echo, grep
```

#### Help
```sh
./check_overlandstorage --help
```
