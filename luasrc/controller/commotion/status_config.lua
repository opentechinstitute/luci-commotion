--[[
LuCI - Lua Development Framework

Copyright 2013 - Seamus Tuohy <s2e@opentechinstitute.org>

With Thanks to the niu suite built by Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module "luci.controller.commotion.status_config"

function index()
	  entry({"admin", "commotion", "status"}, template("commotion/status"), translate("Staus"), 1)

	  entry({"admin", "commotion", "status", "nearby_md"}, template("commotion/nearby_md"), translate("Nearby Mesh Devices"))
	  entry({"admin", "commotion", "status", "mesh_viz"}, template("commotion/mesh_viz"), translate("Mesh Visualizer"))
	  entry({"admin", "commotion", "status", "conn_clnts"}, template("commotion/conn_clnts"), translate("Connected Clients"))
	  entry({"admin", "commotion", "status", "dbg_rpt"}, template("commotion/dbg_rpt"), translate("Debug Report"))
	  
end
