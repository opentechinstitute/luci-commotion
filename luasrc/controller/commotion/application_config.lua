--[[
LuCI - Lua Development Framework

Copyright 2013 - Seamus Tuohy <s2e@opentechinstitute.org>

With Thanks to the niu suite built by Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module "luci.controller.commotion.application_config"

function index()
	  entry({"admin", "commotion", "basic"}, alias({"admin", "commotion", "application", "list"}), translate("Applications"), 30).index = true

	  entry({"admin", "commotion", "application", "list"}, cbi("commotion/application_list"), translate("List"), 40)
	  
	  entry({"admin", "commotion", "application", "add"}, cbi("commotion/application_add"), translate("Add"), 50)
	  
	  entry({"admin", "commotion", "application", "settings"}, cbi("commotion/application_set"), translate("Settings"), 60)
end
