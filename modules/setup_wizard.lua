
local require = require
local uci = require "luci.model.uci".cursor()
local db = require "luci.commotion.debugger"

module "luci.commotion.setup_wizard"

local SW = {}

--! @name status
--! @brief Checks the status of the startup wizard
--! @return true if on, false if completed
--! @TODO IMPLEMENT THIS: Currently placeholder
function SW.status()
   local enabled = uci:get("setup_wizard", "settings", "enabled")
   db.log(enabled)
   if enabled == "1" then
	  return true
   else
	  return false
   end
end

return SW
