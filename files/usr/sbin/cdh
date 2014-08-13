#!/bin/sh

#================================================================
# Commotion Bug Info
#================================================================
#
#Commotion Bug Info runs a series of scripts to gather information about a node.
#This is a simple way to automate data collection from new or inexperienced node owners.
#

#==================PreDefined Values=================
FILE=/tmp/debug.info
APPEND=prep

#=========================FUNCTION========================= 
# Name: Usage
# Description: Display usage information
#===========================================================

usage()
{
	cat <<- EOF

A debugging information collection script. Default output is sent to a file /tmp/debug.info

Usage: $0 [options] [OBJECT]

Options:
    -o|output    Define where the output file is located.
    -a|append    Append out to an existing file.

Objects:
    network    Outputs network related data from a node.
    rules      Outputs rule related data from a node.
    state      Outputs node operating data.
    all        all possible data is output to the file

EOF
}

#======================Check Input=================

#Check to see if -o flag is given
while getopts "o:a" OPTION
do
	    case $OPTION in
			o)
				FILE="$OPTARG"
				;;
			 a)
				APPEND=append
				;;
			[?])
				usage
				exit 1
				;;
			
    esac
done
shift $(($OPTIND-1))

if [ $# -ne 1 ]; then
	usage
    exit 1
fi

OBJECT="$1"


#If no commands are given show the usage info.
if [ $# -eq 0 ]; then
	usage
	exit 1
fi



#=====================================================================================
# PREPARATION AND FORMATTING
#=====================================================================================
flair()
{
	echo "--------------------------------------------------------------------" >> $FILE
	echo "$1" >> $FILE
	echo "--------------------------------------------------------------------" >> $FILE
}

prep()
{
	date>$FILE
}
append()
{
	date>>$FILE
	flair "BEGIN DEBUGGING INFO"
}
#===================================================================
# MAIN FUNCTION
#===================================================================

network()
{	
	flair "IP Routing Table: (route -n)"
	route -n >> $FILE
	
	flair "IP Routing Tables (ip route list table all):"
	ip route list table all >> $FILE
	
	flair "JSON INFO:(wget http://localhost:2006)"
	if (wget -q http://localhost:2006 -O /tmp/json.info 2>/dev/null); then
	cat /tmp/json.info >> $FILE
	wait
	rm /tmp/json.info
	wait
	fi	
	flair "IP Routing Table's for Smart Gateway:(ip route ls table [224 & 223])"
	echo -e "---------------OLSRd Standard Default Route---------------------" >> $FILE
	ip route ls table 223 >> $FILE
	echo -e "---------------Smart Gateway Default Route---------------------" >> $FILE
	ip route ls table 224 >> $FILE

	dev scan
	dev station dump
}

rules()
{
	flair "IP Filter Tables: (iptables -nvL)"
	iptables -nvL >> $FILE
	
	flair "IP NAT Filter Table: (iptables -t nat -nvL)"
	iptables -t nat -nvL >> $FILE
	
	flair "IP Routing Rules: (ip rule show)"
	ip rule show >> $FILE
	
	flair "UCI Firewall Rules: (uci show firewall)"
	uci show firewall >> $FILE
	
	flair "UCI Firewall Current State: (uci show -p /var/state firewall)"
	uci show -p /var/state firewall  >> $FILE
	
	flair "Nodogsplash Info:(ndsctl status)"
	ndsctl status >> $FILE
}

state()
{
	flair "Kernel Buffer Log: (dmesg)"
	dmesg >> $FILE
	
	flair "Device Logs: (logread)"
	logread >> $FILE
	
	
	flair "UCI info: (uci show)"
	uci -q show >> "$FILE" 

	
	
	flair "Current Processes: (ps -w)"
	ps -w >> $FILE
	
	flair "Router uptime and Load: (uptime)"
	uptime >> $FILE

	phy info
	dev info
	dev link
}

#======================================================
# radio identifier and Scanner
#=======================================================
dev()
{
	local i=0
	local DEV=
	while [ $? -eq 0 ]
	do
		DEV=`uci -P /var/state -q get wireless.@wifi-iface[$i].ifname`
		if [ $? -eq 0 ]
		then
			flair "$DEV $1"
			iw dev $DEV $@ >> $FILE
			i=$(($i+1))
		elif [ $? -eq 1 ]
		then
			break
			exit 0
		fi
	done
}

phy()
{
	local i=0
	local PHY=
	while [ $? -eq 0 ]
	do
		PHY=`uci -q get wireless.@wifi-device[$i]`
		if [ $? -eq 0 ]
		then
			flair "phy$i $1"
			iw phy phy$i $@ >> $FILE
			i=$(($i+1))
		elif [ $? -eq 1 ]
		then
			break
			exit 0
		fi
	done
}

all()
{
	network
	rules
	state
}

#=====================================================The Actual Program================
$APPEND
$1
exit 0
