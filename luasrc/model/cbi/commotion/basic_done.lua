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

m = Map("system", translate("Basic Configuration Complete!"), translate("You have completed all of the required steps to configure this mesh node."))
m.skip_to_end = true

s = m:section(SimpleSection, "stuff", translate("If you would like to configure additional network interfaces on this node, click the next button to continue to Additional Network Settings below. Otherwise click the Finish button."))
s.anonymous = true
s.title = nil

return m
