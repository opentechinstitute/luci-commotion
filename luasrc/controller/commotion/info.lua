--[[
LuCI - Lua Development Framework

Copyright 2013 - Seamus Tuohy <s2e@opentechinstitute.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module "luci.controller.commotion.info"

function index()
   entry({"admin", "commotion", "client"}, alias("admin", "commotion", "client", "welcome_page"), translate("Client Controls"), 30)

   entry({"commotion", "about"}, template("commotion/about"), translate("About")).hidden = true
   entry({"commotion", "help"}, template("commotion/help"), translate("Help")).hidden = true
   entry({"commotion", "license"}, template("commotion/license"), translate("License")).hidden = true
end
