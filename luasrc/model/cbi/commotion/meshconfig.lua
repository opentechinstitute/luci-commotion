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
   c:value(36, "36 (5 GHz)")
   c:value(40, "40 (5 GHz)")
   c:value(44, "44 (5 GHz)")
   c:value(48, "48 (5 GHz)")
   c:value(149, "149 (5 GHz)")
   c:value(153, "153 (5 GHz)")
   c:value(157, "157 (5 GHz)")
   c:value(161, "161 (5 GHz)")
   c:value(165, "165 (5 GHz)")
else
   c = e:option(ListValue, "channel", translate("2GHz Channel"), translate("The 2.4GHz backhaul channel of the mesh network, if applicable"))
   for i=1, 11 do
	  c:value(i, i .. " (2.4 GHz)")
   end
end

m2 = Map("system")
o = m2:section(TypedSection, "system", translate("Settings specific to this node"))
o.anonymous = true

location = o:option(Value, "location", translate("Location"), translate("Human-readable location, optionally used to generate hostname/SSID. No spaces or underscores."))
location.datatype = "hostname"
homepage = o:option(Value, "homepage", translate("Homepage"), translate("Homepage for this node or network, used in the splash screen."))
-- homepage.datatype = "host"
--[[
LatLon and OpenStreetMap implementation borrowed from Freifunk.
]]--
lat = o:option(Value, "latitude", translate("Latitude"), translate("e.g.") .. " 40.11143")
lat.datatype = "float"

lon = o:option(Value, "longitude", translate("Longitude"), translate("e.g.") .. " -88.20723")
lon.datatype = "float"

--[[
Opens an OpenStreetMap iframe or popup
Makes use of resources/OSMLatLon.htm and htdocs/resources/osm.js
]]--

local class = util.class

local deflat = uci:get_first("system", "system", "latitude") or 40
local deflon = uci:get_first("system", "system", "longitude") or -88
local zoom = 12
if ( deflat == 40 and deflon == -88 ) then
	zoom = 4
end

OpenStreetMapLonLat = luci.util.class(AbstractValue)
    
function OpenStreetMapLonLat.__init__(self, ...)
	AbstractValue.__init__(self, ...)
	self.template = "cbi/osmll_value"
	self.latfield = nil
	self.lonfield = nil
	self.centerlat = ""
	self.centerlon = ""
	self.zoom = "0"
	self.width = "100%" --popups will ignore the %-symbol, "100%" is interpreted as "100"
	self.height = "600"
	self.popup = false
	self.displaytext="OpenStreetMap" --text on button, that loads and displays the OSMap
	self.hidetext="X" -- text on button, that hides OSMap
end

	osm = o:option(OpenStreetMapLonLat, "latlon", translate("Find your coordinates with OpenStreetMap"), translate("Select your location with a mouse click on the map. The map will only show up if you are connected to the Internet."))
	osm.latfield = "latitude"
	osm.lonfield = "longitude"
	osm.centerlat = uci:get_first("system", "system", "latitude") or deflat
	osm.centerlon = uci:get_first("system", "system", "longitude") or deflon
	osm.zoom = zoom
	osm.width = "100%"
	osm.height = "600"
	osm.popup = false
	osm.displaytext=translate("Show OpenStreetMap")
	osm.hidetext=translate("Hide OpenStreetMap")

return m, m2
