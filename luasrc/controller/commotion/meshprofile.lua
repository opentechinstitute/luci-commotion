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
require "commotion_helpers"

local profileDir = "/etc/commotion/profiles.d/"

function index()
	require("luci.i18n").loadc("commotion")
	local i18n = luci.i18n.translate

	entry({"admin", "commotion", "meshprofile_submit"}, call("ifprocess"))
	entry({"admin", "commotion", "meshprofile_down"}, call("down"))
	entry({"admin", "commotion", "meshprofile_up"}, call("up"))
	entry({"admin", "commotion", "meshprofile"}, call("main"), "Mesh Profile", 20).dependent=false
end

function main(error)
   local uci = luci.model.uci.cursor()
   local rawProfiles = luci.fs.dir(profileDir)	
   local available = {}
   log("main started")
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
   luci.template.render("commotion/meshprofile", {available = available, profiles = profiles, error = error})
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

function checkFile(file)
   --[=[
	  Checks the uploaded profile to ensure the required settings are there.
	  --]=]
	  log("file check started")
	  if luci.fs.isfile(file) then

		 error = nil
		 --required fields for a commotion profile
		 required = {
			ip,
			ipgenerate,
			netmask,
			dns,
			type,
			mode}
		 --Parse uploaded file for settings
		 fields = {}
		 for line in io.lines(file) do
			setting = line:split("=")
			if setting[1] ~= "" and setting[1] ~= nil then
			   table.insert(fields, setting[1])
			end
		 end
		 --Check to see if there are missing fields
		 missing = {}
		 for i,x in pairs(required) do
			contained = nil
			for n,m in pairs(fields) do
			   if i == n then
				  contained = 1
			   end
			end
			if not contained then
			   table.insert(missing, i)
			   log("There are missing fields")
			end
		 end
		 --If missing fields create error
		 if next(missing) ~= nil then
			misStr = table.concat(missing, ",")
			error = "Your profile seem incomplete. You are missing at LEAST the values for "..misStr..". Please edit your profile and re-upload."
			--remove file because it is BAD
			luci.sys.call('rm ' .. file)
		 end
	  else
		 error=" There does not seem to be a file here..."
		 log("File is missing")
	  end
	  if error then
		 return error
	  end
end

function up()
   --[=[calls the file uploader and checks if the file is a correct config.
   --]=]
   log("up started")
   error = nil
   setFileHandler("/etc/commotion/profiles.d/", "config")
   local values = luci.http.formvalue()
   local ul = values["config"]
   if ul ~= '' then
	  --TODO add logging to checkfile to identify why it does not work
	  --TODO check fix to where website pushes to meshprofile_up_up on reupload.
	  error = checkFile("/etc/commotion/profiles.d/" .. ul)
   end
   main(error)
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
   log("download started")
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
	  local sys = require "luci.sys"
	  local fs = require "luci.fs"
	  local configLoc = location
	  local fp
	  luci.http.setfilehandler(
		 function(meta, chunk, eof)
			log("file handler activated")
		 if not fp then
			complete = nil
			if meta and meta.name == input_name then
			   if file_name ~= nil then
				  log("starting download")
				  fp = io.open(configLoc .. file_name, "w")
			   else
				  log("starting download")
				  fp = io.open(configLoc .. meta.file, "w")
			   end
			else
			   log("file not of specified input type (input name variable)")
			end
			if chunk then
			   fp:write(chunk)
			end
			if eof then
			   fp:close()
			   log("file downloaded")
			end
		 end
		 end)
end
