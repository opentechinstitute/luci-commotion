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

module "luci.controller.commotion.security_config"

function index()
	  entry({"admin", "commotion", "security"}, alias("admin", "commotion", "security", "passwords"), translate("Security"), 40).index = true

	  entry({"admin", "commotion", "security", "passwords"}, cbi("commotion/security_pass", {hideapplybtn=true, hideresetbtn=true}), translate("Passwords"), 50).subsection=true

	  entry({"admin", "commotion", "security", "shared_mesh_keychain"}, cbi("commotion/security_smk", {hideapplybtn=true, hideresetbtn=true}), translate("Shared Mesh Keychain"), 60).subsection=true 
end

