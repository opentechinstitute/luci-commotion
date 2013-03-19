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

	entry({"admin", "commotion", "meshprofile"}, call("main"), "Mesh Profile (New)", 20).dependent=false
end

function main()
	-- if return values get them and pass them to return value parser --
	--[[ Ignoring upload until luci-ssl is enabled
	setFileHandler()
	check = luci.http.formvalue()
	if next(check) ~= nil then
	   errorMsg = checkPage()
	end 
		]]--	
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

function checkPage()
   local returns = luci.http.formvalue()
   errors = parseSubmit(returns)
   return errors
end
--[[ Build without upload until luci-ssl is enabled 
function setFileHandler()                                                                                                                                                                                    
	local sys = require "luci.sys"                                                                                                                                                                            
	local fs = require "luci.fs"                                                                                                                                                                              
        -- causes media files to be uploaded to their namesake in the /tmp/ dir.                                                                                                                                  
        local fp                                                                                                                                                                                                  
        luci.http.setfilehandler(
        -- Use profileDir .. meta.file instead of "quickstartMesh" --
	function(meta, chunk, eof)                                                                                                                                                                         
		if not fp then                                                                                                                                                                              
        		if meta and meta.name == "config" then                                                                                                                                               
        			fp = io.open(profileDir .. meta.file, "w")                                                                                                                                  
        		end
        		if chunk then                                                                                                                                                                        
        			fp:write(chunk)                                                                                                                                                                   
        		end                                                                                                                                                                                  
        		if eof then                                                                                                                                                              
        			fp:close()                                                                                                                                                            
        		end                                                                                                                                                                      
        	end                                                                                                                                                                             
	end)                                                                                                                                                                                   
end


function uploadRenderer()                                                                                                                      
--creates an uploader based upon the fileType of the page config
	local uci = luci.model.uci.cursor()
	local page = uci:get('quickstart', 'options', 'pageNo')
        local fileType = uci:get('quickstart', page, 'fileType')
        --TODO check uploader module to see if it needs any values
        if fileType == 'config' then
        	fileInstructions="and submit a config file from your own computer. You will be able to customize this configuration once it has been applied to the node."
        elseif fileType == 'key' then
        	fileInstructions="and submit a key file from your own computer. This will allow your node to talk to any network with the same key file"           
        end
        return {['fileType']=fileType, ['fileInstructions']=fileInstructions}
end
                                                                                                                                                                                                     
function uploadParser()                                                                                                                                      
--Parses uploaded data                                                                                                                                    
	local uci = luci.model.uci.cursor()                                                                                                                       
        error = ''                                                                                                                                             
        if luci.http.formvalue("config") ~= '' then                                                                                                               
        	file = luci.http.formvalue("config")                                                                                                               
        elseif luci.http.formvalue("config") == '' then                                                                                                           
        	error = "Please upload a setting file."                                                                                                            
        elseif luci.http.formvalue("key") ~= '' then                                                                                                              
        	file = luci.http.formvalue("key")                                                                                                                  
        end
        if file then
        	if luci.http.formvalue("config") then
        		--check that each file is actually the file type that we are looking for!!!
        		if not uci:get('nodeConf', 'confInfo', 'name') then
        			error = 'This file is not a configuration file. Please check the file and upload a working config file or go back and choose a pre-built config'
        		end
        	elseif luci.http.formvalue("key") then
        		if luci.sys.call("pwd") == '1' then
        			elseif luci.sys.call("servald keyring list") == '1' then
        			error = 'The file uploaded is either not a proper keyring or has a pin that is required to access the key within. If you do not think that your keyring has a pin please upload a proper servald keyring for your network key. If your keyring is pin protected, please click continue below.'
        		end
        	end
        end
        if error ~= '' then
        	return error
        end
end

]]--	
function finish()
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

