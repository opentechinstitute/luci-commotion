local cursor = require "luci.model.uci".cursor()

local d = Delegator()
d.allow_finish = true
d.allow_back = true
d.allow_cancel = false
d.allow_reset = true

d:add("Node Settings", "commotion/basic_ns")
d:add("Mesh Network", "commotion/basic_mn")
d:add("Wireless Network", "commotion/basic_wn")
d:add("Additional Network Interfaces", "commotion/basic_ani")

function d.on_done()
end

return d
