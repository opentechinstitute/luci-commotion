local cursor = require "luci.model.uci".cursor()

local d = Delegator()
d.allow_finish = true
d.allow_back = true
d.allow_cancel = true
d.allow_reset = true
d.template = "cbi/commotion/delegator"

function d.on_cancel()
   return true
end

d:add("Node Settings", "commotion/basic_ns")
d:add("Mesh Network", "commotion/basic_mn")
d:add("Wireless Network", "commotion/basic_wn")
d:add("Configuration Complete", "commotion/basic_done")
d:add("Additional Network Interfaces", "commotion/basic_ani")


function d.parse(self, ...)
   local form = luci.http.formvalue()
   local db = require "luci.commotion.debugger"
   local page = form.sw_page
   if page ~= nil then
	  db.log("page["..page.."]")
	  d.current = page
	  if page == '' then
		 db.log("EMPTY")
		 d.current = nil
		 s.active = self.chain[1]
	  end
   end
   return Delegator.parse(self, ...)
end


--[[function d.get_next(self, state)
   local form = luci.http.formvalue()
   local page = form.sw_page
   if page then
	  return d:get(state)
   else
	  return Delegator.get_next(self, state)
   end
   end]]--

return d
