--[[
LuCI - Lua Development Framework

Copyright 2013 - Seamus Tuohy <s2e@opentechinstitute.org>

With Thanks to the niu suite built by Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module ("luci.controller.commotion.status_config", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/olsrd") then
		return
	end

        local page  = node("admin", "commotion", "status")                                                    
        page.target = template("commotion/status")                                                                      
        page.title  = _(translate("Commotion Status"))
        page.subindex = true                                           
                                                                                 
        local page  = node("admin", "commotion", "status", "nearby_md")       
        page.target = call("action_neigh")                                     
	-- template("nearby_md")
        page.title  = _(translate("Nearby Mesh Devices"))
        page.subindex = true                                                                 
        page.order  = 5

        local page  = node("admin", "commotion", "status", "mesh_viz")
        page.target = call("action_neigh")                                                           
        -- template("mesh_viz")                                                                     
        page.title  = _(translate("Mesh Visualizer"))
        page.subindex = true                                                                                                                                            
        page.order  = 10

        local page  = node("admin", "commotion", "status", "conn_clnts")
        page.target = call("action_neigh")                                                           
        -- template("conn_clnts")                                                                     
        page.title  = _(translate("Connected Clients"))
        page.subindex = true                                                                                                                                            
        page.order  = 5

        local page  = node("admin", "commotion", "status", "dbg_rpt")
        page.target = call("action_neigh")                                                           
        -- template("dbg_rpt")                                                                     
        page.title  = _(translate("Debug Report"))
        page.subindex = true                                                                                                                                            
        page.order  = 5
end

function action_neigh(json)
        local data = fetch_txtinfo("links")
        if not data or not data.Links then
                luci.template.render("status-olsr/error_olsr")
                return nil
        end
-- table.sort currently breaks nearby_md
--        table.sort(data.Links, compare_links)

                                                                                                                                                                        
        luci.template.render("commotion/nearby_md", {links=data.Links})
end

local function compare_links(a, b)
        local c = tonumber(a.Cost)
        local d = tonumber(b.Cost)

        if not c or c == 0 then
                return false
        end

        if not d or d == 0 then
                return true
        end
        return c < d
end

-- Internal
function fetch_txtinfo(otable)
	require("luci.sys")
	local uci = require "luci.model.uci".cursor_state()
	local resolve = uci:get("luci_olsr", "general", "resolve")
	otable = otable or ""
 	local rawdata = luci.sys.httpget("http://127.0.0.1:2006/"..otable)
 	local rawdatav6 = luci.sys.httpget("http://[::1]:2006/"..otable)
	local data = {}
	local dataindex = 0
	local name = ""
	local defaultgw

	if #rawdata ~= 0 then
		local tables = luci.util.split(luci.util.trim(rawdata), "\r?\n\r?\n", nil, true)

		if otable == "links" then
			local route = {}
			luci.sys.net.routes(function(r) if r.dest:prefix() == 0 then defaultgw = r.gateway:string() end end)
		end

		for i, tbl in ipairs(tables) do
			local lines = luci.util.split(tbl, "\r?\n", nil, true)
			name  = table.remove(lines, 1):sub(8)
			local keys  = luci.util.split(table.remove(lines, 1), "\t")
			local split = #keys - 1
			if not data[name] then
				data[name] = {}
			end

			for j, line in ipairs(lines) do
				dataindex = ( dataindex + 1 )
				di = dataindex
				local fields = luci.util.split(line, "\t", split)
				data[name][di] = {}
				for k, key in pairs(keys) do
					if key == "Remote IP" or key == "Dest. IP" or key == "Gateway IP" or key == "Gateway" then
						data[name][di][key] = fields[k]
						if resolve == "1" then
							hostname = nixio.getnameinfo(fields[k], "inet")
							if hostname then
								data[name][di]["Hostname"] = hostname
							end
						end
						if key == "Remote IP" and defaultgw then
							if defaultgw == fields[k] then
								data[name][di]["defaultgw"] = 1
							end
						end
					elseif key == "Local IP" then
						data[name][di][key] = fields[k]
						data[name][di]['Local Device'] = fields[k]
						uci:foreach("network", "interface",
							function(s)
								localip = string.gsub(fields[k], '	', '')
								if s.ipaddr == localip then
									data[name][di]['Local Device'] = s['.name'] or interface
								end
							end)
					elseif key == "Interface" then
						data[name][di][key] = fields[k]
						uci:foreach("network", "interface",
						function(s)
							interface = string.gsub(fields[k], '	', '')
							if s.ifname == interface then
								data[name][di][key] = s['.name'] or interface
							end
						end)
					else
					    data[name][di][key] = fields[k]
			        end
				end
				if data[name][di].Linkcost then
					data[name][di].LinkQuality,
					data[name][di].NLQ,
					data[name][di].ETX =
					data[name][di].Linkcost:match("([%w.]+)/([%w.]+)[%s]+([%w.]+)")
				end
			end
		end
	end

	if #rawdatav6 ~= 0 then
		local tables = luci.util.split(luci.util.trim(rawdatav6), "\r?\n\r?\n", nil, true)
		for i, tbl in ipairs(tables) do
			local lines = luci.util.split(tbl, "\r?\n", nil, true)
			name  = table.remove(lines, 1):sub(8)
			local keys  = luci.util.split(table.remove(lines, 1), "\t")
			local split = #keys - 1
			if not data[name] then
				data[name] = {}
			end
			for j, line in ipairs(lines) do
				dataindex = ( dataindex + 1 )
				di = dataindex
				local fields = luci.util.split(line, "\t", split)
				data[name][di] = {}
				for k, key in pairs(keys) do
					if key == "Remote IP" then
						data[name][di][key] = "[" .. fields[k] .. "]"
						if resolve == "1" then
							hostname = nixio.getnameinfo(fields[k], "inet6")
							if hostname then
								data[name][di]["Hostname"] = hostname
							end
						end
					elseif key == "Local IP" then
						data[name][di][key] = fields[k]
						data[name][di]['Local Device'] = fields[k]
						uci:foreach("network", "interface",
						function(s)
							local localip = string.gsub(fields[k], '	', ''):upper()
							if s.ip6addr then
								s.ip6addr = luci.ip.IPv6(s.ip6addr):string()
								local ip6addr = string.gsub(s.ip6addr, '\/.*', '')
								if ip6addr == localip then
									data[name][di]['Local Device'] = s['.name'] or s.interface
								end
							end
						end)
					elseif key == "Dest. IP" then
						data[name][di][key] = "[" .. fields[k] .. "]"
					elseif key == "Last hop IP" then
						data[name][di][key] = "[" .. fields[k] .. "]"
					elseif key == "IP address" then
						data[name][di][key] = "[" .. fields[k] .. "]"
					elseif key == "Gateway" then
						data[name][di][key] = "[" .. fields[k] .. "]"
					else
						data[name][di][key] = fields[k]
					end
				end

				if data[name][di].Linkcost then
					data[name][di].LinkQuality,
					data[name][di].NLQ,
					data[name][di].ETX =
					data[name][di].Linkcost:match("([%w.]+)/([%w.]+)[%s]+([%w.]+)")
				end
			end
		end
	end


	if data then
	    return data
	end
end
