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

--[[

droption text: Internet Gateway
dropdown box: gateway configurations allowed (need list of types for ui text review)
option title: Advertise
checkbox
option help text: Advertise your gateway to the mesh network.

]]--

return m
