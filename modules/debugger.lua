--! @file debug

local sys = require "luci.sys"
local type, tostring, pairs = type, tostring, pairs

module "luci.commotion.debugger"

local debugger = {}


--! @name log
--! @brief Outputs a message to logread tagged with the string "luci"
--! @bug Tables that are self referential (_G) will recurse FOREVER. Don't worry new-pretty version in the works. 
--! @param msg A string, number, function, or table to be logged
--! @note A logged function will just give the function pointer, not the actual function code.
function debugger.log(msg)
	if (type(msg) == "table") then
		for key, val in pairs(msg) do
			debugger.log('{')
			debugger.log(key)
			debugger.log(':')
			debugger.log(val)
			debugger.log('}')
		end
	else
	   sys.exec("logger -t luci \"" .. tostring(msg) .. '"')
	end
end

return debugger

