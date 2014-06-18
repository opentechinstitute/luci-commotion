--[[
   Copyright (C) 2012 Dan Staples <danstaples@opentechinstitute.org>
   "with great annoyance provided by Seamus Tuohy"

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
module("luci.controller.commotion.apps_controller", package.seeall)

require "luci.model.uci"
require "luci.http"
require "luci.sys"
require "luci.fs"
local db  = require "luci.commotion.debugger"
local validate = require "luci.commotion.validate"
local dt = require "luci.cbi.datatypes"

function index()
  local uci = luci.model.uci.cursor()
  enabled = uci:get("applications", "settings", "disabled")
  
  --settings and menu-title always stay if installed.
	 entry({"admin", "commotion", "apps"}, alias("admin", "commotion", "apps", "list"), translate("Applications"), 30)
  entry({"admin", "commotion", "apps", "settings"}, cbi("commotion/app_settings", {hideapplybtn=true, hideresetbtn=true}), translate("Settings"), 50).subsection=true

 --remove all other menu's if not installed
  if enabled == "0" then
	 --public facing sections
	 entry({"apps"}, call("load_apps"), translate("Local Applications")).dependent=true
	 entry({"commotion", "index", "apps"}, call("load_apps"), translate("Local Applications"), 20).dependent=true
	 local unauth = uci:get("applications", "settings", "enable_unauth")
	 if unauth == "1" then
		entry({"apps", "add"}, call("add_app")).dependent=true
		entry({"apps", "add_submit"}, call("action_add")).dependent=true
	 end
	 entry({"admin", "commotion", "apps", "add_submit"}, call("action_add")).dependent=true


	 --menu based sections
	 entry({"admin","commotion","apps", "list"}, call("load_apps", {true}), translate("List"), 40).subsection=true
	 entry({"admin", "commotion", "apps", "add"}, call("add_app"), translate("Add"), 50).subsection=true
	 --Special pages for functions
	 entry({"admin", "commotion", "apps", "edit"}, call("admin_edit_app")).hidden=true
	 entry({"admin", "commotion", "apps", "edit_submit"}, call("action_edit")).hidden=true
	 entry({"admin", "commotion", "apps", "list", "judge"}, call("judge_app")).hidden=true
	 entry({"admin", "commotion", "apps", "judge"}, call("judge_app")).hidden=true
	 end
end

function judge_app()
   local action, app_id
   local uci = luci.model.uci.cursor()
   local uuid = luci.http.formvalue("uuid")
   local approved = luci.http.formvalue("approved")
   local dispatch = require "luci.dispatcher"
   uci:foreach("applications", "application",
			   function(app)
				  if (uuid == app.uuid) then
					 app_id = app['.name']
				  end
   end)
   if (not app_id) then
	  dispatch.error500("Application not found")
	  return
   end
   if approved ~= "delete" then
	  if (uci:set("applications", app_id, "approved", approved) and 
			 uci:set("applications", "known_apps", "known_apps") and
			 uci:set("applications", "known_apps", app_id, (approved == "1") and "approved" or "banned") and
			 uci:save('applications') and 
		  uci:commit('applications')) then
		 luci.http.status(200, "OK")
	  else
		 dispatch.error500("Could not judge app")
	  end
   else
	  uci_removed = uci:delete("applications", app_id)
	  uci:save('applications') 
	  uci:commit('applications')
	  if uci_removed then
	         if luci.fs.isfile("/etc/avahi/services/" .. app_id .. ".service") then
	              if (not luci.fs.unlink("/etc/avahi/services/" .. app_id .. ".service")) then
		           dispatch.error500("Failed to delete Avahi service file")
			   return
	              end
	         end
	         luci.http.status(200, "OK")
	  else
		 dispatch.error500("Could not judge app")
	  end
	  end
end

function action_edit()
   action_add({true})
end

function load_apps(admin_vars)
   local uuid, app
   local uci = require "luci.model.uci".cursor()
   local autoapprove = uci:get("applications","settings","autoapprove")
   local categories = {}
   if admin_vars then
	  categories = {banned={}, approved={}, new={}}
   end
   
   uci:foreach("applications", "application",
			   function(app)
				  if app.uuid and admin_vars then
					 if app.approved and app.approved == '1' then
						categories.approved[app.uuid] = app
					 elseif app.approved then
						categories.banned[app.uuid] = app
					 else
						categories.new[app.uuid] = app
					 end
				  else
					 if (app.approved and app.approved == '1') or (autoapprove == '1' and not app.approved) then
						if not categories.applications then categories.applications = {} end
						categories.applications[app.uuid] = app
					 end
				  end
   end)
   luci.template.render("commotion/apps_view", {categories=categories, admin_vars=admin_vars})
end

function add_app(error_info, bad_data)
   local uci = luci.model.uci.cursor()
   local cutil = require "luci.commotion.util"
   local encode = require "luci.commotion.encode"
   local type_tmpl = '<input type="checkbox" name="type" value="${type_escaped}" ${checked}/>${type}<br />'
   local type_categories = uci:get_list("applications","settings","category")
   local allowpermanent = uci:get("applications","settings","allowpermanent")
   local checkconnect = uci:get("applications","settings","checkconnect")
   local types_string = ''
   if (bad_data and bad_data.type) then
	  for i, type_category in pairs(type_categories) do
		 local match = nil
		 if (type(bad_data.type) == "table") then
			for i, app_type in pairs(bad_data.type) do
			   if (app_type == type_category) then match=true end
			end
		 else
			if (type_category == bad_data.type) then match=true end
		 end
		 if (match) then
			types_string = types_string .. cutil.tprintf(type_tmpl, {type=type_category, type_escaped=encode.html(type_category), checked="checked "})
		 else
			types_string = types_string .. cutil.tprintf(type_tmpl, {type=type_category, type_escaped=encode.html(type_category), checked=""})
		 end
	  end
   else
	  for i, type_category in pairs(type_categories) do
		 types_string = types_string .. cutil.tprintf(type_tmpl, {type=type_category, type_escaped=encode.html(type_category), checked=""})
	  end
   end
   luci.template.render("commotion/apps_form", {types_string=types_string, err=error_info, app=bad_data, page={type="add", action="/apps/add_submit", allowpermanent=allowpermanent, checkconnect=checkconnect}})
end

function admin_edit_app(error_info, bad_data)
   local UUID, app_data, types_string
   local cutil = require "luci.commotion.util"
   local encode = require "luci.commotion.encode"
   local uci = luci.model.uci.cursor()
   local dispatch = require "luci.dispatcher"
   local type_tmpl = '<input type="checkbox" name="type" value="${type_escaped}" ${checked}/>${type}<br />'
   local type_categories = uci:get_list("applications","settings","category")
   local allowpermanent = uci:get("applications","settings","allowpermanent")
   if (not bad_data) then
	  -- get app id from GET parameter
	  if (luci.http.formvalue("uuid") and luci.http.formvalue("uuid") ~= '') then
		 UUID = luci.http.formvalue("uuid")
	  else
		 dispatch.error500("No UUID given")
		 return
	  end
	  
	  -- get app data from UCI
	  uci:foreach("applications", "application",
				  function(app)
					 if (UUID == app.uuid) then
						app_data = app
					 end
	  end)
	  if (not app_data) then
		 dispatch.error500("No application found for given UUID")
		 return
	  end
   else
	  UUID = bad_data.uuid
	  app_data = bad_data
   end
   
   types_string = ''
   for i, type_category in pairs(type_categories) do
	  local match = nil
	  if (app_data.type) then
		 for i, app_type in pairs(app_data.type) do
			if (app_type == type_category) then match=true end
		 end
	  end
	  if (match) then
		 types_string = types_string .. cutil.tprintf(type_tmpl, {type=type_category, type_escaped=encode.html(type_category), checked="checked "})
	  else
		 types_string = types_string .. cutil.tprintf(type_tmpl, {type=type_category, type_escaped=encode.html(type_category), checked=""})
	  end
   end
   
   luci.template.render("commotion/apps_form", {types_string=types_string, app=app_data, err=error_info, page={type="edit", action="/apps/edit_submit", allowpermanent=allowpermanent}})
end

function action_add(edit_app)
   local UUID, values, tmpl, type_tmpl, service_type, app_types, service_string, service_file, signing_tmpl, signing_msg, resp, signature, fingerprint, deleted_uci, url
   local uci = luci.model.uci.cursor()
   local dispatch = require "luci.dispatcher"
   local encode = require "luci.commotion.encode"
   local cutil = require "luci.commotion.util"
   local luci_util = require "luci.util"
   local bad_data = {}
   local error_info = {}
   local lifetime = uci:get("applications","settings","lifetime") or 86400
   local allowpermanent = uci:get("applications","settings","allowpermanent")
   local autoapprove = uci:get("applications","settings","autoapprove")
   local checkconnect = uci:get("applications","settings","checkconnect")
   local uri = require "uri"
   
   values = {
	  name =  luci.http.formvalue("name"),
	  uri =  luci.http.formvalue("uri"),
	  port = luci.http.formvalue("port"),
	  icon =  luci.http.formvalue("icon"),
	  description =  luci.http.formvalue("description"),
	  ttl = luci.http.formvalue("ttl"),
	  --permanent = luci.http.formvalue("permanent"),
	  noconnect = '0',
	  protocol = 'IPv4',
	  localapp = '1' -- all manually created apps get a 'localapp' flag
   }
   
   -- ###########################################
   -- #           INPUT VALIDATION              #
   -- ###########################################
   for i, val in pairs({"name","uri","description","icon"}) do
	  if (not luci.http.formvalue(val) or luci.http.formvalue(val) == '') then
		 error_info[val] = "Missing value"
	  end
   end
   
   if not validate.app_name(values.name) then
	   error_info.name = "Invalid name; must be between 1 and 250 characters"
   end
   
   if not validate.app_description(values.description) then
	   error_info.description = "Invalid description; must be between 1 and 243 characters"
   end
   
   if not validate.app_uri(values.uri) then 
	 error_info.uri = "Invalid URI; must be valid IP address or URI less than 252 characters"
   end
   
   if not validate.app_icon(values.icon) then 
	 error_info.icon = "Invalid icon; must be valid URL or file path less than 251 characters"
   end
   
   if (values.port ~= '' and not dt.port(values.port)) then
	  error_info.port = "Invalid port number; must be between 1 and 65535"
   end
   
   if (values.ttl ~= '' and not validate.ttl(values.ttl)) then
	  error_info.ttl = "Invalid TTL value; must be integer greater than zero"
   end
   
   if (edit_app) then
	  if (luci.http.formvalue("approved") and luci.http.formvalue("approved") ~= '' and (tonumber(luci.http.formvalue("approved")) ~= 0 and tonumber(luci.http.formvalue("approved")) ~= 1)) then
		 dispatch.error500("Invalid approved value") -- fail since this shouldn't happen with a dropdown form
		 return
	  end
	  values.approved = luci.http.formvalue("approved")
   end
   
   if (luci.http.formvalue("permanent") and (luci.http.formvalue("permanent") ~= '1' or allowpermanent == '0')) then
	  dispatch.error500("Invalid permanent value")
	  return
   end
   
   if (luci.http.formvalue("uuid") and not dt.uciname(luci.http.formvalue("uuid"))) then
	  DIE("Invalid UUID value")
	  return
   end
   
   -- escape input strings
   for i, field in pairs(values) do
	  if (i ~= 'uri' and i ~= 'icon') then
		 values[i] = encode.html(field)
	  else
		 values[i] = encode.url(field)
	  end
	  if values[i]:len() > 254 then
		 error_info[i] = "Value too long"
	  end
   end
   
   -- make sure application types are within the set of approved categories on node
   if (luci.http.formvalue("type")) then
	   if (not validate.app_category(luci.http.formvalue("type"))) then
		   dispatch.error500("Invalid application type value")
		   return
	   end
	   values.type = luci.http.formvalue("type")
   end
   
   -- Check service for connectivity, if requested
   if (checkconnect == "1" and not error_info.uri) then
	  if (values.uri ~= '' and not dt.ip4addr(values.uri)) then
		 url = string.gsub(values.uri, '[a-z]+://', '', 1)
		 url = url:match("^[^/:]+") -- remove anything after the domain name/IP address
		 -- url = url:match("[%a%d-]+\.%w+$") -- remove subdomains (** actually we should probably keep subdomains **)
	  else
		 url = values.uri
	  end
	  local url_port
	  if (values.port and values.port ~= '') then
		 url_port = values.port
	  else
		 url_port = values.uri:match(":[0-9]+")
		 url_port = url_port and url_port:gsub(":","") or ''
		 if url_port == '' then
			url_port = values.uri:match("^https://") and "443" or ''
		 end
	  end
	  local curr_port = "80"
	  if url_port and url_port ~= "" then
		 if not error_info.port then
			local parsed =  cutil.pass_to_shell(url_port)
			if parsed == nil then
			   curr_port = "80"
			else
			   curr_port = parsed
			end
		 end
	  end
	  local connect = luci.sys.exec("nc -z -w 5 \"" .. cutil.pass_to_shell(url) .. '" "' .. curr_port  .. '"; echo $?')
	  if (connect:sub(-2,-2) ~= '0') then  -- exit status != 0 -> failed to resolve url
		 error_info.uri = "Failed to resolve URL or connect to host"
	  end
   end
   
   -- if invalid input was found, set error notice at top of page
   if (next(error_info)) then error_info.notice = "Invalid entries. Please review the fields below." end
   
   if (not edit_app) then -- if not updating application, check for too many applications or identical applications already on node
	  local count = luci.sys.exec("cat /etc/config/applications |grep -c \"^config application \"")
	  if (count and count ~= '' and tonumber(count) >= 100) then
		 error_info.notice = "This node cannot support any more applications at this time. Please contact the node administrator or try again later."
	  else
		 UUID = encode.uci(values.uri .. values.port):sub(1,254)
		 values.uuid = UUID
		 
		 uci:foreach("applications", "application", 
					 function(app)
						if (UUID == app.uuid or values.name == app.name) then
						   match = true
						end
		 end)
		 
		 if (match) then
			error_info.notice = "An application with this name or address already exists"
		 end
	  end
   else
	  values.uuid = luci.http.formvalue("uuid")
   end
   
   -- if error, send back bad data
   if (next(error_info)) then
	  if (edit_app) then
		 values.fingerprint = luci.http.formvalue("fingerprint")
		 admin_edit_app(error_info, values)
		 return
	  else
		 add_app(error_info, values)
		 return
	  end
   end
   
   
   if (autoapprove == "1" and not values.approved) then
	  values.approved = "1"
   end
   if ((allowpermanent == '1' and luci.http.formvalue("permanent") == nil) or allowpermanent == '0') then
	  --values.permanent = '0'
	  values.lifetime = os.date("%c",os.time() + lifetime) -- Add expiration time
   elseif (allowpermanent == '1' and luci.http.formvalue("permanent") and luci.http.formvalue("permanent") == '1') then
	  values.lifetime = '0'
   end
   if (values.ttl == '') then values.ttl = '0' end
   
   -- Update application if UUID has changed
   if (luci.http.formvalue("uuid") and edit_app) then 
	  if (luci.http.formvalue("uuid") ~= encode.uci(values.uri .. values.port)) then
		 if (not uci:delete("applications",luci.http.formvalue("uuid"))) then
			dispatch.error500("Unable to remove old UCI entry")
			return
		 end
		 deleted_uci = 1
		 UUID = encode.uci(values.uri .. values.port):sub(1,254)
		 values.uuid = UUID
	  else
		 UUID = luci.http.formvalue("uuid")
		 values.uuid = UUID
		 if UUID:len() > 254 then
			DIE("Invalid UUID length")
		 end
	  end
   end
   
   -- #################################################################
   -- #    If TTL > 0, create and sign Avahi service advertisement    #
   -- #################################################################
   if (tonumber(values.ttl) > 0) then
	  
	  type_tmpl = '<txt-record>type=${app_type}</txt-record>'
	  signing_tmpl = [[<type>_${type}._tcp</type>
<domain-name>mesh.local</domain-name>
<port>${port}</port>
<txt-record>name=${name}</txt-record>
<txt-record>ttl=${ttl}</txt-record>
<txt-record>uri=${uri}</txt-record>
${app_types}
<txt-record>icon=${icon}</txt-record>
<txt-record>description=${description}</txt-record>
<txt-record>lifetime=${lifetime}</txt-record>]]
		 tmpl = [[
<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">

<!-- This file is part of commotion -->
<!-- Reference: http://en.gentoo-wiki.com/wiki/Avahi#Custom_Services -->
<!-- Reference: http://wiki.xbmc.org/index.php?title=Avahi_Zeroconf -->

<service-group>
<name replace-wildcards="yes">${hash}</name>

<service>
]] .. signing_tmpl .. [[

<txt-record>signature=${signature}</txt-record>
<txt-record>fingerprint=${fingerprint}</txt-record>
<txt-record>version=1.0</txt-record>
</service>
</service-group>
]]
	  
	  -- FILL IN ${TYPE} BY LOOKING UP PORT IN /ETC/SERVICES, DEFAULT TO 'commotion'
	  if (values.port ~= '') then
		 local command = "grep " .. values.port .. "/tcp /etc/services |awk '{ cutil.tprintf((\"%s\", $1) }'"
		 service_type = luci.sys.exec(command)
		 if (service_type == '') then
			service_type = 'commotion'
		 end
	  else
		 service_type = 'commotion'
	  end
	  
	  -- CREATE <txt-record>type=???</txt-record> FOR EACH APPLICATION TYPE
	  app_types = ''
	  -- 		reverse_app_types = ''
	  if (type(luci.http.formvalue("type")) == "table") then
		 sorted_app_types = {}
		 for i, app_type in pairs(luci.http.formvalue("type")) do
			table.insert(sorted_app_types, app_type)
		 end
		 table.sort(sorted_app_types)
		 for i, app_type in ipairs(sorted_app_types) do
			app_types = app_types .. cutil.tprintf(type_tmpl, {app_type = app_type})
		 end
		 -- 			for i = #luci.http.formvalue("type"), 1, -1 do
		 -- 				reverse_app_types = reverse_app_types .. cutil.tprintf(type_tmpl, {app_type = luci.http.formvalue("type")[i]})
		 -- 			end
	  else
		 if (luci.http.formvalue("type") == '' or luci.http.formvalue("type") == nil) then
			app_types = ''
			-- 				reverse_app_types = ''
		 else
			app_types = cutil.tprintf(type_tmpl, {app_type = luci.http.formvalue("type")})
			-- 				reverse_app_types = app_types
		 end
	  end
	  
	  local fields = {
		 name = values.name,
		 type = service_type,
		 uri = values.uri,
		 port = values.port ~= '' and values.port or 0,
		 icon = values.icon,
		 description = values.description,
		 ttl = values.ttl,
		 app_types = app_types,
		 lifetime = values.lifetime == '0' and '0' or lifetime,
		 hash = luci.sys.exec("echo \"" .. cutil.pass_to_shell(UUID) .. luci.sys.hostname() .. "\" |sha1sum"):match('^[a-fA-F0-9]+')
	  }
	  
	  -- Create Serval identity keypair for service, then sign service advertisement with it
	  signing_msg = cutil.tprintf(signing_tmpl,fields)
	  fields.fingerprint = luci.sys.exec("serval-client id self"):match('^[A-F0-9]+')
	  if (luci.http.formvalue("fingerprint") and validate.hex(luci.http.formvalue("fingerprint")) and luci.http.formvalue("fingerprint"):len() == 64 and edit_app) then
		 resp = luci.sys.exec("commotion serval-crypto sign " .. luci.http.formvalue("fingerprint") .. " \"" .. cutil.pass_to_shell(signing_msg) .. "\"")
	  else
		 if (not deleted_uci and edit_app and not uci:delete("applications",UUID)) then
			dispatch.error500("Unable to remove old UCI entry")
			return
		 end
		 resp = luci.sys.exec("commotion serval-crypto sign " .. fields.fingerprint .. " \"" .. cutil.pass_to_shell(signing_msg) .. "\"")
	  end
	  if (luci.sys.exec("echo $?") ~= '0\n' or resp == '') then
		 dispatch.error500("Failed to sign service advertisement")
		 return
	  end
	  
	  _,_,fields.signature = resp:find('"signature": "([A-Z0-9]+)"')
	  -- UUID = fields.fingerprint  -- not for single-key node
	  values.fingerprint = fields.fingerprint
	  values.signature = fields.signature
	  
	  -- 		fields.app_types = reverse_app_types -- include service types in reverse order since avahi-client parses txt-records in reverse order
	  fields.app_types = app_types -- service types are in alphabetical order
	  
	  service_string = cutil.tprintf(tmpl,fields)
	  
	  -- create service file, then restart avahi-daemon
	  service_file = io.open("/etc/avahi/services/" .. UUID .. ".service", "w")
	  if (service_file) then
		 service_file:write(service_string)
		 service_file:flush()
		 service_file:close()
		 luci.sys.exec("kill -s USR1 $(pgrep olsrd)"); -- send signal to olsrd-dnssd to reload services
		 luci.sys.exec("/etc/init.d/avahi-daemon restart")
	  else
		 dispatch.error500("Failed to create avahi service file")
		 return
	  end
	  
   end  -- if (tonumber(values.ttl) > 0)
   
   -- delete service file if needed
   if (luci.http.formvalue("uuid") and luci.http.formvalue("uuid") ~= '')
	  and ((luci.fs.isfile("/etc/avahi/services/" .. luci.http.formvalue("uuid") .. ".service") and edit_app and tonumber(values.ttl) == 0)
		   or (luci.http.formvalue("uuid") ~= UUID)) then
		 local ret = luci.sys.exec("rm /etc/avahi/services/" .. luci.http.formvalue("uuid") .. ".service; echo $?")
		 if (ret:sub(-2,-2) ~= '0') then
			dispatch.error500("Error removing Avahi service file")
			return
		 end
		 luci.sys.exec("/etc/init.d/avahi-daemon restart")
		 luci.sys.exec("sleep 5; kill -s USR1 $(pgrep olsrd)"); -- send signal to olsrd-dnssd to reload services
   end
   
   -- Commit everthing to UCI
   if (values.approved == "1" or values.approved == "0") then
	  uci:set("applications", "known_apps", "known_apps")
	  uci:set("applications", "known_apps", values.uuid, (values.approved == "1") and "approved" or "blacklisted")
   end
   uci:section('applications', 'application', UUID, values)
   if (luci.http.formvalue("type") ~= nil) then
	  uci:set_list('applications', UUID, "type", luci.http.formvalue("type"))
   else
	  uci:delete('applications', UUID, "type")
   end
   uci:save('applications')
   uci:commit('applications')
   
   if (edit_app) then
	  luci.http.redirect("../apps?add=success")
   else
	  luci.http.redirect("/cgi-bin/luci/apps?add=success")
   end   
end -- action_add()
