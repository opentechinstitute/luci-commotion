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
]]--
module ("luci.controller.commotion.status_config", package.seeall)
local sys = require "luci.sys"
local util = require "luci.util"
function index()

   entry({"admin", "commotion", "status"}, alias("admin", "commotion", "status", "nearby_md"), translate("Status"), 10)
	entry({"admin", "commotion", "status", "nearby_md"}, call("action_neigh")).hidden = true
	entry({"admin", "commotion", "status", "mesh_viz"}, call("viz")).hidden = true
	entry({"admin", "commotion", "status", "conn_clnts"}, call("conn_clnts")).hidden = true
	if sys.exec("opkg list-installed | grep luci-commotion-debug") then
	   entry({"admin", "commotion", "status", "dbg_rpt"}, call("dbg_rpt")).hidden = true
	end	
end


function status_builder(page, assets, active_tab)
   ifaces = {{name="interface one",
			  status="On",
			  sec="Secured",
			  conn="22"}}
   gw = "Yes"
   luci.template.render("commotion/status", {ifaces=ifaces, gateway_provided=gw, page=page, assets=assets, active_tab=active_tab})
end

function viz()
   status_builder("commotion/viz", nil, "mesh_visualizer")
end

function conn_clnts()
--[[
client_id=0
ip=103.114.207.62
mac=10:0b:a9:ca:7b:14
added=1386540225
active=1386540231
duration=6
token=f9b38643
state=Authenticated
downloaded=2
avg_down_speed=3.212
uploaded=1
avg_up_speed=1.54133
]]--
   local convert = function(x)
	  return tostring(tonumber(x)*60).." "..translate(minutes)
   end
   local function total_kB(a, b) return tostring(a+b).." kByte" end
   local function total_kb(a, b) return tostring(a+b).." kbit/s" end
   local clients = {}
   i = 0
   for line in util.execi("ndsctl status") do
	  if string.match(line, "^%d*$") then
		 i = i + 1
	  end
	  string.gsub(i, "^(.-)=(.*)$",
			   function(key, val)
				  clients[i][key] = val
			   end)
	  if clients[i] ~= nil then
		 clients[i].curr_conn=false
		 clients[i].duration = convert(clients[i].duration)
		 clients[i].bnd_wdth = total_kB(clients[i].downloaded, clients[i].uploaded)
		 clients[i].avg_spd = total_kb(clients[i].avg_down_speed, clients[i].avg_up_speed)
	  end
   end
   status_builder("commotion/conn_clients", {clients=clients}, "connected_clients")
end

function dbg_rpt()
   status_builder("commotion/debug", nil, "debug_report")
end

function action_neigh(json)
        local data = fetch_txtinfo("links")
        if not data or not data.Links then
                status_builder("commotion/error_olsr", nil, "nearby_devices")
                return nil
        end
-- table.sort currently breaks nearby_md
--        table.sort(data.Links, compare_links)
		
        status_builder("commotion/nearby_md", {links=data.Links}, "nearby_devices")
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
