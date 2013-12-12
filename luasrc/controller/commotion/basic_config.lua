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

HUGE Thanks to the niu suite!!!
]]--
--[[
   Copyright (C) 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module ("luci.controller.commotion.basic_config", package.seeall)
local db = require "luci.commotion.debugger"

function index()

   entry({"admin", "commotion"}, alias("admin", "commotion", "basic"), translate("Commotion"), 20)

   local page  = node()
   page.lock   = true
   page.target = alias("commotion")
   page.subindex = true
   page.index = false

   local root = node()
   if not root.lock then
	  root.target = alias("commotion")
	  root.index = true
   end

   
   local QS = require "luci.commotion.setup_wizard"

   local redir = luci.http.formvalue("redir", true) or
	  luci.dispatcher.build_url(unpack(luci.dispatcher.context.request))

   cnfm = entry({"admin", "commotion", "confirm"}, call("action_changes"), translate("Confirm"), 40)
   cnfm.query = {redir=redir}
   cnfm.hidden = true

   rvt = entry({"admin", "commotion", "revert"}, call("action_revert"))
   rvt.query = {redir=redir}
   rvt.hidden = true

   sva = entry({"admin", "commotion", "saveapply"}, call("action_apply"))
   sva.query = {redir=redir}
   sva.hidden = true
   
   if QS.status() then
	  entry({"commotion"}, alias("commotion", "setup_wizard"))

	  local confirm = {on_success_to={"admin", "commotion", "confirm"}}
	  entry({"commotion", "setup_wizard"}, cbi("commotion/setup_wizard", confirm), translate("Basic Configuration"), 15).hidden=true

   else
	  entry({"commotion"}, alias("apps"))
	  --Create regular "Basic Config" menu.
	  entry({"admin", "commotion", "basic"}, alias("admin", "commotion", "basic", "node_settings"), translate("Basic Configuration"), 25).index = true
	  
	  --No Subsection for Node Settings?
	  entry({"admin", "commotion", "basic", "node_settings"}, cbi("commotion/basic_ns", {hideapplybtn=true, hideresetbtn=true}), translate("Node Settings"), 25).subsection=true
	  
	  --Subsection Network Settings
	  entry({"admin", "commotion", "basic", "network_settings"}, alias("admin", "commotion", "basic", "mesh_network"), translate("Network Settings"), 30).subsection=true
	  entry({"admin", "commotion", "basic", "mesh_network"}, cbi("commotion/basic_mn", {hideapplybtn=true, hideresetbtn=true}), translate("Mesh Network"), 40)
	  entry({"admin", "commotion", "basic", "wireless_network"}, cbi("commotion/basic_wn", {hideapplybtn=true, hideresetbtn=true}), translate("Wireless Network"), 50)
	  entry({"admin", "commotion", "basic", "addtl_net_ifaces"}, cbi("commotion/basic_ani", {hideapplybtn=true, hideresetbtn=true}), translate("Additional Netork Interfaces"), 60)

   end
end

function action_changes()
   local uci = require "luci.model.uci".cursor()
   local changes = uci:changes()
   
   luci.template.render("commotion/confirm", {
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

	luci.template.render("commotion/revert", {
		changes = next(changes) and changes
	})
end
