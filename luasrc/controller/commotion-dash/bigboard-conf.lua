--[[
LuCI - Lua Configuration Interface

Copyright 2011 Josh King <joshking at newamerica dot net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.commotion-dash.bigboard-conf", package.seeall)

require "luci.model.uci"
require "luci.fs"
require "luci.sys"
require "commotion_helpers"

local dashConfig = "/etc/config/commotion-dash"

function index()
	require("luci.i18n").loadc("commotion")
	local i18n = luci.i18n.translate
	local uci = luci.model.uci.cursor()

--[[ to do: check for jsoninfo plugin 
	check for dashboard plugin
	See: wiki.openwrt.org/doc/techref/uci ]]--
	if uci:get_all('commotion-dash') then
		uci:get_all('olsrd')
		local flag=false
		uci:foreach('olsrd', 'LoadPlugin',
				function(s)
					if string.find(s.library, 'olsrd_jsoninfo') then
						flag=true
					end
				end)
		if flag==true then
			entry({"admin", "commotion", "bigboard-conf_submit"}, call("ifprocess"))
			entry({"admin", "commotion", "bigboard-conf"}, call("main"), translate("BigBoard Configuration"), 20).dependent=false
		else
			log("Can't run Commotion-Dashboard. Install olsrd jsoninfo plugin.")
		end
	end
end

function main(ERR)
	local jsonInfo={}	
        local uci = luci.model.uci.cursor()
	
--[[ Config file format
config dashboard
	option enabled 'true'
	option gatherer 'x.x.x.x'
]]--
	uci:get_all('commotion-dash')
	uci:foreach('commotion-dash', 'dashboard',
		function(s)
				jsonInfo[s['.name']] = {}
				jsonInfo[s['.name']]['name'] = s['.name']
				jsonInfo[s['.name']]['enabled'] = s.enabled
				jsonInfo[s['.name']]['gatherer'] = s.gatherer
		end)
	luci.http.prepare_content("text/html")
	luci.template.render("commotion-dash/bigboard-conf", {jsonInfo = jsonInfo, ERR = ERR})
end

function ifprocess()
	local values = luci.http.formvalue()
	local ERR = nil
	--[[ sanitize inputs ]]--
	for k,v in pairs(values) do
log("sanitizing values: " .. values[k] .. ", " .. v)
		values[k] = url_encode(v)
	end
	
	--[[ validate destination address ]]--
	if is_ip4addr(values['gatherer_ip']) == true or 
		is_ip4addr_cidr(values['gatherer_ip']) == true or 
		is_hostname(values['gatherer_ip']) == true then
	else
		ERR = 'ERROR: invalid IP or site address' .. values['gatherer_ip']
		log("validating inputs " .. values['gatherer_ip'])
	end
	--if bbOnOff does not work during testing try with ~= ''
	if values['bbOnOff'] ~= nil then
		log("Commotion-Dashboard: Enabling network stats submission...")
		log("Commotion-Dashboard: Setting " .. values['gatherer_ip'] .. "as network stats collector")
		if ERR == nil then
			local uci = luci.model.uci.cursor()
	--[[ To do: Allow people to turn off data collection ]]--
			uci:set("commotion-dash", values['dashName'], "enabled", values['bbOnOff'])
			uci:set("commotion-dash", values['dashName'], "gatherer", values['gatherer_ip'])
			uci:commit('commotion-dash')
			uci:save('commotion-dash')
		end	
	else
		log("Disabling Commotion-Dashboard")
		local uci = luci.model.uci.cursor()
		uci:set("commotion-dash", values["dashName"], 'enabled', 'false')
		uci:set("commotion-dash", values["dashName"], 'gatherer', 'x.x.x.x')
		uci:commit('commotion-dash')
		uci:save('commotion-dash')
		ERR = nil
	end
	main(ERR)
end

function getConfType(conf, type)
	local curs=uci.cursor()
	local ifce={}
	curs:foreach(conf,type,function(s) ifce[s[".index"]]=s end)
	return ifce
end

