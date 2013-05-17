--[[
LuCI - Lua Configuration Interface

Copyright 2011 Josh King <joshking at newamerica dot net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"
local util = require "luci.util"


m = Map("wireless", translate("Configuration"), translate("This configuration wizard will assist you in setting up your router " ..
	"for a Commotion network."))

sctAP = m:section(NamedSection, "quickstartAP", "wifi-iface", "Access Point")
sctAP.optional = true
sctAP:option(Value, "ssid", "Name (SSID)", "The public facing name of this interface")

sctSecAP = m:section(NamedSection, "quickstartSec", "wifi-iface", "Secure Access Point")
sctSecAP.optional = true
sctSecAP:option(Value, "ssid", "Name (SSID)", "The public facing name of this interface")

sctMesh = m:section(NamedSection, "quickstartMesh", "wifi-iface", "Mesh Backhaul")
sctMesh.optional = true
sctMesh:option(Value, "ssid", "Name (SSID)", "The public facing name of this interface")
sctMesh:option(Value, "bssid", "Device Designation (BSSID)", "The device read name of this interface. (Letters A-F, and numbers 0-9 only)") 

e = m:section(TypedSection, "wifi-device", translate("Network-wide Settings"))
e.anonymous = true

protocol = uci.get("wireless", "wifi-device", "hwmode")

if protocol == '11na' then
   c = e:option(ListValue, "channel", translate("5GHz Channel"), translate("The 5GHz backhaul channel of the mesh network, if applicable."))
   c:value(36, "Channel 36 (5.180 GHz)")
   c:value(40, "Channel 40 (5.200 GHz)")
   c:value(44, "Channel 44 (5.220 GHz)")
   c:value(48, "Channel 48 (5.240 GHz)")
   c:value(149, "Channel 149 (5.745 GHz)")
   c:value(153, "Channel 153 (5.765 GHz)")
   c:value(157, "Channel 157 (5.785 GHz)")
   c:value(161, "Channel 161 (5.805 GHz)")
   c:value(165, "Channel 165 (5.825 GHz)")
else
   c = e:option(ListValue, "channel", translate("2GHz Channel"), translate("The 2.4GHz backhaul channel of the mesh network, if applicable"))
   for i=1, 11 do
	  c:value(i, "Channel " .. i .. " (" .. tostring(2.407+(i*0.005)) .. " GHz)")
   end
end

return m