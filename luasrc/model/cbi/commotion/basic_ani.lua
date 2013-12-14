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

m = Map("network", translate("Internet Gateway"), translate("If desired, you can configure your gateway interface  here."))

--redirect on saved and changed to check changes.
if not SW.status() then
   m.on_after_save = ccbi.conf_page
end

p = m:section(NamedSection, "plug")
p.anonymous = true

config = p:option(ListValue, "dhcp", translate("Gateway Configuration"))
config:value("auto", translate("Automatically configure gateway on boot."))
config:value("client", translate("This device should ALWAYS try and acquire a DHCP lease."))
config:value("server", translate("This device should ALWAYS provide DHCP leases to clients."))
config:value("none", translate("This device should not do anything with DHCP."))

msh = p:option(Flag, "meshed", translate("Will you be meshing with other Commotion devices over the ethernet interface?"))
msh.enabled = "true"
msh.disabled = "false"
msh.default = "false"
msh.addremove = false

ance = p:option(Flag, "announced", translate("Advertise your gateway to the mesh."))
ance.enabled = "true"
ance.disabled = "false"
ance.addremove = false
ance.default = 'true'
   
return m
