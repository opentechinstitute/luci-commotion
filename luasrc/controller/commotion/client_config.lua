--[[
LuCI - Lua Development Framework

Copyright 2013 - Seamus Tuohy <s2e@opentechinstitute.org>

With Thanks to the niu suite built by Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module "luci.controller.commotion.client_config"

function index()
   entry({"admin", "commotion", "client"}, alias("admin", "commotion", "client", "welcome_page"), translate("Client Controls"), 20)
   entry({"admin", "commotion", "client", "welcome_page"}, cbi("commotion/client_wp", {hideapplybtn=true, hideresetbtn=true}), translate("Welcome Page"), 30).index = true
   entry({"admin", "commotion", "client", "bandwidth_controls"}, cbi("commotion/client_bc", {hideapplybtn=true, hideresetbtn=true}), translate("Bandwidth Controls"), 40)

end
