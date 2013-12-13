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
local cdisp = require "luci.commotion.dispatch"

m = Map("network", translate("Internet Gateway"), translate("If desired, you can configure your gateway interface  here."))

--redirect on saved and changed to check changes.
if not SW.status() then
   m.on_after_save = cdisp.conf_page
end

p = m:section(NamedSection, "plug")
p.anonymous = true

msh = p:option(Flag, "meshability", translate("Will you be meshing with other Commotion devices over the ethernet interface?"))
msh.enabled = "true"
msh.disabled = "false"
msh.default = "false"
msh.addremove = true

ance = p:option(Flag, "announceability", translate("Advertise your gateway to the mesh."))
ance.enabled = "true"
ance.disabled = "false"
ance.addremove = true
--ance:depends("meshability", "false") --!TODO Currently Flags do not have dependance capabilities it seems. I will add and patch in R1.1

config = p:option(ListValue, "plugability", translate("Gateway Configuration"))
config:value("auto", translate("Automatically configure gateway on boot."))
config:value("client", translate("This device should try and acquire a DHCP lease"))
config:value("host", translate("This device should provide DHCP leases to clients."))

return m
