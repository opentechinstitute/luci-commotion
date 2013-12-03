#!/bin/sh

#simple barely functional nodogsplash uci-track script to set nodogsplash uci values that were set.

. /lib/functions/commotion.sh
. /lib/config/uci.sh

start() {
	#nodogsplash configuration file.
	local conffile=/etc/nodogsplash/nodogsplash.conf
	#disable/enable nodogsplash
	local enable=$(uci_get nodogsplash settings enable)
	if [ "$enable" == 1 ]; then #this might come back as a string and not as a intiger. Check and fix that.
		/etc/init.d/nodogsplash disable
	else
		/etc/init.d/nodogsplash enable
	fi
	
	#convert splash page time into minues
	local splash_time=$(uci_get nodogsplash settings splashtime)
	local splash_unit=$(uci_get nodogsplash settings splashunit)
	if [ "$splash_unit" == "days" ]; then
		splash_time=$(($splash_time*60))
	elif [ "$splash_unit" == "hours" ]; then
		splash_time=$(($splash_time*24*60))
	elif [ "$splash_unit" == "seconds" ]; then
		splash_time=$(($splash_time/60))
	fi
	#set splashpage time
	sed -i 's/^\(ClientIdleTimeout \).*/\1 $splash_time/' $conffile
	sed -i 's/^\(ClientForceTimeout \).*/\1 $splash_time/' $conffile
	#get and set interface name
	local interface=$(uci_get nodogsplash interfaces interface)
	local network=$(uci_get wireless $interface network)
	local iface_name=$(ubus call network.interface.$network status |grep \"device\" |awk '{print$2}'| sed 's/"\(\w*\)",/\1/')
	sed -i 's/^\(GatewayInterface \).*/\1 $iface_name/' $conffile
}
