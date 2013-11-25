local cursor = require "luci.model.uci".cursor()

local d = Delegator()
d.allow_finish = false
d.allow_back = true
d.allow_cancel = false
d.allow_reset = true

d:add("Node Settings", "commotion/basic_ns")
d:add("Network Settings", "commotion/basic_nets")
d:add("Mesh Network", "commotion/basic_mn")
d:add("Wireless Network", "commotion/basic_wn")

function d.on_done()
   --Here he wave the cursor commit all the places required earler from the confirmation page.
--	cursor:commit("network")
--	cursor:commit("wireless")
end

return d
