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

local m = Map("wireless", translate("Wireless Network"), translate("Turning on an Access Point provides a wireless network for people to connect to using a laptop or other wireless devices."))

function m.on_commit()
   if not uci:get("network", "commotionAP") then
	  uci:section("network", "interface", "commotionAP", {proto="commotion"})
	  uci:save("network")
	  uci:commit("network")
   end
end

s = m:section(TypedSection, "wifi-iface", translate("Access Point"), translate("Turning on an Access Point provides a wireless network for people to connect to using a laptop or other wireless devices."))
s.addremove = true
s.optional = false
s.template_addremove = "cbi/commotion/addAP" --This template controls the form for adding a new access point.

--Default Mode
mode = s:option(DummyValue, "mode")
mode.default = "ap"
mode.render = function() end

--Default Commotion AP Profile
ntwk = s:option(DummyValue, "network")
ntwk.default = "commotionAP"
ntwk.render = function() end

local wifi_dev = {}
uci.foreach("wireless", "wifi-device",
			function(s)
			   local name = s[".name"]
			   local mode = s.hwmode
			   table.insert(wifi_dev, {name, mode})
			end
)

local this_dev = nil
--Check for more than one radio, and if not don't offer to change radio's.
if #wifi_dev > 1 then
   radios = s:option(ListValue, "device",  translate("wifi-device"), translate("Wireless Interface"), translate("Select the wireless network interface to use for your access point."))
   for _,dev in pairs(wifi_dev) do
	  local freq = cnw.get_channels(dev[2], true)

	  radios:value(dev[1].." "..freq, {dev[1]})
	  
	  local channels = s:option(ListValue, "channel", translate("Channel"), translate("The channel of this wireless interface."))
	  channels.depends("radios", dev[1])
	  
	  --adds the values to the list based on frequency
	  for _,x in pairs((cnw.get_channels(dev[2]))) do
		 channels:value(x[1], x[2])
	  end
	  channels.default = uci:get("wireless", dev[1], "channel")
	  function channels.write(self, section, value)
		 return self.map:set(dev[1], "channel", value)
	  end
   end
else
   --Default radio
   radio = s:option(DummyValue, "device")
   radio.default = wifi_dev[1][1]
   radio.render = function() end

   local channels = s:option(ListValue, "channel", translate("Channel"), translate("The channel of your wireless interface."))
   channels.default = uci:get("wireless", wifi_dev[1][1], "channel")
   function channels.write(self, section, value)
	  return self.map:set(wifi_dev[1][1], "channel", value)
   end
   for _,x in pairs(cnw.get_channels(wifi_dev[1][2])) do
	  channels:value(x[1], x[2])
   end
end

enc = s:option(Flag, "encryption", translate("Require a Password?"), translate("When people connect to this access point, should a password be required?"))
enc.disabled = "none"
enc.enabled = "psk2"
enc.rmempty = true

function enc.remove(self, section) --TODO fix this so that when enc is removed the key is also removed.
   for i,x in pairs(enc) do db.log(tostring(i)..":"..tostring(x)) end
   local key = self.map:del(section, "key")
   local enc = self.map:del(section, self.option)
   return key and enc or false
end

pw1 = s:option(Value, "_pw1", translate("Password"), translate("Enter the password people should use to connect to this access point. Commotion uses WPA2 security for Access Point passwords."))
pw1.password = true
pw1:depends("encryption", "psk2")

function pw1.write(self, section, value)
   return self.map:set(section, "key", value)
end

pw2 = s:option(Value, "_dummy")
pw2.password = true
pw2:depends("encryption", "psk2")
function pw2.write(self, section, value)
   return true
end


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

return m
