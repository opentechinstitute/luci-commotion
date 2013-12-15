--! @file network

local utils = require "luci.util"
local sys = require "luci.sys"
local uci = require "luci.model.uci"
local ubus = require "ubus"

local string, table, tostring, pairs = string, table, tostring, pairs
local print = print
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
   if utils.contains(five_ghz, mode) then
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

--! @name commotiond
--! @brief a local function which currently calls the commotiond command line function. This will hopfully be replaces with lua/c bindings later.
--! param cmd string The command to append to commotiond
--! param err bool true if you want to receive the error code nil if you wan the standard output
--! @return the standard out of the commotiond call
function network.commotiond(cmd, err)
   if err then
	  return sys.call("commotiond "..cmd)
   else
	  return sys.exec("commotiond "..cmd)
   end
end


--! @name commotion_set
--! @brief finds, or creates a commotion profile and sets values
--! param name string name of profile
--! param options table options in key/value pairs {option="value", option2="value2"}
--! @return boolean value stating success or failure and errors if any on failure
function network.commotion_set(name, options)
   return true --! TODO ALERT this renders this function useless until commotiond functionality is enabled.
--[[   local function setop(opts, err, pr)
	  for i,x in pairs(opts) do
		 if not network.commotiond("set "..pr.." "..i.." "..x, true) then
			table.insert(err, {i,x})
		 end
	  end
	  return err
   end
   local profiles = network.commotiond("profiles", true)
   local profile = nil
   local errors = {}
   for _,prof in ipairs(prof) do
	  if prof == name then
		 profile = name
	  end
   end
   if profile then
	  errors = setop(options, errors, profile)
   else
	  local create = network.commotiond(name, true)
	  if create then
		 errors = setop(options, errors, name)
	  else
		 table.insert(errors, {"profile", "created"}
	  end
   end
   if errors then
	  return nil, errors
   else
	  return true
   end
   return true]]--
end

--! @name nodeid
--! @brief finds, or creates the nodeid 
--! param name string name of profile
--! param options table options in key/value pairs {option="value", option2="value2"}
--! @return boolean value stating success or failure and errors if any on failure
function network.nodeid(new_id)
   return "abcdefghijklmnopqrstuvwxyznowiknowmyabcs"
   --! TODO ALERT this renders this function useless until commotiond functionality is enabled.
--[[   if new_id then
	  return network.commotiond("nodeid "..new_id, true)
   else
	  return network.commotiond("nodeid")
   end	  ]]--
end

--[[

Commotiond commands to add functionality for
   
up <iface> <profile> -same as before
down <iface> -same as before
status <iface> -same as before
state <iface> <property> -same as before
profiles -replaces list_profiles
set <profile> <property> <value> -allows you to set profile values
get <profile> <property> <value> -allows you to get profile values
save <profile> <file> -allows you to save a profile to a new file in the
profiles.d directory
new <profile> -allows you to create a new profile
delete <profile> -allows you to delete a profile
ipgen <ip address> <netmask> -allows you to generate an arbitrary IP
address from the nodeid
nodeid <id> -run without arguments, prints the nodeid. Can also set the
nodeid.
]]--

--[[
   And here's the new config file:
{
  "ssid": "commotionwireless.net",
  "bssid": "02:CA:FF:EE:BA:BE",
  "bssidgen": "true"
  "channel": "5",
  "type": "mesh",
  "dns": "8.8.8.8",
  "domain": "mesh.local",
  "ipgen": "true",
  "ipgenmask": "255.0.0.0",
  "mode": "adhoc",
  "ip": 100.64.0.0,
  "netmask": "255.192.0.0",
  "wpa": "true",
  "wpakey": "c0MM0t10n!r0cks",
  "servald": "false",
  "servalsid": "",
  "announce": "true"
}
]]--


--! @name list_ifaces
--! @brief iterates over all zones in the network uci config and then uses ubus to gather network interfaces that use that zone.
--! @param swap optional to return a swapped array of with interfaces from ubus as keys and zones from uci as values
--! @return an array with matched zone names and interface names. By default the array is keyed by the zones pulled from /etc/config/network interface section names.
function network.ifaces_list(swap)
   local z2if = {}
   local conn = ubus.connect()
   if not conn then
	  error("Failed to connect to ubusd")
   end
   cursor = uci.cursor()
   cursor:foreach("network", "interface",
				  function(zone)
					 local iface = conn:call("network.interface."..zone['.name'], "status", {})
					 if iface.device ~= nil then
						dev = tostring(iface.device)
						if swap and dev then
						   r.z2if[dev]=zone['.name']
						else
						   r.z2if[zone['.name']]=dev
						end
					 end
   )
   return r
end

return network

