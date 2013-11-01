--! @file debug

local sys = require "luci.sys"
local type, tostring = type, tostring

module "luci.commotion.debugger"

local debugger = {}


--! @name log
--! @brief Outputs a message to logread tagged with the string "luci" 
--! @param msg A string, number, or table to be logged
function debugger.log(msg)
	if (type(msg) == "table") then
		for key, val in pairs(msg) do
			log('{')
			log(key)
			log(':')
			log(val)
			log('}')
		end
	else
	   sys.exec("logger -t luci \"" .. tostring(msg) .. '"')
	end
end

return debugger

