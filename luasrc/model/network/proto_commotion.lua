--[[
LuCI - Network model - 3G, PPP, PPtP, PPPoE and PPPoA protocol extension

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]--

local netmod = luci.model.network

local p = "commotionif"

local proto = netmod:register_protocol(p)

function proto.get_i18n(self)
   if p == "commotionif" then
	  return luci.i18n.translate("Commotion Interface")
   end
end

function proto.ifname(self)
   return p .. "-" .. self.sid
end

-- The Following function is disabled until we have a package the interface relies on
--function proto.opkg_package(self)
--   if p == "commotionif" then
--	  return commotionbase
--   end
--end

-- The following function is disabled because it refers to depreciated shell script
--function proto.is_installed(self)
--   return nixio.fs.access("/lib/network/commotion.sh")
--end

function proto.is_virtual(self)
   return true
end

function proto.get_interfaces(self)
   if self:is_floating() then
	  return nil
   else
	  return netmod.protocol.get_interfaces(self)
   end
end

function proto.contains_interface(self, ifc)
   if self:is_floating() then
	  return (netmod:ifnameof(ifc) == self:ifname())
   else
	  return netmod.protocol.contains_interface(self, ifc)
   end
end

netmod:register_pattern_virtual("^%s-%%w" % p)
