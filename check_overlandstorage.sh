#!/bin/bash
#################################################################################
# Script:       check_overlandstorage                                           #
# Author:       Haris Buchal blog.axiomdynamics.com                             #
# Description:  Plugin for Nagios (and forks) to check Overland Storage         #
#               SnapServer N2000 device with SNMP v2.                           #
#               It might also work on other Overland Storage devices given      #
#               those devices implement SNMP MIBs from following RFCs:          #
#                                                                               #
#               https://tools.ietf.org/html/rfc2790.txt                         #
#               http://www.oidview.com/mibs/0/HOST-RESOURCES-MIB.html           #
#                                                                               #
#               https://www.ietf.org/rfc/rfc1213.txt                            #
#               http://www.oidview.com/mibs/0/RFC1213-MIB.html                  #
#                                                                               #
# Based On:     check_storcenter by Claudio Kuenzler www.claudiokuenzler.com    #
# License:      GPLv2                                                           #
# History:                                                                      #
# 20160421      Created plugin (types: disk, raid, nic, info)                   #
#################################################################################
# Usage:        ./check_overlandstorage -H host -C community -t type [-w warning] [-c critical]
#################################################################################
help="check_overlandstorage (c) 2016 Haris Buchal published under GPL license
Usage: ./check_overlandstorage -H host -C community -t type [-w warning] [-c critical]
Requirements: snmpwalk, sed, cut, echo, grep, 

Options:	-H hostname
		-C community (to be defined in snmpv2 settings on OverlandStorage SnapServer)
		-t Type to check, see list below
		-w Warning Threshold (optional)
		-c Critical Threshold (optional)

Types: 		disk -> Checks hard disks for their current status
		raid -> Checks the RAID status
		cpu -> Check current CPU load (thresholds possible)
		info -> Outputs some general information of the device"

# Nagios exit codes and PATH
STATE_OK=0              # define the exit code if status is OK
STATE_WARNING=1         # define the exit code if status is Warning
STATE_CRITICAL=2        # define the exit code if status is Critical
STATE_UNKNOWN=3         # define the exit code if status is Unknown
PATH=$PATH:/usr/local/bin:/usr/bin:/bin # Set path

# If the following programs aren't found, we don't launch the plugin
for cmd in snmpwalk sed cut echo grep [
do
 if ! `which ${cmd} 1>/dev/null`
 then
 echo "UNKNOWN: ${cmd} does not exist, please check if command exists and PATH is correct"
 exit ${STATE_UNKNOWN}
 fi
done
#################################################################################
# Check for people who need help - aren't we all nice ;-)
if [ "${1}" = "--help" -o "${#}" = "0" ];
       then
       echo -e "${help}";
       exit 1;
fi
#################################################################################
# Get user-given variables
while getopts "H:C:t:w:c:" Input;
do
       case ${Input} in
       H)      host=${OPTARG};;
       C)      community=${OPTARG};;
       t)      type=${OPTARG};;
       w)      warning=${OPTARG};;
       c)      critical=${OPTARG};;
       *)      echo "Wrong option given. Please use options -H for host, -C for SNMPv2 community, -t for type, -w for warning and -c for critical"
               exit 1
               ;;
       esac
done
# Let's check that thing
case ${type} in

# Disk or RAID Check
disk|raid)
        disktype="RAID"
        if [ ${type} = "disk" ]; then disktype="SCSI"; fi

        disknames=($(snmpwalk -v 2c -c ${community} ${host} .1.3.6.1.2.1.25.3.2.1.3 | grep -i ${disktype} | sed s/'STRING\|:\|"\|SCSI\|disk\|(\|)\| '//g | sed s/"iso\.3\.6\.1\.2\.1\.25\.3\.2\.1\.3\."//g | sed s/=/','/g))
        countdisks=${#disknames[*]}
        unset diskstatus
        diskstatus=()

        #we need to get disk status individually
        for diskname in ${disknames[@]}
        do 
        	disknumber=($(echo $diskname | cut -d ',' -f1)) 
                diskstatus+=($disknumber,$(snmpwalk -v 2c -c ${community} ${host} .1.3.6.1.2.1.25.3.2.1.5.$disknumber | cut -d '=' -f2 | cut -d ':' -f2 | sed s/' '//g)) 
        done

        # disk states per https://tools.ietf.org/html/rfc2790#section-4.4 and http://www.oidview.com/mibs/0/HOST-RESOURCES-MIB.html
        diskstatusunknown=0 #unknown(1)
        diskstatusrunning=0 #running(2)
        diskstatuswarning=0 #warning(3)
        diskstatustesting=0 #testing(4)
        diskstatusdown=0 #down(5)
        disknumber=0
 
        unset diskproblem
        diskproblem=()

        for status in ${diskstatus[@]}
        do
            	istatus=($(echo $status | cut -d ',' -f2))
                if [ $istatus == 2 ]; then diskstatusrunning=$((diskstatusrunning + 1)); fi
                if [ $istatus == 1 ]; then diskstatusunknown=$((diskstatusunknown + 1)); diskproblem[${disknumber}]=${disknames[${disknumber}]}; fi
                if [ $istatus == 3 ]; then diskstatuswarning=$((diskstatuswarning + 1)); diskproblem[${disknumber}]=${disknames[${disknumber}]}; fi
                if [ $istatus == 4 ]; then diskstatustesting=$((diskstatustesting + 1)); diskproblem[${disknumber}]=${disknames[${disknumber}]}; fi
                if [ $istatus == 5 ]; then diskstatusdown=$((diskstatusdown + 1)); diskproblem[${disknumber}]=${disknames[${disknumber}]}; fi
        let disknumber++
        done

        #runtime debugging
        #echo -e "${disknames[*]}\n"
        #echo -e "${diskstatus[*]}\n"
        #echo -e "${diskproblem[*]}\n"
 
        if [ $diskstatusunknown -gt 0 ] || [ $diskstatuswarning -gt 0 ] || [ $diskstatustesting -gt 0 ] || [ $diskstatusdown -gt 0 ] 
        then 
		echo "DISK CRITICAL - ${#diskproblem[@]} ${type}(s) failed (${diskproblem[@]})"; exit ${STATE_CRITICAL};
        else 
		echo "DISK OK - ${countdisks} ${type}s found, no problems"; exit ${STATE_OK}
        fi
;;
nic)
        ifnames=($(snmpwalk -v 2c -c ${community} ${host} .1.3.6.1.2.1.2.2.1.2 | cut -d ' ' -f4  | cut -d '"' -f2))
        countifs=${#ifnames[*]}
        ifstatus=($(snmpwalk -v 2c -c ${community} ${host} .1.3.6.1.2.1.2.2.1.8 | cut -d ' ' -f4))

        # if states per https://www.ietf.org/rfc/rfc1213.txt and http://www.oidview.com/mibs/0/RFC1213-MIB.html
        ifstatusup=0 		#up(1)
        ifstatusdown=0 		#down(2)
        ifstatustest=0 		#testing(3)
        ifnumber=0
 
        unset ifproblem
        ifproblem=()

        for status in ${ifstatus[@]}
        do
                if [ $status == 1 ]; then ifstatusup=$((ifstatusup + 1)); fi
                if [ $status == 2 ]; then ifstatusdown=$((ifstatusdown + 1)); ifproblem[${ifnumber}]=${ifnames[${ifnumber}]}; fi
                if [ $status == 3 ]; then ifstatustest=$((ifstatustest + 1)); ifproblem[${ifnumber}]=${ifnames[${ifnumber}]}; fi
        let ifnumber++
        done

        #runtime debugging
        #echo -e "${ifnames[*]}\n"
        #echo -e "${ifstatus[*]}\n"
        #echo -e "${ifproblem[*]}\n"
 
        if [ $ifstatusdown -gt 0 ] || [ $ifstatustest -gt 0 ] 
        then 
		echo "NIC CRITICAL - ${#ifproblem[@]} nics failed (${ifproblem[@]})"; exit ${STATE_CRITICAL};
        else 
		echo "NIC OK - ${countifs} nics found, no problems"; exit ${STATE_OK}
        fi
;;
info)   
 	uptime=$(snmpwalk -v 2c -c ${community} ${host} 1.3.6.1.2.1.25.1.1 | cut -d ' ' -f5-7)
        hostname=$(snmpwalk -v 2c -c ${community} ${host} 1.3.6.1.2.1.1.5 | cut -d ' ' -f4 | cut -d '"' -f2)
        echo "${hostname}, Uptime: ${uptime}"; exit ${STATE_OK}
esac

echo "Unknown error"; exit ${STATE_UNKNOWN}
