--[[
LuCI - Lua Development Framework Modifications

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
	  local confirm = {on_success_to={"admin", "commotion", "quickstart", "confirm"}}
	  entry({"admin", "commotion", "confirm_config"}, cbi("commotion/confirm_config"), translate("Confirm your Changes"))
	  entry({"admin", "commotion", "quickstart"}, cbi("commotion/quickstart", confirm), translate("Basic Configuration"), 15)
   else
	  --Create regular "Basic Config" menu.
	  entry({"admin", "commotion", "basic"}, alias("admin", "commotion", "basic", "node_settings"), translate("Basic Configuration"), 10).index = true
	  entry({"admin", "commotion", "basic", "node_settings"}, cbi("commotion/basic_ns"), translate("Node Settings"), 20)
	  entry({"admin", "commotion", "basic", "network_settings"}, alias("admin", "commotion", "basic", "mesh_network"), translate("Network Settings"), 30)
	  entry({"admin", "commotion", "basic", "mesh_network"}, cbi("commotion/basic_mn"), translate("Mesh Network"), 40)
	  entry({"admin", "commotion", "basic", "wireless_network"}, cbi("commotion/basic_wn"), translate("Wireless Network"), 50)
	  entry({"admin", "commotion", "basic", "addtl_net_ifaces"}, cbi("commotion/basic_ani"), translate("Additional Netork Interfaces"), 60)
   end
end

function index()
	local redir = luci.http.formvalue("redir", true) or
	  luci.dispatcher.build_url(unpack(luci.dispatcher.context.request))

	entry({"admin", "commotion", "quickstart", "confirm"}, call("action_changes"), _("Changes"), 40).query = {redir=redir}
	entry({"admin", "uci", "revert"}, call("action_revert"), _("Revert"), 30).query = {redir=redir}
	entry({"admin", "uci", "apply"}, call("action_apply"), _("Apply"), 20).query = {redir=redir}
	entry({"admin", "uci", "saveapply"}, call("action_apply"), _("Save &#38; Apply"), 10).query = {redir=redir}
end

function action_changes()
	local uci = luci.model.uci.cursor()
	local changes = uci:changes()

	luci.template.render("admin_uci/changes", {
		changes = next(changes) and changes
	})
end

function action_apply()
	local path = luci.dispatcher.context.path
	local uci = luci.model.uci.cursor()
	local changes = uci:changes()
	local reload = {}

	-- Collect files to be applied and commit changes
	for r, tbl in pairs(changes) do
		table.insert(reload, r)
		if path[#path] ~= "apply" then
			uci:load(r)
			uci:commit(r)
			uci:unload(r)
		end
	end

	luci.template.render("admin_uci/apply", {
		changes = next(changes) and changes,
		configs = reload
	})
end

function action_revert()
	local uci = luci.model.uci.cursor()
	local changes = uci:changes()

	-- Collect files to be reverted
	for r, tbl in pairs(changes) do
		uci:load(r)
		uci:revert(r)
		uci:unload(r)
	end

	luci.template.render("admin_uci/revert", {
		changes = next(changes) and changes
	})
end
