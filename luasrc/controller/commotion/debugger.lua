

--[[

appSplash - LuCI based debugging tool.
Copyright (C) <2012>  <Seamus Tuohy>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

module("luci.controller.commotion.debugger", package.seeall)

require "luci.sys"
require "luci.fs"

function index()
   entry({"admin", "status", "debug"}, template("commotion/debugger"), translate("Commotion Debugging Helper"), 50)
   page = entry({"admin", "status","debug", "submit"}, call("debug"), nil)
   page.leaf=true
end

--! @name debug
--! @brief checks for user reported text and creates a debug file and adds to it.
function debug()
   report = {}
   report.Name = luci.http.formvalue("name")
   report.Contact = luci.http.formvalue("contact")
   report.User_action = luci.http.formvalue("userAction")
   report.Expected_Behavior = luci.http.formvalue("expectedBehavior")
   report.Bad_Behavior = luci.http.formvalue("badBehavior")
   
   if report.Bad_Behavior == '' and report.Expected_Behavior == '' and report.User_action == '' then
     luci.template.render("commotion/debugger", {err = {notice = "Must include at least some information about the problem that occurred."}})
     return
   end
   
   if report ~= {} then
	  local f = io.open("/tmp/debug.info", "w")
	  for i,x in pairs(report) do
		 if x then
			f:write(string.format("%q", i.." : "..x.."\n"))
		 end
	  end
	  f:close()
   end
   data()
end

--! @name data
--! @brief Checks for the buginfo formvalue and then runs the corresponding debug helper function type and returns it to the user.
--! @note the anon function that re-implements luci.util.contains is for the extra quotes that %q formatting adds in. 
function data()
   local http = require "luci.http"
   debug_commands = {"network", "state", "rules", "all"}
   value = string.format("%q", luci.http.formvalue("buginfo"))
   if function()
	  for i,x in pairs(debug_commands) do
		 if value == string.format("%q", x) then
			return true
		 end end end
   then
	  if luci.sys.call("/usr/sbin/cdh -a " .. value) == 0 then
		 local f = io.open("/tmp/debug.info")
		 http.prepare_content("application/force-download")
		 http.header("Content-Disposition", "attachment; filename=debug.info")
		 luci.ltn12.pump.all(luci.ltn12.source.file(f), luci.http.write)
		 luci.fs.unlink("/tmp/debug.info")
		 f:close()
	  end
   end
   old_uri = luci.http.getenv("REQUEST_URI")
   uri = string.gsub(old_uri, "debug/submit", "debug")
   http.redirect("https://"..luci.http.getenv("SERVER_NAME")..uri)
end
