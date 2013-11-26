--[[
LuCI - Lua Development Framework

Copyright 2013 - Seamus Tuohy <s2e@opentechinstitute.org>

With Thanks to the niu suite built by Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module "luci.controller.commotion.basic_config"

function index()
   local QS = require "luci.commotion.quickstart"

   if QS.status() then
	  local confirm = {on_success_to={"admin", "commotion", "confirm_config"}}
	  entry({"admin", "commotion", "confirm_config"}, cbi("commotion/confirm_config"), translate("Confirm your Changes"))
	  entry({"admin", "commotion", "quickstart"}, cbi("commotion/quickstart", confirm), translate("Basic Configuration"), 15)
   else
	  --Create regular "Basic Config" menu.
	  entry({"admin", "commotion", "basic"}, alias({"admin", "commotion", "basic", "node_settings"}), translate("Basic Configuration"), 10).index = true
	  
	  entry({"admin", "commotion", "basic", "node_settings"}, cbi("commotion/basic_ns"), translate("Node Settings"), 20)

	  entry({"admin", "commotion", "basic", "network_settings"}, alias({"admin", "commotion", "basic", "mesh_network"}), translate("Network Settings"), 30)

	  entry({"admin", "commotion", "basic", "mesh_network"}, cbi("commotion/basic_mn"), translate("Mesh Network"), 40)

	  entry({"admin", "commotion", "basic", "wireless_network"}, cbi("commotion/basic_wn"), translate("Wireless Network"), 50)

	  entry({"admin", "commotion", "basic", "addtl_net_ifaces"}, cbi("commotion/basic_ani"), translate("Additional Netork Interfaces"), 60)

   end
end
