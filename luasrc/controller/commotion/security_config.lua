--[[
LuCI - Lua Development Framework

Copyright 2013 - Seamus Tuohy <s2e@opentechinstitute.org>

With Thanks to the niu suite built by Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module "luci.controller.commotion.security_config"

function index()   
	  entry({"admin", "commotion", "security"}, alias("admin", "commotion", "security", "passwords"), translate("Security"), 40).index = true

	  entry({"admin", "commotion", "security", "passwords"}, cbi("commotion/security_pass"), translate("Passwords"), 50)

	  entry({"admin", "commotion", "security", "shared_mesh_keychain"}, cbi("commotion/security_smk"), translate("Shared Mesh Keychain"), 60)
end
