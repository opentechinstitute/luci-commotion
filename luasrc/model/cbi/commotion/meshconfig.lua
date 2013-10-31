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
--
function log(msg)
if (type(msg) == "table") then
for key, val in pairs(msg) do            
log('{')                                                                                                                 
log(key)       
log(':')
log(val)          
log('}')      
end                            
else                             
luci.sys.exec("logger -t luci \"" .. tostring(msg) .. '"')
end                                    
end 
--
m = Map("wireless", translate("Configuration"), translate("This configuration wizard will assist you in setting up your router for a Commotion network."))

sctAP = m:section(NamedSection, "quickstartAP", "wifi-iface", translate("Access Point"))
sctAP.optional = true
sctAP:option(Value, "ssid", translate("Name (SSID)"), translate("The public facing name of this interface"))

sctSecAP = m:section(NamedSection, "quickstartSec", "wifi-iface", translate("Secure Access Point"))
sctSecAP.optional = true
sctSecAP:option(Value, "ssid", translate("Name (SSID)"), translate("The public facing name of this interface"))

sctMesh = m:section(NamedSection, "quickstartMesh", "wifi-iface", translate("Mesh Backhaul"))
sctMesh.optional = true
sctMesh:option(Value, "ssid", translate("Name (SSID)"), translate("The public facing name of this interface"))
sctMesh:option(Value, "bssid", translate("Device Designation (BSSID)"), translate("The device read name of this interface. (Letters A-F, and numbers 0-9 only)")) 

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

-- TASK: Add option to manual mesh config to change DNS server
m3 = Map("network")
s_namesrv = m3:section(TypedSection, "_dummy", translate("DNS Servers"),
   translate("Override nameservers defined in Commotion profiles"))
s_namesrv.optional = true

-- Check /etc/config/network for existing overrides
local placeholder = {}
uci:foreach("network","interface",
   function(interface)
      if interface["dns"] then 
         log('interface["dns"] == ')
         for d in tostring(interface['dns']) do log(d) 
         end
      end
      if interface["proto"] == "comotion" and interface.dns then
         log("interface.dns == ")
         log(interface.dns)
         placeholder = placeholder .. " " .. tostring(interface["dns"])
      end
   end
)
o_dns = s_namesrv:option(Value, "dns", "",
	translate("Separate hostnames or IP addresses with spaces"))
o_dns.placeholder = placeholder
log("o_dns.placeholder == ")
log(placeholder)
o_dns.rmempty = true

function s_namesrv.cfgsections()
   return { "_dns" }
end


--[[m3.on_parse(Map)
   local placeholder={}                                                                       
   uci.foreach("network", "interface", "dns")
      function(interface)                                                                                   
         if interface.dns then
            placeholder = placeholder .. " " .. interface.dns                                      
         end            
      end                                                                                                      
   )
end]]--

--[[m3_on_commit = function(
   uci.foreach("network", "interface")
      function(interface)
         if interface.proto == "commotion" then
            uci.set("network", "interface", "dns", o_dns)
	    uci.commit
         end
      end
)]]--

--https://forum.openwrt.org/viewtopic.php?pid=95297#p95297
-- check network for profiles
-- e.g., network.plug.profile=defaultPlug
--[[
network.loopback=interface
network.loopback.ifname=lo
network.loopback.proto=static
network.loopback.ipaddr=127.0.0.1
network.loopback.netmask=255.0.0.0
network.plug=interface
network.plug.ifname=eth0
network.plug.proto=commotion
network.plug.profile=defaultPlug
network.@alias[0]=alias
network.@alias[0].interface=plug
network.@alias[0].proto=static
network.@alias[0].ipaddr=192.168.1.20
network.@alias[0].netmask=255.255.255.0
network.mesh=interface
network.mesh.profile=quickstartMesh
network.mesh.proto=commotion
network.mesh.dns=8.8.8.8
network.secAp=interface
network.secAp.profile=quickstartSec
network.secAp.proto=commotion
network={loopback={"interface", ["ifname"] = "lo", ["proto"] = "static", ["ipaddr"] = "127.0.0.1", ["netmask"] = "255.0.0.0"}, plug={"interface", ["ifname"] = "eth0", ["proto"] = "commotion", ["profile"] = "defaultPlug"}}
]]--

m2 = Map("commotiond")                                                                                                                         
node = m2:section(TypedSection, "node", translate("Settings specific to this node"))
node.anonymous = true
node.optional = true
node:option(Value, "dhcp_timeout", translate("DHCP Timeout"), translate("How many seconds to wait on boot for a DHCP lease from the gateway"))

return m, m3, m2
