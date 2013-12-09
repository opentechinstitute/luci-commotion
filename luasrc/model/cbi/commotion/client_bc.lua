--[[
Modifications Copyright (C) 2013 Seamus Tuohy 

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
--[[
LuCI - Lua Configuration Interface

Copyright 2009 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: p2pblock.lua 5448 2009-10-31 15:54:11Z jow $
]]--

local sys = require "luci.sys"
local cdisp = require "luci.commotion.dispatch"

m = Map("freifunk_p2pblock", translate("Bandwidth Controls"),
	translate("You can disable potentially high-bandwith applications here. "))

--redirect on saved and changed to check changes.
m.on_after_save = cdisp.conf_page

s = m:section(NamedSection, "p2pblock", "settings", "Settings")
s.anonymous = true
s.addremove = false

en = s:option(Flag, "_enabled", translate("Enable/Disable Bandwidth Controls"))
en.rmempty = false

function en.cfgvalue()
	return ( sys.init.enabled("freifunk-p2pblock") and "1" or "0" )
end

function en.write(self, section, val)
	if val == "1" then
		sys.init.enable("freifunk-p2pblock")
	else
		sys.init.disable("freifunk-p2pblock")
	end
end

--s:option(Value, "portrange", translate("Portrange"))

--s:option(Value, "blocktime", translate("Block Time"),
--	translate("seconds"))

--s:option(DynamicList, "whitelist", translate("Whitelisted IPs"))

l7 = s:option(MultiValue, "layer7", translate("Layer7-Protocols"))
l7.widget = "checkbox"
l7:value("aim", "AIM Chat")
l7:value("bittorrent", "Bittorrent")
l7:value("edonkey", "eDonkey, eMule, Kademlia")
l7:value("fasttrack", "Fasttrack Protocol")
l7:value("ftp", "File Transfer Protocol")
l7:value("gnutella", "Gnutella")
l7:value("http", "Hypertext Transfer Protocol")
l7:value("ident", "Ident Protocol")
l7:value("irc", "Internet Relay Chat")
l7:value("jabber", "Jabber/XMPP")
l7:value("msnmessenger", "MSN Messenger")
l7:value("ntp", "Network Time Protocol")
l7:value("pop3", "POP3 Protocol")
l7:value("smtp", "SMTP Protocol")
l7:value("ssl", "SSL Protocol")
l7:value("vnc", "VNC Protocol")

ipp2p = s:option(MultiValue, "ipp2p", translate("IP-P2P"))
ipp2p.widget = "checkbox"
ipp2p:value("edk", "eDonkey, eMule, Kademlia")
ipp2p:value("kazaa", "KaZaA, FastTrack")
ipp2p:value("gnu", "Gnutella")
ipp2p:value("dc", "Direct Connect")
ipp2p:value("bit", "BitTorrent, extended BT")
ipp2p:value("apple", "AppleJuice")
ipp2p:value("winmx", "WinMX")
ipp2p:value("soul", "SoulSeek")
ipp2p:value("ares", "AresLite")

return m
