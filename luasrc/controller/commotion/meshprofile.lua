--[[
LuCI - Lua Configuration Interface

Copyright 2013 Open Technology Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/License-2.0
]]--

module("luci.controller.commotion.meshprofile", package.seeall)

function index()
	require("luci.i18n").loadc("commotion")
	local i18n = luci.i18n.translate

-- REQUIRE AUTH --
	entry({"admin", "commotion", "meshprofile"}, template("commotion/meshprofile"), "Mesh Profiles", 10).dependent=false
end

function generate_page()
	luci.http.prepare_content("text/plain")
	value = "meat"
	luci.dispatcher.template("commotion/meshprofile", value = value)
end
