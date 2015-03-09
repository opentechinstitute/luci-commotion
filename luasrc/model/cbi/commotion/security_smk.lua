
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
local util = require "luci.util"

m = Map("olsrd", translate("Shared Mesh Keychain"), translate("To ensure that only authorized devices can route traffic on your Commotion mesh network, one Shared Mesh Keychain file can be generated and shared by all devices."))

--redirect on saved and changed to check changes.
m.on_after_save = ccbi.conf_page

s = m:section(TypedSection, "LoadPlugin", translate("Use a Shared Mesh Keychain to sign mesh routes. Yes/No"), translate("Add or remove a Shared Mesh Keychain on this device. You can also upload or generate a new Shared Mesh Keychain once you add a Shared Mesh Keychain to this device."))
s.addremove = true
s.anonymous = true

function s.filter(self, section)
   return self.map:get(section, "library") == "olsrd_mdp.so.0.1"
end

function s.remove(self, section)
   unset_commotion()
   return self.map:del(section)
end

--! @brief Preempts loadPlugin section creation with the deletion and re-creation of the serval keyring. Simply, when the add button is clicked the key is deleted and re-created.
function s.create(self, section)
   sys.exec("rm /etc/commotion/keys.d/mdp/serval.keyring")
   set_commotion()
   s.fields.sid.default = get_sid()
   return AbstractSection.create(self, section)
end

function s.parse(self, novld)
   local changes = uci:changes("olsrd")
   if changes and changes.olsrd then
	  db.log("changes found:")
	  self.changed = true
   else
	  db.log("changes NOT found")
   end
   TypedSection.parse(self, novld)
end

lib = s:option(Value, "library")
lib.default = "olsrd_mdp.so.0.1"
lib.render = function() end
function lib:parse(section)
   db.log("lib parse")
   local cvalue = self:cfgvalue(section)
   db.log(cvalue)
   if not cvalue then
	  self:write(section, self.default)
   end
end

function lib.write(self, section, value)
   set_commotion()
   return self.map:set(section, self.option, value)
end


sp = s:option(Value, "keyringpath")
sp.default = "/etc/commotion/keys.d/mdp/serval.keyring"
sp.render = function() end
function sp:parse(section)
   db.log("sp parse")
   local cvalue = self:cfgvalue(section)
   db.log(cvalue)
   if not cvalue then
	  self:write(section, self.default)
   end
end

function sp.write(self, section, value)
   set_commotion()
   m.changed = true
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
						cnet.commotion_set(profile, {mdp_keyring="/etc/commotion/keys.d/mdp/serval.keyring", mdp_sid=sid, serval='true'})
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
	  sys.exec("SERVALINSTANCE_PATH=/etc/commotion/keys.d/mdp/ serval-client keyring create")
	  sys.exec("SERVALINSTANCE_PATH=/etc/commotion/keys.d/mdp/ serval-client keyring add")
   end
   local sid = sys.exec("SERVALINSTANCE_PATH="..path.." serval-client keyring list |tail -1")
   local key = string.match(sid, "^(%w*):%w*:?")
   if key == nil or string.len(key) ~= 64 then
	  m.message = translate("The file supplied is not a proper keyring, or is password protected. Please upload another key.")
	  m.state = -1
	  return false
   else
	  return key
   end
end

sid = s:option(Value, "sid")
sid.default = get_sid()
function sid.write(self, section, value)
   db.log("sid write")
   local value = get_sid()
   m.changed = true
   return self.map:set(section, self.option, value)
end

sid.render = function() end
function sid:parse(section)
   db.log("sid parse")
   local cvalue = self:cfgvalue(section)
   if not cvalue then
	  self:write(section, get_sid())
   end
end

uploader = s:option(FileUpload, "_upload", translate("Upload Shared Mesh Keychain File"), translate("If a Shared Mesh Keychain file was provided to you by a network administrator or another community member, select and upload it here to join this device to an existing mesh network."))
uploader.anonymous = true

function uploader.write(self, section, value)
   db.log("uploader write")
   local nfs = require "nixio.fs"
   sys.exec("mv /lib/uci/upload/cbid.olsrd.*._upload /lib/uci/upload/serval.keyring")
   if get_sid("/lib/uci/upload/") ~= false then
	  local mv = nfs.move("/lib/uci/upload/serval.keyring", "/etc/commotion/keys.d/mdp/serval.keyring")
	  self.map:set(section, "sid", get_sid())
	  set_commotion()
	  m.changed = true
   else
	  return false
   end
end

dwnld = s:option(Button, "_dummy", translate("Download Shared Mesh Keychain"), translate("Download a copy of this device's existing Shared Mesh Keychain. Use this feature to make a backup of this file, or to share it with people putting up new devices on your Commotion mesh network."))
dwnld.anonymous = true

function dwnld.write(self, section, value)
   local ltn12 = require "luci.ltn12"
   keyring = uci:get("serval", "settings", "olsrd_mdp_keyring")
   local f = io.open(keyring.."/serval.keyring")
   if not f then
	  self:add_error(section, translate("No Current Shared Mesh Keychain To Download."))
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

function new.write(self, section, value)
   m.changed = true
   return self.map:set(section, "sid", get_sid())
end

function new.validate(self, section, value)
   db.log("new")
   m.save = true
   sys.exec("rm /etc/commotion/keys.d/mdp/serval.keyring")
   set_commotion()
   return true
end

return m
