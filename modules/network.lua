--! @file network

local utils = require "luci.util"
local sys = require "luci.sys"
local uci = require "luci.model.uci"
local string, table, tostring = string, table, tostring

module "luci.commotion.network"

local network = {}

--! @name list_ifaces
--! @brief iterates over all zones in the network uci config and then uses ubus to gather network interfaces that use that zone.
--! @return an array with matched zone names and interface names. Arrays are mirrors of each other with one keyed by interface names and another keyed by zone name.
function network.list_ifaces()
  local r = {zone_to_iface = {}, iface_to_zone = {}}
  cursor = uci.cursor()
  cursor:foreach("network", "interface",
    function(zone)
      if zone['.name'] == 'loopback' then return end
      local iface = sys.exec("ubus call network.interface." .. zone['.name'] .. " status |grep '\"device\"' | cut -d '\"' -f 4"):gsub("%s$","")
      r.zone_to_iface[zone['.name']]=iface
      r.iface_to_zone[iface]=zone['.name']
    end
  )
  return r
end


--! @name get_channels
--! @brief Takes a radio's mode and returns the channel list or just the frequency with optional short flag.
--! @return a table with channel number and a string describing it for full.
--! @returns the frequency name if short flag is passed.
function network.get_channels(mode, short)
   local five_ghz = {"11a", "11adt", '11na'}
   if utils.contains(five_ghz, hwm) then
	  freq = "5GHz"
   else
	  freq = "2.4GHz"
   end
   if short then return freq end
   if freq == "5GHz" then
	  return {{36, "Channel 36 (5.180 GHz)"},
			  {40, "Channel 40 (5.200 GHz)"},
			  {44, "Channel 44 (5.220 GHz)"},
			  {48, "Channel 48 (5.240 GHz)"},
			  {149, "Channel 149 (5.745 GHz)"},
			  {153, "Channel 153 (5.765 GHz)"},
			  {157, "Channel 157 (5.785 GHz)"},
			  {161, "Channel 161 (5.805 GHz)"},
			  {165, "Channel 165 (5.825 GHz)"}}
   else
	  if freq == "2.4GHz" then
		 local set = {}
		 for i=1, 11, 1 do
			table.insert(set, {i, "Channel " .. i .. " (" .. tostring(2.407+(i*0.005)) .. " GHz)"})
		 end
		 return set
	  end
   end
end



return network

