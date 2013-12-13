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

local SW = require "luci.commotion.setup_wizard"
local db = require "luci.commotion.debugger"
local uci = require "luci.model.uci".cursor()
local cdisp = require "luci.commotion.dispatch"
local cnet = require "luci.commotion.network"

--Main title and system config map for hostname value
local m = Map("system", translate("Basic Configuration"), translate("In this section you'll set the basic required settings for this device, and the basic network settings required to connect this device to a Commotion Mesh network. You will be prompted to save your settings along the way and apply them at the end."))
--redirect on saved and changed to check changes.
if not SW.status() then
   m.on_after_save = cdisp.conf_page
end

--load up system section
local shn = m:section(TypedSection, "system")
--Don't display it
shn.anonymous = true

--Create a value field for hostname
local hname = shn:option(Value, "hostname", translate("Node Name"), translate("The node name (hostname) is a unique name for this device, visible to other devices and users on the network. Name this device in the field provided."))
function hname.write(self, section, value)
   local node_id = cnet.nodeid()
   local new_hn = value.."-"..string.sub(node_id, 1, 10)
   return self.map:set(section, section, new_hn)
end

--PASSWORDS

local v0 = true -- track password success across maps

-- Allow incorrect root password to prevent settings change
-- Don't prompt for password if none has been set
if luci.sys.user.getpasswd("root") then
   s0 = m:section(TypedSection, "_dummy", translate("Current Password"),
				  translate("Current password required to make changes on this page"))
   s0.addremove = false
   s0.anonymous = true
   
   pw0 = s0:option(Value, "pw0", translate("Current Password"))
   pw0.password = true
   -- fail by default
   v0 = false
   
   function s0.cfgsections()
	  return { "_pass0" }
   end
end

if SW.status() then
   pw_text = "This password will be used to make changes to this device after initial setup has been completed. The administration username is “root."
else
   pw_text = "This password is used to make changes to this device. The administration username is “root."
end
   
s = m:section(TypedSection, "_dummy", translate("Administration Password"), translate(pw_text))
s.addremove = false
s.anonymous = true

pw1 = s:option(Value, "pw1", translate("Password"))
pw1.password = true

pw2 = s:option(Value, "pw2", translate("Confirmation"))
pw2.password = true

function s.cfgsections()
	return { "_pass" }
end

function m.on_before_commit(map)
	-- if existing password, make sure user has old password
	if s0 then
		v0 = luci.sys.user.checkpasswd("root", formvalue("_pass0"))
	end

	if v0 == false then
		m.message = translate("Incorrect password. Changes rejected!")
		m.save=v0
		m2.save=v0
	end
end

function m.on_commit(map)
   local v1 = pw1:formvalue("_pass")
   local v2 = pw2:formvalue("_pass")
	
	if v0 == true and v1 and v2 and #v1 > 0 and #v2 > 0 then
	   if v1 == v2 then
		  if luci.sys.user.setpasswd(luci.dispatcher.context.authuser, v1) == 0 then
			 m.message = translate("Password successfully changed!")
		  else
			 m.message = translate("Unknown Error, password not changed!")
		  end
	   else
		  m.message = translate("Given password confirmation did not match, password not changed!")
	   end
	end
end

return m
