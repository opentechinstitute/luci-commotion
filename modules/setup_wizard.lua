module "luci.commotion.setup_wizard"

local SW = {}

--! @name status
--! @brief Checks the status of the startup wizard
--! @return true if on, false if completed
--! @TODO IMPLEMENT THIS: Currently placeholder
function SW.status()
   local uci = require "luci.model.cui".cursor()
   if uci:get("setup_wizard", "settings", "enabled") == "1" then
	  return true
   else
	  return false
   end
end

return SW
