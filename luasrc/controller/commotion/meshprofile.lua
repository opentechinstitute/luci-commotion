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
	entry({"admin", "commotion", "meshprofile"}, call("main"), "Mesh Profile (New)", 20).dependent=false
end

function main()
	local uci = luci.model.uci.cursor()
	local rawProfiles = luci.fs.dir(profileDir)	
	local available = {}
	uci:get_all('network')
	uci:foreach('network', 'interface',
		function(s)
			if s['.name'] and s.profile then
				log(s.profile)
				table.insert(available, {s['.name'], s.profile})
				log(s['.name'] .. " uses " .. s.profile)
			end
		end)
	local profiles = {}
	for i,p in ipairs(rawProfiles) do
		log("checking " .. p)
		if not string.find(p, "^%.*$") then		
			table.insert(profiles, p)
			log("adding "..p.." to table")
		end
	end	
	log("profiles contains "..tostring(profiles))
	luci.http.prepare_content("text/html")
	luci.template.render("commotion/meshprofile", {available = available, profiles = profiles})
end

function ifprocess()
	log("Processing profile application...")
	local values = luci.http.formvalue()
	local tif = values["interfaces"]
	local p = values["profiles"]
	local uci = luci.model.uci.cursor()
	log("Applying " .. p .. " to " .. tif)
	uci:set('network', tif, "profile", p)
	uci:commit('network')
	uci:save('network')
	finish()
end

function finish()
   luci.template.render("QS/module/applyreboot", {redirect_location=("http://"..luci.http.getenv("SERVER_NAME").."/cgi-bin/luci/admin/commotion/meshprofile")})
   luci.http.close()
   luci.sys.call("/etc/init.d/commotiond restart")
   luci.sys.call("sleep 2; /etc/init.d/network restart")
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

