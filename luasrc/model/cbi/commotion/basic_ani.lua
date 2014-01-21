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
local ip = require "luci.ip"

m = Map("network", translate("Internet Gateway"), translate("If desired, you can configure your gateway interface  here."))

--redirect on saved and changed to check changes.
if not SW.status() then
   m.on_after_save = ccbi.conf_page
end

p = m:section(NamedSection, "wired")
p.anonymous = true

msh = p:option(Flag, "meshed", translate("Will you be meshing with other Commotion devices over the ethernet interface?"))
msh.enabled = "true"
msh.disabled = "false"
msh.default = "false"
msh.addremove = false
msh.write = ccbi.flag_write

function msh:remove(self, section)
   value = self.map:get(section, self.option)
   if value ~= self.disabled then
	  self.section.changed = true
	  return self.map:set(section, self.option, 'false')
   end
end

ipaddress = p:option(TextValue, "ipaddr", translate("IP-Address"), translate(""))
ipaddress:depends("meshed", "true")
ipaddress.datatype = "ipaddr"
function ipaddress:validate(val)
   if val then
	  if ip.IPv4(val) or ip.IPv6(val) then
		 return val
	  else
		 return nil
	  end
   end
   return nil
end

netmask = p:option(TextValue, "netmask", translate("Net-Mask"), translate(""))
netmask:depends("meshed", "true")
netmask.datatype = "ipaddr"
function netmask:validate(val)
   if val then
	  if ip.IPv4(val) or ip.IPv6(val) then
		 return val
	  else
		 return nil
	  end
   end
   return nil
end

config = p:option(ListValue, "dhcp", translate("Gateway Configuration"))
config:value("auto", translate("Automatically configure gateway on boot."))
config:value("client", translate("This device should ALWAYS try and acquire a DHCP lease."))
config:value("server", translate("This device should ALWAYS provide DHCP leases to clients."))
config:value("none", translate("This device should not do anything with DHCP."))
config:depends("meshed", "") --CBI checks on flags check for the self.enabled value if true and and empty string if false. This only applies to flags. So, you know.... don't think this will work other places.
function config:remove(section, value)
	return self.map:set(section, self.option, "none")
end


ance = p:option(Flag, "_gateway", translate("Advertise your gateway to the mesh."))
ance.addremove = true

function dyn_exists()
   local cvalue = nil
   uci:foreach("olsrd", "LoadPlugin",
			   function(p)
				  if string.match(p.library, "^olsrd_dyn_gw_plain.*") then
					 cvalue = p[".name"]
				  end
			   end
   )
   return cvalue
end
	  
function ance.cfgvalue(self, section)
   if dyn_exists() ~= nil then
	  return '1'
   else
	  return '0'
   end
end

function ance.write(self, section, fvalue)
   if dyn_exists() == nil then
	  self.section.changed = true
	  --! @TODO Make this actually check the installed version and not just use 0.4.
	  uci:section("olsrd", "LoadPlugin", nil, {library="olsrd_dyn_gw_plain.so.0.4"})
	  uci:save("olsrd")
	  return true
   end
end

function ance.remove(self, section)
   local cvalue = dyn_exists()
   if cvalue ~= nil  then
	  self.section.changed = true
	  uci:delete("olsrd", cvalue)
	  uci:save("olsrd")
	  return true
   end
end


return m
