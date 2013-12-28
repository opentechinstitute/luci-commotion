--! @file network

local utils = require "luci.util"
local sys = require "luci.sys"
local uci = require "luci.model.uci"
local ubus = require "ubus"
local dt = require "luci.cbi.datatypes"
local db = require "luci.commotion.debugger"

local string, table, tostring, pairs, require = string, table, tostring, pairs, require
local print = print
module "luci.commotion.network"

local network = {}

--! @name replacements
--! @brief A list of uci to commotiond values that correspond
local replacements = {key="wpakey", encryption="wpa"}

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
--! @return a table containing the output of the commotiond call
function network.commotiond(cmd, err)
   db.log("commotiond")
   db.log(cmd)
   db.log(err)
   local json = require "luci.json"
   if err then
	  return sys.call("commotion "..cmd)
   else
	  json_obj =  sys.exec("commotion "..cmd)
	  db.log("commotion returns "..tostring(json_obj))
	  return json.decode(json_obj)
   end
end


--! @name check_channel
--! @brief  checks if a channel is appropriate 
local function check_channel(x)
   db.log("channels")
   db.log(x)
   local channels = {1,2,3,4,5,6,7,8,9,10,11,36,40,44,48,149,153,157,161,165}
   if util.table.contains(channels, x) then
	  return true
   end
end

local val_check = {
   bssid=dt.macaddr,
   channel=check_channel,
   ip=dt.ipaddr,
   wpakey=dt.wpakey,
}

--! @name c_check
--! @brief a function that does value and error checking and option replacement 
--! param op string: the option name 
--! param val string: the value associated with an option
--! @return option and value or nil if the value is incorrectly formatted.
function network.c_check(option, value)
   db.log("ccheck")
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
   db.log("cerr")
   db.log(set)
   db.log(key)
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
   db.log("network commotion set")
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
--! param name string name of profile
--! param options table options in key/value pairs {option="value", option2="value2"}
--! @return boolean value stating success or failure and errors if any on failure
function network.nodeid(new_id)
   db.log("nodeid")
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

