--[[
LuCI - Lua Configuration Interface

Copyright 2011 Josh King <joshking at newamerica dot net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.commotion.serval_keyring", package.seeall)

local key_file = "/etc/commotion/keys.d/mdp/"

function index()
	require("luci.i18n").loadc("commotion")
	local i18n = luci.i18n.translate

	entry({"admin", "commotion", "serval_keyring_new"}, call("new_keyring"))
	entry({"admin", "commotion", "serval_keyring_down"}, call("down"))
	entry({"admin", "commotion", "serval_keyring_up"}, call("up"))
	entry({"admin", "commotion", "serval_keyring"}, call("main"), "Serval Keyring", 20)
end

function main(Err)
   if not ERR then
	  ERR = nil
   end
   luci.http.prepare_content("text/html")
   luci.template.render("commotion/serval_keyring", {Err = Err})
end

function new_keyring()
   local debug = require "luci.commotion.debugger"
	debug.log("Creating New Keyring...")
	local values = luci.http.formvalue()
	local new = values["new_keyring"]
	local rm = luci.sys.call("rm "..key_file.."serval.keyring")
	--Define the various serval code to run
	local s_path = "SERVALINSTANCE_PATH="
	local s_start = s_path..key_file.." servald start"
	local s_stop = s_path..key_file.." servald stop"
	--local s_add_key = s_path..key_file.." servald keyring add"
	--local s_list_key = s_path..key_file.." servald keyring list"
	local AND = " && "
	--Run the actual serval command to create a new keyring & key
	local new_key = luci.sys.call(s_start..AND..s_stop)
	--debug.log(luci.sys.exec(s_list_key))
	--If no errors occured in sys calls
	if rm ~= 1 and new_key ~= 1 then
	   finish()
	else
	   main("Serval process failed")
	end
end

function finish()
   --TODO What kind of cleanup/setup do we need to do?
   local olsrd = luci.sys.call("/etc/init.d/olsrd restart")
   if olsrd == 0 then
	  main()
   else
	  main("olsrd failed to restart")
   end
end

---calls the file uploader and checks if the file is a correct config.
function up()
   local debug = require "luci.commotion.debugger"
   debug.log("uploader started")
   local error = nil
   setFileHandler("/tmp/", "upload", "serval.keyring")
   --debug.log(luci.sys.exec("md5sum /tmp/serval.keyring"))
   local values = luci.http.formvalue()
   local ul = values["upload"]
   if ul ~= '' and ul ~= nil then
	  debug.log("checking file")
	  error = checkFile("/tmp/serval.keyring")
   end
   --remove file if errors, copy it to correct directory and finish if a keyring
   if error ~= nil then
	  debug.log("error found")
	  local rm = luci.sys.call("rm /tmp/serval.keyring")
	  main(error)
   else
	  local rm = luci.sys.call("rm "..key_file.."serval.keyring")
	  local cp = luci.sys.call("cp /tmp/serval.keyring "..key_file..".")
	  finish()
   end
end

function checkFile(file)
   local keyring = luci.sys.exec("SERVALINSTANCE_PATH=/tmp/ servald keyring list")
   local key = string.match(keyring, "^(%w*):%w*:")
   if key == nil or string.len(key) ~= 64 then
	  return "The file supplied is not a proper keyring, or is password protected. Please upload another key."
   end
end


function down()
   local values = luci.http.formvalue()
   download(key_file.."serval.keyring")
   main()
end

function download(filename)
   local debug = require "luci.commotion.debugger"
   --TODO remove the luci.http.status calls and replace them with calls to main(error) with the appropriate text to inform the user of why they cannot download it.
   debug.log("download started")
  local f = io.open(filename)
  -- file does not exist
  if not f then
	 debug.log("File Does Not Exist")
	 luci.http.status(403, "Access denied")
	 return
  end
  -- send it
  luci.http.prepare_content("application/force-download")
  luci.http.header("Content-Disposition", "attachment; filename=serval.keyring")
  luci.ltn12.pump.all(luci.ltn12.source.file(f), luci.http.write)
  io.close(f)
end


---Uploads a file to a specified location, and possible file name.
--@param      location: (string) The full path to where the file should be saved.
--@param	  input_name: (string) The name specified by the input html field. <input type="submit" name="input_name_here" value="whatever you want"/>
--@param	 file_name   (string, optional) The optional name you would like the file to be saved as. If left blank the file keeps its uploaded name.
function setFileHandler(location, input_name, file_name)
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
