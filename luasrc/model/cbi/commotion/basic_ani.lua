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
local QS = require "luci.commotion.quickstart"


m = Map("wireless", translate("Additional Network Interfaces"), translate("Commotion's Setup Wizard has detected additional un-configured network interfaces on this device. If desired, you can configure them here."))

local used_radio = {}
local unused_dev = {}

uci.foreach("wireless", "wifi-iface",
			function(s)
			   local dev = s.device
			   table.insert(used_radio, dev)
			end
)
uci.foreach("wireless", "wifi-device",
			function(s)
			   if not utils.contains(used_radio, s[".name"]) then
				  table.insert(unused_dev, s[".name"])
			   end
			end
)

if #unused_dev > 0 then
   s = m:section(TypedSection, "wifi-iface")
   s.addremove = true
   s.optional = false
   s.anonymous = true
   
   function s:filter(section)
	  local dev = self.map:get(section, "device")
	  return not utils.contains(used_radio, dev)
   end
   
   mode = s:option(ListValue, "mode", translate("mode"), translate("Will this interface be a Mesh Network or a Access Point?"))
   mode:value("ap", "Access Point")
   mode:value("adhoc", "Mesh Network")
   
   function mode.write(self, section, value)
	  ListValue.write(self, section, value) --Call original function
	  if value == "adhoc" then
		 if QS.status() then
			cnw.commotion_set("NAME HERE", {values="mapvalues here"}) --TODO make commotion set actually work
		 end
	  else
		 self.map:set(section, "network", "client")
	  end
   end
   
   s.valuefooter = "cbi/full_valuefooter"
   s.template_addremove = "cbi/commotion/addAdditional" --This template controls the addremove form for adding a new access point so that it has better wording.
   
   name = s:option(Value, "ssid",  translate("Interface Name"), translate(""))
   
   local wifi_dev = {}
   uci.foreach("wireless", "wifi-device",
			   function(s)
				  if not utils.contains(used_radio, s[".name"]) then
					 local name = s[".name"]
					 local mode = s.hwmode
					 table.insert(wifi_dev, {name, mode})
				  end
			   end
   )
   --Check for more than one radio, and if not don't offer to change radio's.
   if #wifi_dev > 1 then
	  radios = s:option(ListValue, "device",  translate("wifi-device"), translate("The Setup Wizard has detected all of the network interfaces on this device. Select the network interface to use."))
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
		 function channels:write(section, value)
			return self.map:set(dev[1], "channel", value)
		 end
	  end
   else
	  local channels = s:option(ListValue, "channel", translate("Channel"), translate("The channel of your wireless interface."))
	  channels.default = uci:get("wireless", wifi_dev[1][1], "channel")
	  function channels.write(self, section, value)
		 return self.map:set(wifi_dev[1][1], "channel", value)
	  end
	  for _,x in pairs(cnw.get_channels(wifi_dev[1][2])) do
		 channels:value(x[1], x[2])
	  end
   end
   
   enc = s:option(Flag, "encryption", translate("Encryption"), translate("When connecting to this interface, should a password be required?"))
   enc.disabled = "none"
   enc.enabled = "psk2"
   enc.rmempty = true
   enc.default = "none" --default must == disabled value for rmempty to work
   
   --Have enc flag also remove the encryption key when deleted
   function enc.remove(self, section)
	  local key = self.map:del(section, "key")
	  local enc = self.map:del(section, self.option)
	  return key and enc or false
   end
   
   --dummy value set to not reveal password
   pw1 = s:option(Value, "_pw1", translate("Mesh Encryption Password"), translate("Enter the password people should use to connect to this interface. Commotion uses WPA2 security for interface passwords."))
   pw1.password = true
   pw1:depends("encryption", "psk2")
   
   --password should write to the key, not to the dummy value
   function pw1.write(self, section, value)
	  return self.map:set(section, "key", value)
   end
   
   pw2 = s:option(Value, "_dummy")
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
	  if v1 and v2 and #v1 > 0 and #v2 > 0 then
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
		 self:add_error(section, translate("Unknown Error, password not changed!"))
		 return nil
	  end
   end
end
--Default radio (don't render this. Just add it so that it gets added to UCI when created)
radio = s:option(DummyValue, "device")
radio.default = wifi_dev[1][1]
radio.render = function() end

--[[

droption text: Internet Gateway
dropdown box: gateway configurations allowed (need list of types for ui text review)
option title: Advertise
checkbox
option help text: Advertise your gateway to the mesh network.

]]--

return m
