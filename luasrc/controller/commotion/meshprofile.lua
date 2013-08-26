--[[
LuCI - Lua Configuration Interface

Copyright 2011 Josh King <joshking at newamerica dot net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.commotion.meshprofile", package.seeall)

require "luci.model.uci"
require "luci.fs"
require "luci.sys"

local profileDir = "/etc/commotion/profiles.d/"

function index()
	require("luci.i18n").loadc("commotion")
	local i18n = luci.i18n.translate

	entry({"admin", "commotion", "meshprofile_submit"}, call("ifprocess"))
	entry({"admin", "commotion", "meshprofile"}, call("main"), "Mesh Profile", 20).dependent=false
end

function main(error)
	local uci = luci.model.uci.cursor()
	local rawProfiles = luci.fs.dir(profileDir)	
	local available = {}
	uci:get_all('network')
	uci:foreach('network', 'interface',
		function(s)
			if s['.name'] and s.profile then
				table.insert(available, {s['.name'], s.profile})
				log(s['.name'] .. " uses " .. s.profile)
			end
		end)
	local profiles = {}
	for i,p in ipairs(rawProfiles) do
		if not string.find(p, "^%.*$") then		
			table.insert(profiles, p)
		end
	end	
	luci.http.prepare_content("text/html")
	luci.template.render("commotion/meshprofile", {available = available, profiles = profiles})
end

function ifprocess()
	log("Processing profile application...")
	local error = nil
	local values = luci.http.formvalue()
	local tif = values["interfaces"]
	local p = values["profiles"]
	local uci = luci.model.uci.cursor()
	log("Applying " .. p .. " to " .. tif)
	old_prof = uci:get('network', tif, "profile")
	error = flush_wireless_profile(old_prof, p, tif)
	uci:set('network', tif, "profile", p)
	uci:commit('network')
	uci:save('network')
	if error ~= nil then
	   main(error)
	else
	   finish()
	end
end


function finish()
   luci.template.render("QS/module/applyreboot", {redirect_location=("http://"..luci.http.getenv("SERVER_NAME").."/cgi-bin/luci/admin/commotion/meshprofile")})
   luci.http.close()
--   luci.sys.call("/etc/init.d/commotiond restart")
--   luci.sys.call("sleep 2; /etc/init.d/network restart")
   luci.sys.reboot()
   return({'complete'})
end

function log(msg)
	if (type(msg) == "table") then
        	for key, val in pairs(msg) do
        		if type(key) == 'boolean' then
        			log('{')
        			log(tostring(key))
        			log(':')
        			log(val)
        			log('}')
        		elseif type(val) == 'boolean' then
        			log('{')
        			log(key)
        			log(':')
        			log(tostring(val))
        			log('}')
        		else
        			log('{')
        			log(key)
        			log(':')
        			log(val)
        			log('}')
        		end
        	end
        else
        	luci.sys.exec("logger -t luci " .. msg)
        end
end


function flush_wireless_profile(old_profile, new_profile, interface)
   --TODO need a userspace warning that channel settings will not take effect and need to be done in the settings page.
   local uci = luci.model.uci.cursor()
   local found = nil
   local old_dev = nil
   local name = nil
   local error = nil
   settings = get_commotion_settings(new_profile)
   uci:foreach("wireless", "wifi-iface",
			   function(s)
				  log(s['.name'] )
				  if s['.name'] == old_profile then
					 --check that they are
					 log("OLD")
					 found = true
					 old_dev = s.device
					 name = s['.name']
				  elseif s['.name'] == new_profile  then
					 error = luci.i18n.translate("Each profile must have a seperate name. Please try with a unique profile.")
				  elseif s['.name'] ~= old_profile and s.network == interface then
					 error = luci.i18n.translate("You have multiple wireless interfaces on a single network interface. This is not allowed.")
				  end
			   end)
   log(tostring(conflict).." is the conflict level")
   if error ~= nil then  
	  return error
   else
	  uci:delete("wireless", name)
	  uci:section('wireless', 'wifi-iface', new_profile,
				  {device=old_dev,
				   network=interface,
				   ssid=settings[ssid],
				   mode=settings[mode]})
	  uci:save("wireless")
	  uci:commit("wireless")
   end
end

function get_commotion_settings(file)
   --[=[ Checks the quickstart settings file and returns a table with setting, value pairs.--]=]
   local QS = luci.controller.QS.QS
   settings = {}
   for line in io.lines("/etc/commotion/profiles.d/"..file) do
	  setting = line:split("=")
	  if setting[1] ~= nil and setting[2] ~= nil then
		 settings[setting[1]] = setting[2]
	  end
   end
   if next(settings) then
	  return settings
   end
end

function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end
