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

m = Map("network", translate("Internet Gateway"), translate("If desired, you can configure your gateway interface  here."))

p = m:section(NamedSection, "plug")
p.anonymous = true

advtz = p:option(Flag, "advertised", translate("Advertise your gateway to the mesh."))
advtz.default = "true"
advtz.enabled = "true"
advtz.disabled = "false"

advtz = p:option(Flag, "meshing", translate("Will you be meshing with other Commotion devices over the ethernet interface?"))
advtz.default = "true"
advtz.enabled = "true"
advtz.disabled = "false"

config = p:option(ListValue, "configuration", translate("Gateway Configurations"))
config:value("auto", "Automatically configure gateway on boot.")
config:value("client", "We have an upstream device that provides DHCP leases")
config:value("host", "This device should provide DHCP leases to clients.")








--[[

droption text: Internet Gateway
dropdown box: gateway configurations allowed (need list of types for ui text review)
option title: Advertise
checkbox
option help text: Advertise your gateway to the mesh network.

]]--

return m
