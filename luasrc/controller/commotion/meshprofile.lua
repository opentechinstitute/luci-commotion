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
	entry({"admin", "commotion", "meshprofile_down"}, call("down"))
	entry({"admin", "commotion", "meshprofile_up"}, call("up"))
	entry({"admin", "commotion", "meshprofile"}, call("main"), i18n("Mesh Profile"), 20).dependent=false
end

function main(ERR)
   local debug = require "luci.commotion.debugger"
   debug.log("main started")
   if not ERR then
	  ERR = nil
   end
   local uci = luci.model.uci.cursor()
   local rawProfiles = luci.fs.dir(profileDir)	
   local available = {}
   uci:get_all('network')
   uci:foreach('network', 'interface',
			   function(s)
				  if s['.name'] and s.profile then
					 table.insert(available, {s['.name'], s.profile})
					 --debug.log(s['.name'] .. " uses " .. s.profile)
				  end
			   end)
   local profiles = {}
   for i,p in ipairs(rawProfiles) do
		if not string.find(p, "^%.*$") then		
		   table.insert(profiles, p)
		end
   end
   luci.http.prepare_content("text/html")
   luci.template.render("commotion/meshprofile", {available = available, profiles = profiles, ERR = ERR})

end

function ifprocess()
   local debug = require "luci.commotion.debugger"
	debug.log("Processing profile application...")
	local error = nil
	local values = luci.http.formvalue()
	local tif = values["interfaces"]
	local p = values["profiles"]
	local uci = luci.model.uci.cursor()
	debug.log("Applying " .. p .. " to " .. tif)
	old_prof = uci:get('network', tif, "profile")
	local wireless = false
	uci:foreach('wireless','wifi-iface',
	    function(iface)
		if iface.network == tif then
			wireless = true
		end
	    end
	)
	if wireless then
		error = flush_wireless_profile(old_prof, p, tif)
	end
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
   --luci.sys.call("/etc/init.d/commotiond restart")
   --luci.sys.call("sleep 2; /etc/init.d/network restart")
   --In order to ensure that everything works cleanly a restart is required
   p = luci.sys.reboot()
   return({'complete'})
end

function checkFile(file)
   local debug = require "luci.commotion.debugger"
   --[=[
	  Checks the uploaded profile to ensure the required settings are there.
	  --]=]
	  debug.log("file check started")
	  local error = nil
	  if luci.fs.isfile(file) then
		 --required fields for a commotion profile
		 required = {
			"ip",
			"ipgenerate",
			"netmask",
			"dns",
			"type",
			"mode"}
		 --Parse uploaded file for settings
		 fields = {}
		 for line in io.lines(file) do
			setting = line:split("=")
			if setting[2] and setting[1] ~= "" and setting[1] ~= nil then
			   table.insert(fields, setting[1])
			end
		 end
		 if fields ~= {} then
			--Check to see if there are missing fields
			missing = {}
			for _,x in pairs(required) do
			   contained = nil
			   for _,m in pairs(fields) do
				  if x == m then
					 contained = 1
				  end
			   end
			   if not contained then
				  table.insert(missing, x)
				  debug.log("Field "..x.." is missing.")
			   end
			end
		 end
		 --If missing fields create error
		 if next(missing) ~= nil then
			misStr = table.concat(missing, ", ")
			error = "Your uploaded profile seem incomplete. You are missing at LEAST the values for "..misStr..". Please edit your profile and re-upload."
			--remove file because it is BAD
			removed = luci.sys.call('rm ' .. file)
		 else
			debug.log("Profile seems to be correctly formatted.")
		 end
	  else
		 error = "There does not seem to be a file here..."
		 debug.log("File is missing")
	  end
	  if error then
		 return error
	  else
		 return nil
	  end
	  return nil
end

function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end


function up()
   --[=[calls the file uploader and checks if the file is a correct config.
   --]=]
   local debug = require "luci.commotion.debugger"
   debug.log("up started")
   local error = nil
   setFileHandler("/etc/commotion/profiles.d/", "config")
   local values = luci.http.formvalue()
   local ul = values["config"]
   if ul ~= '' and ul ~= nil then
	  --TODO add logging to checkfile to identify why it does not work
	  file = "/etc/commotion/profiles.d/" .. ul
	  error = checkFile(file)
   end
   if error ~= nil then
	  main(error)
   else
	  main(nil)
   end
end

function down()
   local values = luci.http.formvalue()
   local dl = values["dl_profile"]
   if dl ~= '' then
	  download(dl)
   end
   main()
end

function download(filename)
   --TODO remove the luci.http.status calls and replace them with calls to main(error) with the appropriate text to inform the user of why they cannot download it.
   debug.log("download started")
   -- no file name provided
  if not filename then
    luci.http.status(403, "Forbidden")
    return
  end
  -- no relative paths with backrefs
  if filename:find("%.%.") then
    luci.http.status(403, "Access denied")
    return
  end
  -- no absolute paths
  if # filename > 0 and filename:sub(1,1) == '/' then
    luci.http.status(403, "Access denied")
    return
  end
  local f = io.open(profileDir .. filename)
  -- file does not exist
  if not f then
    luci.http.status(403, "Access denied")
    return
  end
  -- send it
  luci.http.prepare_content("application/force-download")
  luci.http.header("Content-Disposition", "attachment; filename=" .. filename)
  luci.ltn12.pump.all(luci.ltn12.source.file(f), luci.http.write)

  io.close(f)
end

function setFileHandler(location, input_name, file_name)
   --[=[Uploads a file to a specified location, and possible file name.
	  
	  Use:
	  add a call to this function within the index entry function called by an submit button  on a luci page.
	  eg.
	  function index()
	      entry({"admin", "commotion", "submit_clicked"}, call("start_upload"))
	  end
	  function start_upload()
	       setFileHandler("/tmp/", "image", "tmp_image.jpg")
	       local values = luci.http.formvalue()
	       local dl = values["image"] reload_page()
	  end

	  Inputs:
      location: (string) The full path to where the file should be saved.
	  input_name: (string) The name specified by the input html field. <input type="submit" name="input_name_here" value="whatever you want"/>
	  file_name: (string, optional) The optional name you would like the file to be saved as. If left blank the file keeps its uploaded name.

	  --]=]
	  local debug = require "luci.commotion.debugger"
	  local sys = require "luci.sys"
	  local fs = require "luci.fs"
	  local configLoc = location
	  local fp
	  luci.http.setfilehandler(
		 function(meta, chunk, eof)
		 if not fp then
			complete = nil
			if meta and meta.name == input_name then
			   if file_name ~= nil then
				  debug.log("starting download")
				  fp = io.open(configLoc .. file_name, "w")
			   else
				  debug.log("starting download")
				  fp = io.open(configLoc .. meta.file, "w")
			   end
			else
			   debug.log("file not of specified input type (input name variable)")
			end
		 end
		 if chunk then
			fp:write(chunk)
		 end
		 if eof then
			fp:close()
			debug.log("file downloaded")
		 end
		 end)
end


function flush_wireless_profile(old_profile, new_profile, interface)
   --TODO need a userspace warning that channel settings will not take effect and need to be done in the settings page.
   local debug = require "luci.commotion.debugger"
   local uci = luci.model.uci.cursor()
   local found = nil
   local old_dev = nil
   local name = nil
   local error = nil
   settings = get_commotion_settings(new_profile)
   uci:foreach("wireless", "wifi-iface",
			   function(s)
				  if s['.name'] == old_profile then
					 found = true
					 old_dev = s.device
					 name = s['.name']
				  elseif s['.name'] == new_profile  then
					 error = luci.i18n.translate("Each profile must have a seperate name. Please try with a unique profile.")
				  elseif s['.name'] ~= old_profile and s.network == interface then
					 error = luci.i18n.translate("You have multiple wireless interfaces on a single network interface. This is not allowed.")
				  end
			   end)
   --debug.log(tostring(conflict).." is the conflict level")
   if error ~= nil then  
	  return error
   else
	  uci:delete("wireless", name)
	  uci:section('wireless', 'wifi-iface', new_profile,
				  {device=old_dev,
				   network=interface,
				   ssid=settings['ssid'],
				   mode=settings['mode']})
	  uci:save("wireless")
	  uci:commit("wireless")
   end
end

function get_commotion_settings(file)
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
