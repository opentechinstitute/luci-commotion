
local require = require
local uci = require "luci.model.uci".cursor()

module "luci.commotion.setup_wizard"

local SW = {}

--! @name status
--! @brief Checks the status of the startup wizard
--! @return true if on, false if completed
function SW.status()
   local enabled = uci:get("setup_wizard", "settings", "enabled")
   if enabled == "1" then
	  return true
   else
	  return false
   end
end

return SW
