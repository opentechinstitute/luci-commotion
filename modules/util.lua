--! @file util

string = string
local http = require "luci.http"
local io = require "io"

module "luci.commotion.util"

local util = {}

--! @name tprintf
--! @brief A printf for templates that takes a string tmpl and replaces the substing ${THING} with the object in the t array passed {THING="stuff"} 
--! @param tmpl templated string to modify
--! @param t array of template values to modify in the string
--! @example util_trpintf.lua
--! @return string modified with all found values in the array changed
function util.tprintf(tmpl,t)
	return (tmpl:gsub('($%b{})', function(w) return t[w:sub(3, -2)] or w end))
end

--! @name upload
--! @brief Uploads a file to a specified location, using an optional file name. To use this function add a call to this function within the index entry function called by a submit button  on a luci page.
--! @param location (string) The full path to where the file should be saved.
--! @param input_name (string) The name specified by the input html field. <input type="submit" name="input_name_here" value="whatever you want"/>
--! @param file_name (string, optional) The optional name you would like the file to be saved as. If left blank the file keeps its uploaded name.
--! @example examples/util_upload.lua
function util.upload(location, input_name, file_name)
	  local configLoc = location
	  local fp
	  http.setfilehandler(
		 function(meta, chunk, eof)
		 if not fp then
			complete = nil
			if meta and meta.name == input_name then
			   if file_name ~= nil then
				  fp = io.open(configLoc .. file_name, "w")
			   else
				  fp = io.open(configLoc .. meta.file, "w")
			   end
			else
			end
		 end
		 if chunk then
			fp:write(chunk)
		 end
		 if eof then
			fp:close()
		 end
		 end)
end


--! @name pass_to_shell
--! @brief A function to sanatize data before it is passed to the shell to execute.
--! @param String to be cleaned
function util.pass_to_shell(str)
   if str ~= nil and str ~= "" then
	  return str:gsub("$(","\\$"):gsub("`","\\`")
   else
	  return nil
   end
end

return util

