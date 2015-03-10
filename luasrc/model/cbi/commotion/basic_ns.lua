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
local cnet = require "luci.commotion.network"
local http = require "luci.http"
local ccbi = require "luci.commotion.ccbi"
local validate = require "luci.commotion.validate"

--Main title and system config map for hostname value
local m = Map("system", translate("Node Settings"), translate("In this section you'll set the basic required settings for this device, and the basic network settings required to connect this device to a Commotion Mesh network. You will be prompted to save your settings along the way and apply them at the end."))
--redirect on saved and changed to check changes.
if not SW.status() then
   m.on_after_save = ccbi.conf_page
end

--load up system section

local shn = m:section(TypedSection, "system")
--Don't display it
shn.anonymous = true
--Sure as Sugar don't remove it
shn.addremove = false

--Create a value field for hostname
local hname = shn:option(Value, "hostname", translate("Node Name"), translate("The node name (hostname) is a unique name for this device, visible to other devices and users on the network. Name this device in the field provided."))
hname.datatype = "rangelength(1, 53)"
hname.rmempty = false

function hname.validate(self,value)
   if validate.hostname(value) then
      return value
   else
      return nil, "Valid hostnames must be between 1 and 63 characters; contain only letters, numbers, and hyphens; start with a letter; and cannot end in a hyphen."
   end
end

function hname.write(self, section, value)
   hn = self:formvalue(section)
   old_hn = self:cfgvalue(section)
   if hn and hn == old_hn then
          return true
   else
          local node_id = cnet.nodeid()
          if string.match(hn, node_id) then
                -- requested hn already has nodeid
                return self.map:set(section, self.option, hn)
          else
                local new_hn = hn.."-"..string.sub(node_id, 1, 10)
                return self.map:set(section, self.option, new_hn)
          end
   end
end

--PASSWORDS
local v0 = true -- track password success across maps

-- CURRENT PASSWORD
-- Allow incorrect root password to prevent settings change
-- Don't prompt for password if none has been set
if luci.sys.user.getpasswd("root") then
   s0 = m:section(TypedSection, "_dummy", translate("Current Node Administration Password"), translate("The current node administration password is required to change the administration password."))
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

if SW.status() then
   pw_text = "This password will be used to make changes to this device after initial setup has been completed. The administration username is “root."
else
   pw_text = 'This password is used to make changes to this device. The administration username is “root".'
end
   
s = m:section(TypedSection, "_dummy", translate("Administration Password"), translate(pw_text))
s.addremove = false
s.anonymous = true

pw1 = s:option(Value, "_pw1", translate("Password"))
pw1.password = true

if SW.status() then
   pw1.rmempty = false
end

pw2 = s:option(Value, "_pw2", translate("Confirmation"))
pw2.password = true

--make sure passwords are equal
function pw1.validate(self, value, section)
    local v1 = value
    local v2 = pw2:formvalue(section)
   
    if validate.admin_pass(value) == false then
        m.message = translate("Error, no changes saved. See below.")
        self:add_error(section, translate("Password must be between 1 and 127 characters."))
        m.save = false
        return nil
    else    
        if root_pass_check() == true then
            if v1 and v2 and #v1 > 0 and #v2 > 0 then
                    if v1 == v2 then
			if luci.sys.user.setpasswd('root', v1) == 0 then
			   uci:set("setup_wizard", "passwords", "admin_pass", 'changed')
			   uci:save("setup_wizard")
			end
			if m.message == nil then
			   m.message = translate("Password successfully changed!")
			end
			return value
                    else
			m.message = translate("Error, no changes saved. See below.")
			self:add_error(section, translate("Given confirmation password did not match, password not changed!"))
			m.save = false
			return nil
                    end
            else
                    m.message = translate("Error, no changes saved. See below.")
                    self:add_error(section, translate("Unknown Error, password not changed!"))
                    m.save = false
                    return nil
            end
        end
    end
end

function s.cfgsections()
	return { "_pass" }
end

function root_pass_check()
   if not SW.status() then
	  local form = http.formvaluetable("cbid")
	  local check = nil
	  local conf_pass = nil
	  for field,val in pairs(form) do
		 string.gsub(field, ".-_pw(%d)$",
					 function(num)
						if tonumber(num) == 0 then
						   conf_pass = val
						end
						if val ~= nil and val ~= "" then
						   check = true
						end
		 end)
	  end
	  if check ~= nil then
		 if conf_pass then
			v0 = luci.sys.user.checkpasswd("root", conf_pass)
			if v0 ~= true then
			   m.message = translate("Incorrect node administration password. Changes rejected!")
			   m.save = false
			   return false
			else
			   return true
			end
		 else
			m.message = translate("Please enter your old node administration password. Changes rejected!")
			m.save = false
			return false
		 end
	  else
		 return true
	  end
   else
	return true	 
   end
end

return m
