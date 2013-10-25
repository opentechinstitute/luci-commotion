--! @file network

local sys = require "luci.sys"
local uci = require "luci.model.uci"
local string = string

module "luci.commotion.network"

local network = {}

--! @name
--! @brief
--! @param
--! @return
function network.list_ifaces()
  local r = {zone_to_iface = {}, iface_to_zone = {}}
  cursor = uci.cursor()
  cursor:foreach("network", "interface", 
    function(zone)
      if zone['.name'] == 'loopback' then return end
      local iface = sys.exec("ubus call network.interface." .. zone['.name'] .. " status |grep '\"device\"' | cut -d '\"' -f 4"):gsub("%s$","")
      r.zone_to_iface[zone['.name']]=iface
      r.iface_to_zone[iface]=zone['.name']
    end
  )
  return r
end



return network

