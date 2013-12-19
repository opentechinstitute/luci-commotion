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
local cnet = require  "luci.commotion.network"
local sys = require "luci.sys"
local fs = require "luci.fs"

m = Map("olsrd", translate("Shared Mesh Keychain"), translate("To ensure that only authorized devices can route traffic on your Commotion mesh network, one Shared Mesh Keychain file can be generated and shared by all devices."))

--redirect on saved and changed to check changes.
m.on_after_save = ccbi.conf_page

s = m:section(NamedSection, "LoadPlugin", "olsrd-mdp", translate("Use a Shared Mesh Keychain to sign mesh routes. Yes/No"), translate("Check the box to use a Shared Mesh Keychain on this device. You'll also be required to upload or generate a Shared Mesh Keychain."))
s.anonymous = true
s.addremove = true

function s.remove(self, section)
   unset_commotion()
   self.map.proceed = false
   return self.map:del(section)
end

lib = s:option(Value, "library")
lib.default = "olsrd_mdp.so.0.1"
lib.hidden = true
lib.render = function() end
function lib:parse(section)
   local cvalue = self:cfgvalue(section)
   if not cvalue then
	  self:write(section, self.default)
   end
end

sp = s:option(Value, "servalpath")
sp.hidden = true
sp.default = "/etc/commotion/keys.d/mdp/"
sp.render = function() end
function sp:parse(section)
   local cvalue = self:cfgvalue(section)
   if not cvalue then
	  self:write(section, self.default)
   end
end
function sp.write(self, section, value)
   set_commotion()
   return self.map:set(section, self.option, value)
end

function set_commotion()
   db.log("set")
   uci.foreach("wireless", "wifi-iface",
			   function(s)
				  local sid = get_sid()
				  local name = s[".name"]
				  if s.mode == 'adhoc' then
					 if uci:get("network", s.network, "proto") == "commotion" then
						local profile = uci:get("network", s.network, "profile")
						cnet.commotion_set(profile, {mdp_keyring="/etc/commotion/keys.d/mdp/", mdp_sid=sid, serval='true'})
						cnet.commotion_set(profile)
					 end
				  end
			   end
   )
end

function unset_commotion()
   db.log("unset")
   uci.foreach("wireless", "wifi-iface",
			   function(s)
				  local sid = get_sid()
				  local name = s[".name"]
				  if s.mode == 'adhoc' then
					 if uci:get("network", s.network, "proto") == "commotion" then
						local profile = uci:get("network", s.network, "profile")
						cnet.commotion_set(profile, {serval='false'})
					 end
				  end
			   end
   )
end

function get_sid(path)
   db.log("get sid")
   if path == nil then
	  path = "/etc/commotion/keys.d/mdp/"
   end
   if not fs.isfile("/etc/commotion/keys.d/mdp/serval.keyring") then
	  sys.exec("SERVALINSTANCE_PATH="..path.." serval-client keyring create")
   end
   local sid = sys.exec("SERVALINSTANCE_PATH="..path.." serval-client keyring list")
   db.log(sid)
   --! @TODO TEST CODE CHANGE ME!!!!
   sid = "AA5C1E0DAB14D1177E134BD3001A31114901684FE04A53B67205D53A965C7365:29528158741:"
   local key = string.match(sid, "^(%w*):%w*:")
   if key == nil or string.len(key) ~= 64 then
	  m.message = translate("The file supplied is not a proper keyring, or is password protected. Please upload another key.")
	  m.status = -1
	  return false
   else
	  return key
   end
end

sid = s:option(Value, "sid")
sid.default = get_sid()
sid.optional = false
function sid.write(self, section, value)
   local value = get_sid()
   return self.map:set(section, self.option, value)
end

sid.render = function() end
function sid:parse(section)
   local cvalue = self:cfgvalue(section)
   if not cvalue then
	  self:write(section, self.default)
   end
end

uploader = s:option(FileUpload, "_upload", translate("Upload Shared Mesh Keychain File"), translate("If a Shared Mesh Keychain file was provided to you by a network administrator or another community member, select and upload it here to join this device to an existing mesh network."))
uploader.anonymous = true

function uploader.write(self, section, value)
   db.log("uploader write")
   if get_sid("/lib/uci/upload/") ~= false then
	  local mv = sys.call("mv /lib/uci/upload/cbid.serval.settings._upload /etc/commotion/keys.d/mdp/serval.keyring")
	  if mv ~= 0 then
		 return false
	  else
		 set_commotion()
		 return true
	  end
   else
	  return false
   end
end

dwnld = s:option(Button, "_dummy", translate("Download Shared Mesh Keychain"), translate("Download a copy of this device's existing Shared Mesh Keychain. Use this feature to make a backup of this file, or to share it with people putting up new devices on your Commotion mesh network."))
dwnld.anonymous = true

function dwnld.write(self, section, value)
   db.log("write")
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
new.anonymous = true

function new.write() return true end
function new.validate(self, section, value)
   db.log("new")
   m.save = true
   sys.exec("rm /etc/commotion/keys.d/mdp/serval.keyring")
   local create = sys.exec("SERVALINSTANCE_PATH=/etc/commotion/keys.d/mdp/ serval-client keyring create")
   set_commotion()
   db.log(create)
   if create then
	  return 'true'
   else
	  return nil
   end
end

return m
