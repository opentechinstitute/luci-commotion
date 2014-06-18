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

local http = require "luci.http"
local disp = require "luci.dispatcher"

module "luci.commotion.ccbi"

local ccbi = {}

--! @name flag_write
--! @brief Modifies cbi's flag write function to set section.changed.
--! @note Called with flagname.remove=ccbi.flag_remove
--! @param self the self object of the flag. You should not have to set this explicitly unless you call it directly, which you should not do. (see note above)
--! @param section the section object of the flag. You should not have to set this explicitly unless you call it directly, which you should not do. (see note above)
function ccbi.flag_write(self, section, fvalue)
   value = self.map:get(section, self.option)
   if value ~= fvalue then
	  self.section.changed = true
	  return self.map:set(section, self.option, fvalue)
   end
end

--! @name flag_remove
--! @brief Modifies the flag remove function to set section.changed
--! @note called like flagname.remove=ccbi.flag_remove
--! @param self the self object of the flag. You should not have to set this explicitly unless you call it directly, which you should not do. (see note above)
--! @param section the section object of the flag. You should not have to set this explicitly unless you call it directly, which you should not do. (see note above)
function ccbi.flag_remove(self, section)
   value = self.map:get(section, self.option)
   if value ~= self.disabled then
	  self.section.changed = true
	  return self.map:del(section, self.option)
   end
end

--! @name flag_off
--! @brief Modifies the flag remove function to set section.changed and set the value to 0 instead of removal
--! @note called like flagname.remove=ccbi.flag_off
--! @param self the self object of the flag. You should not have to set this explicitly unless you call it directly, which you should not do. (see note above)
--! @param section the section object of the flag. You should not have to set this explicitly unless you call it directly, which you should not do. (see note above)
function ccbi.flag_off(self, section)
   value = self.map:get(section, self.option)
   if value ~= self.disabled then
	  self.section.changed = true
	  return self.map:set(section, self.option, '0')
   end
end

--! @name conf_page
--! @brief redirects cbi Maps on_after_save value to a confirmation page instead of letting a user save/save-apply directly on a page... inconvienence for usability
--! @note If you use this function it reduces confusion to remove the save&apply button. Do this in the page's cbi call in the  entry function in your index as such. cbi("your/map", {hideapplybtn=true})
--! @note call as such m.on_after_save = conf_page
--! @param self the map object. You should not have to set this explicitly unless you call it directly, which you should not do. (see note above)
--! @return nil (Redirects a user to the confirmation page if the map is changed and the form is NOT invalid, or been requested not to with map.proceed.)
function ccbi.conf_page(self)
   FORM_INVALID = -1
   if self.changed and self.state ~= FORM_INVALID and not self.proceed then
	  http.redirect(disp.build_url("admin", "commotion", "confirm"))
   end
end


return ccbi
