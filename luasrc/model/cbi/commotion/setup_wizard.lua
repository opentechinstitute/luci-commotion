--[[
Copyright (C) 2013 Seamus Tuohy 

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
]]--
local db = require "luci.commotion.debugger"
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
   local page = form.sw_page
   if page ~= nil then
	  d.current = page
	  if page == '' then
		 d.current = nil
		 s.active = self.chain[1]
	  end
   end
   return Delegator.parse(self, ...)
end


function d.get_next(self, state)
   local form = luci.http.formvalue()
   local page = form.sw_page
   db.log("is there a page")
   db.log(page)
   if page then
	  for k, v in ipairs(self.chain) do
		 if v == state then
			return self.chain[k]
		 end
	  end
   else
	  return Delegator.get_next(self, state)
   end
end

return d
