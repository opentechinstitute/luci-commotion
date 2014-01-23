--! @file network

local utils = require "luci.util"
local sys = require "luci.sys"
local uci = require "luci.model.uci"
local ubus = require "ubus"
local dt = require "luci.cbi.datatypes"
local validate = require "luci.commotion.validate"

local string, table, tostring, pairs, require = string, table, tostring, pairs, require
local print = print
module "luci.commotion.network"

local network = {}

--! @name replacements
--! @brief A list of uci to commotiond values that correspond
local replacements = {key="wpakey", encryption="wpa"}

--! @name list_ifaces
--! @deprecated See replacement "network.ifaces_list()"
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
--! @param short Flag to have function only return string containing frequency
--! @param mode The radio's mode see hwmode in http://wiki.openwrt.org/doc/uci/wireless#common.options
--! @return a table keyed with this modes channel numbers and a string describing each channel.
--! @returns if short flag then only returns a string containing the frequency.
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
--! @brief a local function which currently calls the commotiond command line function.
--! @todo This will hopfully be replaced with lua/c bindings later.
--! @param cmd string The command to append to commotiond
--! @param err bool true if you want to receive the error code nil/false if you want the standard output
--! @return a table containing the output of the commotiond call
function network.commotiond(cmd, err)
   local json = require "luci.json"
   if err then
	  return sys.call("commotion "..cmd)
   else
	  json_obj =  sys.exec("commotion "..cmd)
	  return json.decode(json_obj)
   end
end

--! @name val_check
--! @brief table containing the values that have corresponding functions for validating input
--! @todo create a function for every commotiond input. It does not validate input strongly, so we need to do that on the front end.
local val_check = {
   bssid=dt.macaddr,
   channel=validate.channel,
   ip=dt.ipaddr,
   wpakey=validate.wireless_pw,
   ssid=validate.mesh_ssid
}

--! @name c_check
--! @brief a function that does value and error checking and option replacement 
--! param option string: the option name 
--! param value string: the value associated with an option
--! @return option and value or if the value is incorrectly formatted returns nil.
function network.c_check(option, value)
   if replacements.option then
	  option = replacements.option
   end
   if val_check.value then
	  if val_check.value(value) then
		 return option, value
	  else
		 return nil
	  end
   else
	  return option, value
   end
end

--! @name cerr
--! @brief a function that checks for error returns in a commotion set
--! param set a decoded data structure returned from commotiond
--! param key a key you would like to exstract from the set
--! @return false, and the error message if error or the value if not false.
function network.cerr(set, key)
   if set['error'] then
	  return false, set['error']
   else
	  return set[key]
   end
end

--! @name commotion_set
--! @brief finds, or creates a commotion profile and sets values
--! param name string name of profile
--! param options table options in key/value pairs {option="value", option2="value2"}
--! @return boolean value stating success or failure and errors if any on failure
function network.commotion_set(name, options)
   local errors = {}
   --! This function runs command and adds to the error table being created
   local function setop(opts, err, pr)
	  local op, val
	  for op,val in pairs(opts) do
		 op, val = network.c_check(op, val)
		 if op then
			local operation = network.commotiond("set "..pr.." "..op.." "..val)
			if operation.error then
			   table.insert(err, {op,operation.error})
			end
		 end
	  end
	  return err
   end
   local profiles = network.commotiond("profiles")
   local profile
   profile = utils.contains(profiles, name)
   if profile then
	  if options then
		 errors = setop(options, errors, profile)
	  end
   else
	  local create = network.commotiond("new "..name)
	  if not create.error then
		 if options then
			errors = setop(options, errors, name)
		 end
	  else
		 table.insert(errors, {"profile", create.error})
	  end
   end
   if errors[1] then
	  return false, errors
   else
	  local save = network.commotiond("save "..name)
	  return true
   end
end

--! @name nodeid
--! @brief finds, or creates the nodeid
--! @param new_id string name of profile
--! @return node id on success or failure and errors (if any) on failure
function network.nodeid(new_id)
   if new_id then
	  if #new_id <= 10  and new_id:match("^[0-9]+$") then
		 id_set = network.commotiond("nodeid "..new_id)
		 uci:set("commotion", "node", "nodeid", id_set['id'])
		 return network.cerr(id_set, 'id')
	  else
		 return false, "Node id must be less than 10 charicters and composed of only numbers."
	  end
   else
	  cur_id = network.commotiond("nodeid")
	  return network.cerr(cur_id, 'id')
   end
end

--! @name list_ifaces
--! @note this function is a replacement for "network.list_ifaces()" to reduce memory use calling the shell.
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
					 if iface and iface.device ~= nil then
						dev = tostring(iface.device)
						if swap and dev then
						   z2if[dev]=zone['.name']
						else
						   z2if[zone['.name']]=dev
						end
					 end
				  end)
   conn:close()
   return z2if
end

return network

