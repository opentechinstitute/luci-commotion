local cursor = require "luci.model.uci".cursor()

local d = Delegator()
d.allow_finish = true
d.allow_back = true
d.allow_cancel = true
d.allow_reset = true
d.template = "cbi/commotion/delegator"
function d.on_cancel()
--   d.nodes["Additional Network Interfaces"] = nil
   return true
end

d:add("Node Settings", "commotion/basic_ns")
d:add("Mesh Network", "commotion/basic_mn")
d:add("Wireless Network", "commotion/basic_wn")
d:add("Configuration Complete", "commotion/basic_done")
d:add("Additional Network Interfaces", "commotion/basic_ani")

function d.on_done()
end

return d
