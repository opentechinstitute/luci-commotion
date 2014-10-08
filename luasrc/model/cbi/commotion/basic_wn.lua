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

local m = Map("wireless", translate("Wireless Network"), translate("Turning on an Access Point provides a wireless network for people to connect to using a laptop or other wireless devices."))

--redirect on saved and changed to check changes.
if not SW.status() then
   m.on_after_save = ccbi.conf_page
end

s = m:section(TypedSection, "wifi-iface", translate("Access Point"), translate("Turning on an Access Point provides a wireless network for people to connect to using a laptop or other wireless devices."))
s.optional = false
s.anonymous = true
 --if not setup wizard then allow for adding and removal and default addition
if not SW.status() then
   s.addremove = true

   md = s:option(Value, "mode")
   md.default = 'ap'
   md.render = function() end
   md.parse = function(self, section, novld)
	  if self:cfgvalue(section) ~= md.default then
		 return self.map:set(section, self.option, value)
	  end
   end
   
   nwk = s:option(Value, "network")
   nwk.default = "lan"
   nwk.render = function() end
   nwk.parse = function(self, section, novld)
	  if self:cfgvalue(section) ~= nwk.default then
		 return self.map:set(section, self.option, value)
	  end
   end
   function s.remove(self, section)
	  m.changed = true
	  return self.map:del(section)
   end
end

function s:filter(section)
   mode = self.map:get(section, "mode")
   return mode == "ap" or mode == nil
end

s.valuefooter = "cbi/full_valuefooter"
s.template_addremove = "cbi/commotion/addAP" --This template controls the addremove form for adding a new access point so that it has better wording.

name = s:option(Value, "ssid", translate("Name"), translate("The access point name (SSID) is the name that people will look for when connecting to this device."))
name.default = "CommotionWireless"
name.datatype = "maxlength(32)"
name.rmempty = false
function name:validate(val)
   if val and validate.ap_ssid(val) then
	   return val
   end
   return nil,"Invalid access point name; must be between 1 and 32 characters"
end

local wifi_dev = {}
uci.foreach("wireless", "wifi-device",
			function(s)
			   local name = s[".name"]
			   local mode = s.hwmode
			   table.insert(wifi_dev, {name, mode})
			end
)

--Check for more than one radio, and if not don't offer to change radio's.
if #wifi_dev > 1 then
   radios = s:option(ListValue, "device",  translate("wifi-device"), translate("Select the wireless network interface to use for your access point."))
   for _,dev in ipairs(wifi_dev) do
	  local freq = cnw.get_channels(dev[2], true)
	  radios:value(dev[1], dev[1].." "..freq)
	  local channels = s:option(ListValue, "channel_"..dev[1], translate("Channel"), translate("The channel of this wireless interface."))
	  channels:depends("device", dev[1])
	  --adds the values to the list based on frequency
	  for _,x in pairs((cnw.get_channels(dev[2]))) do
		 channels:value(x[1], x[2])
	  end
	  channels.default = uci:get("wireless", dev[1], "channel")
	  function channels.write(self, section, value)
		 local enable = self.map:set(dev[1], "disabled", "0") -- enable the radio
		 return self.map:set(dev[1], "channel", value)
	  end
   end
else

   local channels = s:option(ListValue, "channel", translate("Channel"), translate("The channel of your wireless interface."))
   channels.default = uci:get("wireless", wifi_dev[1][1], "channel")
   function channels.write(self, section, value)
	  local enable = self.map:set(wifi_dev[1][1], "disabled", "0") -- enable the radio
	  self.map:set(section, "device", wifi_dev[1][1]) --set iface to use this device.
	  return self.map:set(wifi_dev[1][1], "channel", value)
   end
   for _,x in pairs(cnw.get_channels(wifi_dev[1][2])) do
	  channels:value(x[1], x[2])
   end
end

enc = s:option(Flag, "encryption", translate("Require a Password?"), translate("When people connect to this access point, should a password be required?"))
enc.disabled = "none"
enc.enabled = "psk2"
enc.rmempty = false
enc.default = "none" --default must == disabled value for rmempty to work

enc.write=ccbi.flag_write
--Have enc flag also remove the encryption key when deleted and mark as changed.
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
pw1 = s:option(Value, "_pw1", translate("Password"), translate("Enter the password people should use to connect to this access point. Commotion uses WPA2 security for Access Point passwords."))
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
