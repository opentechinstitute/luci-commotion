module "luci.commotion.startup_wizard"

local SW = {}

--! @name status
--! @brief Checks the status of the startup wizard
--! @return true if on, false if completed
--! @TODO IMPLEMENT THIS: Currently placeholder
function SW.status()
   return false
   --return true
end

return SW
