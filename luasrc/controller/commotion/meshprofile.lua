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
	local rawProfiles = luci.fs.dir(profileDir)	
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
	luci.template.render("commotion/meshprofile", {profiles = profiles})
end

function ifprocess()
	log("PROCESSING MEAT")
	finish()
end

function checkPage()
   local returns = luci.http.formvalue()
   errors = parseSubmit(returns)
   return errors
end

function finish()
   luci.sys.call("/etc/init.d/commotiond restart")
   luci.sys.call("sleep 2; /etc/init.d/network restart")
   -- applyreboot module should probably be made core --
   luci.template.render("QS/module/applyreboot", {redirect_location=("http://"..luci.http.getenv("SERVER_NAME").."/cgi-bin/luci/admin/commotion/meshprofile")})
   luci.http.close()
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

