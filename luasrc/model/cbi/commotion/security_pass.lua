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
local db = require "luci.commotion.debugger"
local http = require "luci.http"
local ccbi = require "luci.commotion.ccbi"
local uci = require "luci.model.uci".cursor()

local m = Map("wireless", translate("Passwords"), translate("Commotion basic security settings places all the passwords and other security features in one place for quick configuration. "))

--redirect on saved and changed to check changes.
m.on_after_save = ccbi.conf_page

--PASSWORDS
local v0 = true -- track password success across maps

-- CURRENT PASSWORD
-- Allow incorrect root password to prevent settings change
-- Don't prompt for password if none has been set
if luci.sys.user.getpasswd("root") then
   s0 = m:section(TypedSection, "_dummy", translate("Current Node Administration Password"), translate("Current node administration password required to make changes on this page"))
   s0.addremove = false
   s0.anonymous = true
   pw0 = s0:option(Value, "_pw0")
   pw0.password = true
   -- fail by default
   v0 = false
   function s0.cfgsections()
	  return { "_pass0" }
   end
end

local interfaces = {}
uci:foreach("wireless", "wifi-iface",
			function(s)
			   local name = s[".name"]
			   local key = s.key or "NONE"
			   local mode = s.mode or "NONE"
			   local enc = s.encryption or "NONE"
			   table.insert(interfaces, {name=name, mode=mode, key=key, enc=enc})
			end
)

--iface password creator for all other interfaces
--! @name pw_sec_opt
--! @brief create password options to add to interface passed-
function pw_sec_opt(pw_s, iface, mode)
   --section options
   pw_s.addremove = false
   pw_s.anonymous = true
   local helptext
   
   --encryption toggle
   if (mode == 'adhoc') then
	   helptext = translate("When people connect to this mesh network, should a password be required?")
   elseif (mode == 'ap') then
	   helptext = translate("When people connect to this access point, should a password be required?")
   end
   enc = pw_s:option(Flag, "encryption", translate("Require a Password?"), helptext)
   enc.disabled = "none"
   enc.enabled = "psk2"
   enc.rmempty = false
   enc.default = enc.disabled --default must == disabled value for rmempty to work
   
   --Make enc flag actually check for section.changed and set that flag for the confirmation page to work
   enc.write = ccbi.flag_write
   function enc.remove(self, section)
	  value = self.map:get(section, self.option)
	  if value ~= self.disabled then
		 local key = self.map:del(section, "key")
		 local enc = self.map:del(section, self.option)
		 self.section.changed = true
		 return key and enc or false
	  end
   end
      
   --password options
   pw1 = pw_s:option(Value, (iface.name.."_pw1"))
   pw1.password = true
   pw1:depends("encryption", "psk2")
   pw1.datatype = "wpakey"
   
   --confirmation password
   pw2 = pw_s:option(Value, iface.name.."_pw2", nil, translate("Confirm Password"))
   pw2.password = true
   pw2:depends("encryption", "psk2")
   
   --password should write to the key, not to the dummy value
   function pw1.write(self, section, value)
	  return self.map:set(section, "key", value)
   end
   
   --Don't actually write this value, just return success
   function pw2.write(self, section, value)
	  return true
   end
   
   --make sure passwords are equal
   function pw1.validate(self, value, section)
	  local v1 = value
	  local v2 = http.formvalue(string.gsub(self:cbid(section), "%d$", "2"))
	  if v1 and v2 and #v1 > 0 and #v2 > 0 then
		 if v1 == v2 then
			if m.message == nil then
			   m.message = translate("Password successfully changed!")
			end
			return value
		 else
			m.message = translate("Error, no changes saved. See below.")
			self:add_error(section, translate("Given password confirmation did not match, password not changed!"))
			m.state = -1
			return nil
		 end
	  else
		 m.message = translate("Error, no changes saved. See below.")
		 self:add_error(section, translate("Unknown Error, password not changed!"))
		 m.state = -1
		 return nil
	  end
   end
end

--MESH ECRYPTION PASSWORD
--Check for mesh interfaces
mesh_ifaces = {}
for i,iface in ipairs(interfaces) do
   if iface.mode == "adhoc" then
	  table.insert(mesh_ifaces, iface)
   end
end

local pw_text = "To encrypt Commotion mesh network data between devices, each device must share a common mesh encryption password. Enter that shared password here."
if #mesh_ifaces > 1 then
   for _,x in pairs(mesh_ifaces) do
	  local meshPW = m:section(NamedSection, x.name, "wifi-iface", x.name, pw_text)
	  meshPW = pw_sec_opt(meshPW, x, 'adhoc')
   end
elseif  #mesh_ifaces == 1 then
   local meshPW = m:section(NamedSection, mesh_ifaces[1].name, "wifi-iface", mesh_ifaces[1].name, pw_text)
   meshPW = pw_sec_opt(meshPW, mesh_ifaces[1], 'adhoc')
end

--ADMIN PASSWORD
admin_pw_text = "This password is used to login to this node."
admin_pw_s = m:section(TypedSection,"_dummy", translate("Administration Password"), translate(admin_pw_text))
admin_pw_s.addremove = false
admin_pw_s.anonymous = true

admin_pw1 = admin_pw_s:option(Value, "admin_pw1")
admin_pw1.password = true

admin_pw2 = admin_pw_s:option(Value, "admin_pw2", translate("Confirmation"))
admin_pw2.password = true

function admin_pw_s.cfgsections()
	return { "_pass" }
end

--Check for other Interfaces
for i,iface in ipairs(interfaces) do
   if iface.mode ~= "adhoc" then
	  local otherPW = m:section(NamedSection, iface.name, "wifi-iface", iface.name.." Interface", translate("Enter the password people should use to connect to this interface."))
	  otherPW = pw_sec_opt(otherPW, iface, iface.mode)
   end
end

--!brief This map checks for the admin password field and denies all saving and removes the confirmation page redirect if it is there.
function m.on_parse(self)
   local form = http.formvaluetable("cbid.wireless")
   local check = nil
   local conf_pass = nil
   for field,val in pairs(form) do
	  string.gsub(field, ".-_pw(%d)$",
				  function(num)
					 if tonumber(num) == 0 then
						conf_pass = val
					 end
					 if val then
						check = true
					 end
				  end)
   end
   if check ~= nil then
	  if conf_pass then
		 v0 = luci.sys.user.checkpasswd("root", conf_pass)
		 if v0 ~= true then
			m.message = translate("Incorrect password. Changes rejected!")
			m.save = false
		 end
	  else
		 m.message = translate("Please enter your old password. Changes rejected!")
		 m.save = false
	  end
   end
end

--! admin password changes checks
function m.on_save(self)
   local v1 = admin_pw1:formvalue("_pass")
   local v2 = admin_pw2:formvalue("_pass")
   if v0 == true and v1 and v2 and #v1 > 0 and #v2 > 0 then
	  if v1 == v2 then
		 if luci.sys.user.setpasswd(luci.dispatcher.context.authuser, v1) == 0 then
			m.message = translate("Admin Password successfully changed!")
			uci:set("setup_wizard", "passwords", "admin_pass", 'changed')
			uci:save("setup_wizard")
		 else
			m.message = translate("Unknown Error, password not changed!")
			m.state = -1
		 end
	  else
		 m.message = translate("Given password confirmation did not match, password not changed!")
		 m.state = -1
	  end
   end
end

return m



