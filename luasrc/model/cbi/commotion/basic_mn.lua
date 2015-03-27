--[[
Copyright (C) 2013 Seamus Tuohy

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
]]--

local uci = require "luci.model.uci".cursor()
local utils = require "luci.util"
local cnw = require "luci.commotion.network"
local db = require "luci.commotion.debugger"
local http = require "luci.http"
local SW = require "luci.commotion.setup_wizard"
local ccbi = require "luci.commotion.ccbi"
local validate = require "luci.commotion.validate"
local encode = require "luci.commotion.encode"


local m = Map("wireless", translate("Network Settings"), translate("Every Commotion node must have one mesh network connection or interface. Commotion can mesh over wireless or wired interfaces."))

--redirect on saved and changed to check changes.
if not SW.status() then
   m.on_after_save = ccbi.conf_page
end

s = m:section(TypedSection, "wifi-iface")
s.optional = false
s.anonymous = true

if not SW.status() then --if not setup wizard then allow for adding and removal
   s.addremove = true

   md = s:option(Value, "mode")
   md.default = 'adhoc'
   md.render = function() end
   function md:parse(section)
	  local cvalue = self:cfgvalue(section)
	  if not cvalue then
		 self:write(section, self.default)
	  end
   end
   function s.remove(self, section)
	  m.changed = true
	  clean_network(name:formvalue(section))
	  return self.map:del(section)
   end
end


function s:filter(section)
   mode = self.map:get(section, "mode")
   return mode == "adhoc" or mode == nil
end

s.valuefooter = "cbi/full_valuefooter"
s.template_addremove = "cbi/commotion/addMesh" --This template controls the addremove form for adding a new access point so that it has better wording.

name = s:option(Value, "ssid",  translate("Mesh Network Name"), translate("Commotion networks share a network-wide name. This must be the same across all devices on the same mesh. This name cannot be greater than 31 characters."))
name.default = "commotionwireless.net"
name.datatype = "maxlength(31)"
name.rmempty = false
function name:validate(val)
   if val and validate.mesh_ssid(val) then
	  return val
   end
   return nil,"Invalid mesh network name; must be between 1 and 31 characters"
end

nwk = s:option(Value, "network")

--! @brief creates a network section and same named commotion profile when creating a mesh interface and assigns it to that mesh interface
function write_network(value)
   local net_name = encode.uci(value)
   network_name = uci:section("network", "interface", net_name, {proto="commotion", class='mesh'})
   cnw.commotion_set(network_name)
   uci:set("network", network_name, "profile", network_name)
   uci:save("network")
   if value ~= nil then
	  uci:foreach("firewall", "zone",
				  function(s)
					 if s.name and s.name == "mesh" then
						local list = {net_name}
						for _,x in ipairs(s.network) do
						   table.insert(list, x)
						end
						uci:set_list ("firewall", s[".name"], "network", list)
						uci:save("firewall")
					 end
				  end
	  )
	  return net_name
   end
end

function clean_network(value)
   local fs = require "luci.fs"
   local net_name = encode.uci(value)
   uci:delete("network", net_name)
   fs.unlink("/etc/commotion/profiles.d/"..net_name)
   uci:save("network")
   if value ~= nil then
	  uci:foreach("firewall", "zone",
				  function(s)
					 if s.name and s.name == "mesh" then
						local list = {}
						for _,x in ipairs(s.network) do
						   if x ~= net_name then
							  table.insert(list, x)
						   end
						end
						uci:set_list ("firewall", s[".name"], "network", list)
						uci:save("firewall")
					 end
				  end
	  )
	  return net_name
   end
end

function check_name(self, section, value)
   local uci = require "luci.model.uci".cursor()
   local clean_name = encode.uci(value)
   local exist = uci:get("network", clean_name)
   if exist ~= nil then
	  local current = self.map:get(section, "network")
	  if current == clean_name then
		 return true
	  else
		 m.message = "You cannot have multiple interfaces with the same name."
		 m.state = -1
		 name:add_error(section, nil, "This section is named the same as an existing interface.")
		 db.log("errors set because of existing network")
		 return nil
	  end
   else
	  return true
   end
end

nwk.render = function() end
function nwk:parse(section)
   db.log("parsing network")
   local cvalue = self:cfgvalue(section)
   local name = name:formvalue(section)
   if name ~= nil and name ~= '' and not cvalue then
	  if check_name(self, section, name) ~= nil then
		 local net_name = write_network(name)
		 uci:set("wireless", section, "network", net_name)
		 uci:save("wireless")
 	  else
		 db.log("failed to write the network.")
	  end
   else
	  db.log("Already set or a nil value.")
   end
end

local wifi_dev = {}
uci.foreach("wireless", "wifi-device",
  function(s)
    table.insert(wifi_dev, {name=s[".name"], mode=s.hwmode})
  end
)

--Check for more than one radio, and if not don't offer to change radio's.
if #wifi_dev > 1 then
  radios = s:option(ListValue, "device",  translate("wifi-device"), translate("The Setup Wizard has detected all of the network interfaces on this device. Select the network interface that will connect to the mesh."))
   for _,dev in ipairs(wifi_dev) do
          local iw = luci.sys.wifi.getiwinfo(dev.name)
	  local hw_modes = iw.hwmodelist or { }
	  local cl = iw and iw.countrylist
	  
	  if hw_modes.a and hw_modes.g then
	    radios:value(dev.name, dev.name.." 2.4GHz/5GHz")
	  elseif hw_modes.a then
	    radios:value(dev.name, dev.name.." 5GHz")
	  elseif hw_modes.g then
	    radios:value(dev.name, dev.name.." 2.4GHz")
	  else
	    radios:value(dev.name, dev.name)
	  end
	  
	  local channels = s:option(ListValue, "channel_"..dev.name, translate("Channel"), translate("The channel of this wireless interface."))
	  channels:depends("device", dev.name)
	  for _, f in ipairs(iw and iw.freqlist or { }) do
	    if not f.restricted then
	      channels:value(f.channel, "%i (%.3f GHz)" %{ f.channel, f.mhz / 1000 })
	    end
	  end
	  channels.default = uci:get("wireless", dev.name, "channel")
	  function channels.write(self, section, value)
	    local enable = self.map:set(dev.name, "disabled", "0") -- enable the radio
	    local set_chan = self.map:set(dev.name, "channel", value)
	    if hw_modes.n then
	      self.map:set(dev.name, "hwmode", tonumber(value) <= 14 and "11ng" or "11na")
	    else
	      self.map:set(dev.name, "hwmode", tonumber(value) <= 14 and "11g" or "11a")
	    end
	    return set_chan and enable or false
	  end
	  
	  local cc = s:option(ListValue, "country_"..dev.name, translate("Country Code"), translate("Use ISO/IEC 3166 alpha2 country codes."))
	  cc:depends("device", dev.name)
	  if cl and #cl > 0 then
		 cc.default = uci:get("wireless", dev.name, "country")
		 for _, c in ipairs(cl) do
		      cc:value(c.alpha2, "%s - %s" %{ c.alpha2, c.name })
		 end
	  else
		 s:option(Value, "country", translate("Country Code"), translate("Use ISO/IEC 3166 alpha2 country codes."))
	  end
	  function cc:write(section, value)
		 local set_cc = self.map:set(dev.name, "country", value)
		 return set_cc or false
	  end
   end
else
   local dev = wifi_dev[1]
   local iw = luci.sys.wifi.getiwinfo(dev.name)
   local hw_modes = iw.hwmodelist or { }
   local cl = iw and iw.countrylist
   
   local channels = s:option(ListValue, "channel", translate("Channel"), translate("The channel of your wireless interface."))
   channels.default = uci:get("wireless", dev.name, "channel")
   for _, f in ipairs(iw and iw.freqlist or { }) do
     if not f.restricted then
       channels:value(f.channel, "%i (%.3f GHz)" %{ f.channel, f.mhz / 1000 })
     end
   end
   function channels.write(self, section, value)
	  local enable = self.map:set(dev.name, "disabled", "0") -- enable the radio
	  self.map:set(section, "device", dev.name) --set iface to use this device.
	  if hw_modes.n then
	    self.map:set(dev.name, "hwmode", tonumber(value) <= 14 and "11ng" or "11na")
	  else
	    self.map:set(dev.name, "hwmode", tonumber(value) <= 14 and "11g" or "11a")
	  end
	  return self.map:set(dev.name, "channel", value)
   end
   
   if cl and #cl > 0 then
	  local cc = s:option(ListValue, "country", translate("Country Code"), translate("Use ISO/IEC 3166 alpha2 country codes."))
	  cc.default = uci:get("wireless", dev.name, "country")
	  function cc.write(self, section, value)
		return self.map:set(dev.name, "country", value)
	  end  
	  for _, c in ipairs(cl) do
                cc:value(c.alpha2, "%s - %s" %{ c.alpha2, c.name })
	  end
   else
          s:option(Value, "country", translate("Country Code"), translate("Use ISO/IEC 3166 alpha2 country codes."))
   end   
end

enc = s:option(Flag, "encryption", translate("Mesh Encryption"), translate("Choose whether or not to encrypt data sent between mesh devices for added security."))
enc.disabled = "none"
enc.enabled = "psk2"
enc.rmempty = false
enc.default = "none" --default must == disabled value for rmempty to work

enc.write = ccbi.flag_write
--Have enc flag also remove the encryption key when deleted
function enc.remove(self, section)
   value = self.map:get(section, self.option)
   if value ~= self.disabled then
	  local key = self.map:del(section, "key")
	  local enc = self.map:del(section, self.option)
	  self.section.changed = true
	  return key and enc or false
   end
end



--dummy value set to not reveal password
pw1 = s:option(Value, "_pw1", translate("Mesh Encryption Password"), translate("To encrypt data between devices, each device must share a common mesh encryption password."))
pw1.password = true
pw1:depends("encryption", "psk2")
pw1.datatype = "wpakey"

--password should write to the key, not to the dummy value
function pw1.write(self, section, value)
   return self.map:set(section, "key", value)
end

pw2 = s:option(Value, "_dummy", translate("Confirmation"))
pw2.password = true
pw2:depends("encryption", "psk2")

--Don't actually write this value, just return success
function pw2.write(self, section, value)
   return true
end

--make sure passwords are equal
function pw1.validate(self, value, section)
   local v1 = value
   local v2 = pw2:formvalue(section)
   --local v2 = http.formvalue(string.gsub(self:cbid(section), "%d$", "2"))
   if v1 and v2 and validate.wireless_pw(v1) and validate.wireless_pw(v2) then
	  if v1 == v2 then
		 if m.message == nil then
			m.message = translate("Password successfully changed!")
		 end
		 return value
	  else
		 m.message = translate("Error, no changes saved. See below.")
		 self:add_error(section, translate("Given password confirmation did not match, password not changed!"))
		 return nil
	  end
   else
	  m.message = translate("Error, no changes saved. See below.")
	  self:add_error(section, translate("Invalid password; must be 8 and 63 printable ASCII characters"))
	  return nil
   end
end

return m
