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

local ccbi = require "luci.commotion.ccbi"
local db = require "luci.commotion.debugger"
local uci = require "luci.model.uci".cursor()

m = Map("serval", translate("Shared Mesh Keychain"), translate("To ensure that only authorized devices can route traffic on your Commotion mesh network, one Shared Mesh Keychain file can be generated and shared by all devices."))

--redirect on saved and changed to check changes.
m.on_after_save = ccbi.conf_page

s = m:section(TypedSection, "settings", translate("Use a Shared Mesh Keychain to sign mesh routes. Yes/No"), translate("Check the box to use a Shared Mesh Keychain on this device. You'll also be required to upload or generate a Shared Mesh Keychain."))
toggle = s:option(Flag, "enabled")
s.anonymous = true

toggle.disabled = "false"
toggle.enabled = "true"
toggle.rmempty = true
toggle.default = toggle.disabled
toggle.title = nil

--Make flag actually check for section.changed and set that flag for the confirmation page to work

--[[
config LoadPlugin
    option sid 'A6D29C35D0409F176B22AEF2FAC447572540F39D8AEB8C48C107F9A11D224B06'
    option servalpath '/etc/commotion/keys.d/mdp'
]]--

--TODO make this a commotion function. It is repeated in multiple cbi models.
function toggle.remove(self, section)
   value = self.map:get(section, self.option)
   if value ~= self.disabled then
	  self.section.changed = true
	  return self.map:del(section, self.option)
   end
end

function toggle.write(self, section, fvalue)
   db.log("toggle write function")
   db.log(fvalue)
   value = self.map:get(section, self.option)
   if value ~= fvalue then
	  self.section.changed = true
	  return self.map:set(section, self.option, value)
   end
end

uploader = s:option(FileUpload, "_upload", translate("Upload Shared Mesh Keychain File"), translate("If a Shared Mesh Keychain file was provided to you by a network administrator or another community member, select and upload it here to join this device to an existing mesh network."))
uploader:depends("enabled", "true")
uploader.anonymous = true

--! TODO test this function to ensure that it checks for a good key and then writes the new_mdp_keyring value to true if so.
function uploader.write(self, section, value)
   local keyring = luci.sys.exec("SERVALINSTANCE_PATH=/lib/uci/upload/ servald keyring list")
   local key = string.match(keyring, "^(%w*):%w*:")
   if key == nil or string.len(key) ~= 64 then
	  self:add_error(section, translate("The file supplied is not a proper keyring, or is password protected. Please upload another key."))
   else
	  --set key variable for mdp
	  self.map:set(section, "mdp_sid", key)
	  return self.map:set(section, "new_mdp_keyring", "true")
   end
end


dwnld = s:option(Button, "_dummy", translate("Download Shared Mesh Keychain"), translate("Download a copy of this device's existing Shared Mesh Keychain. Use this feature to make a backup of this file, or to share it with people putting up new devices on your Commotion mesh network."))
dwnld.anonymous = true
dwnld:depends("enabled", "true")

function dwnld.write(self, section, value)
   keyring = uci:get("serval", "settings", "olsrd_mdp_keyring")
   local f = io.open(keyring)
   if not f then
	  self:add_error(section, translate("No Current Serval Key To Download."))
	  return nil
   end
   luci.http.prepare_content("application/force-download")
   luci.http.header("Content-Disposition", "attachment; filename=serval.keyring")
   luci.ltn12.pump.all(luci.ltn12.source.file(f), luci.http.write)
   io.close(f)
   return true
end

new = s:option(Button, "_dummy2", translate("Create a new Shared Mesh Keychain file"), translate("Click on the button below to create a new Shared Mesh Keychain file. This will DELETE the existing Shared Mesh Keychain on this device. Use this option if you are creating a brand new Commotion mesh network, or if you are changing the Shared Mesh Keyhchain on an existing network. In either case, create a backup of the existing Shared Mesh Keychain first."))
new:depends("enabled", "true")
new.anonymous = true

function new.write(self, section, value)
   return self.map:set(section, "new_mdp_keyring", "true")
end

return m
