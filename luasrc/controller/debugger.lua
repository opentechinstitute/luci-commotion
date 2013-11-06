
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

module("luci.controller.commotion-debug-helper.debugger", package.seeall)

require "luci.sys"
require "luci.fs"

function index()
   entry({"admin", "commotion", "debug"}, template("commotion-debug-helper/debugger"), translate("Commotion Debugging Helper"), 50)
   page = entry({"admin", "commotion","debug", "submit"}, call("debug"), nil)
   page.leaf=true
end

function debug()
   report = {}
   report.Name = luci.http.formvalue("name")
   report.Contact = luci.http.formvalue("contact")
   report.User_action = luci.http.formvalue("userAction")
   report.Expected_Behavior = luci.http.formvalue("expectedBehavior")
   report.Bad_Behavior = luci.http.formvalue("badBehavior")
   
   local f = io.open("/tmp/debug.info", "r")
   for i,x in pairs(report) do
	  if x then
		 f:write(string.format("%q", i.." : "..x))
	  end
   end
   f:close()
   data()
end

function data()
   debug_commands = {"network", "state", "rules", "all"}
   value = string.format("%q", luci.http.formvalue("buginfo"))
   if luci.util.contains(debug_commands, value) then
	  if luci.sys.call("/usr/sbin/cdh -a " .. value) == 0 then
		 local f = io.open("/tmp/debug.info")
		 luci.http.prepare_content("application/force-download")
		 luci.http.header("Content-Disposition", "attachment; filename=debug.info")
		 luci.ltn12.pump.all(luci.ltn12.source.file(f), luci.http.write)
		 luci.fs.unlink("/tmp/debug.info")
		 f:close()
	  end
   end
end
