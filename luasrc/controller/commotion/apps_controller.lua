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
require "csm"
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
  local action, app_id, key
  local uci = luci.model.uci.cursor()
  local uuid = luci.http.formvalue("uuid")
  local approved = luci.http.formvalue("approved")
  local dispatch = require "luci.dispatcher"
  uci:foreach("applications", "application",
    function(app)
      if (uuid == app['.name']) then
	key = app.key
	app_id = uuid
      end
    end
  )
  if (not app_id) then
    dispatch.error500("Application not found")
    return
  end
  if approved == "1" or approved == "0" then
    if (uci:set("applications", app_id, "approved", approved) and 
	uci:set("applications", "known_apps", "known_apps") and
	uci:set("applications", "known_apps", app_id, (approved == "1") and "approved" or "banned") and
	uci:save('applications') and 
	uci:commit('applications')) then
      luci.http.status(200, "OK")
    else
      dispatch.error500("Could not approve/ban app")
    end
  elseif approved == "delete" then
    csm.init()
    local services = csm.fetch_services()
    local s = services[key]
    if not s or not s:remove() then
      dispatch.error500("Could not delete app")
    else
      luci.http.status(200, "OK")
    end
    services:free()
    csm.shutdown()
  end
end

function action_edit()
  action_add({true})
end

function load_apps(is_admin)
  local uuid, app
  local uci = require "luci.model.uci".cursor()
  local autoapprove = uci:get("applications","settings","autoapprove")
  local categories = {}
  if is_admin then
    categories = {banned={}, approved={}, new={}}
  end
  
  uci:foreach("applications", "application",
    function(app)
      if is_admin then
	if app.approved and app.approved == '1' then
	  categories.approved[app[".name"]] = app
	elseif app.approved then
	  categories.banned[app[".name"]] = app
	else
	  categories.new[app[".name"]] = app
	end
      else
	if (app.approved and app.approved == '1') or (autoapprove == '1' and not app.approved) then
	  if not categories.applications then categories.applications = {} end
	  categories.applications[app[".name"]] = app
	end
      end
    end
  )
  luci.template.render("commotion/apps_view", {categories=categories, is_admin=is_admin})
end

function add_app(error_info, bad_data)
  local uci = luci.model.uci.cursor()
  local co_utils = require "luci.commotion.util"
  local encode = require "luci.commotion.encode"
  local tag_tmpl = '<input type="checkbox" name="tag" value="${tag_escaped}" ${checked}/>${tag}<br />'
  local categories = uci:get_list("applications","settings","category")
  local allowpermanent = uci:get("applications","settings","allowpermanent")
  local tags_string = ''
  if (bad_data and bad_data.tag) then
    for i, category in pairs(categories) do
      local match = nil
      if (type(bad_data.tag) == "table") then
	for i, app_tag in pairs(bad_data.tag) do
	  if (app_tag == category) then match=true end
	end
      else -- type(bad_data.tag) == "string"
	if (category == bad_data.tag) then match=true end
      end
      if (match) then
	tags_string = tags_string .. co_utils.tprintf(tag_tmpl, {tag=category, tag_escaped=encode.html(category), checked="checked "})
      else
	tags_string = tags_string .. co_utils.tprintf(tag_tmpl, {tag=category, tag_escaped=encode.html(category), checked=""})
      end
    end
  else
    for i, category in pairs(categories) do
      tags_string = tags_string .. co_utils.tprintf(tag_tmpl, {tag=category, tag_escaped=encode.html(category), checked=""})
    end
  end
  luci.template.render("commotion/apps_form", {tags_string=tags_string, err=error_info, app=bad_data, page={type="add", action="/apps/add_submit", allowpermanent=allowpermanent}})
end

function admin_edit_app(error_info, bad_data)
  local uuid, app_data, tags_string
  local co_utils = require "luci.commotion.util"
  local encode = require "luci.commotion.encode"
  local uci = luci.model.uci.cursor()
  local dispatch = require "luci.dispatcher"
  local tags_tmpl = '<input type="checkbox" name="tag" value="${tag_escaped}" ${checked}/>${tag}<br />'
  local categories = uci:get_list("applications","settings","category")
  local allowpermanent = uci:get("applications","settings","allowpermanent")
  if (not bad_data) then
    -- get app id from GET parameter
    if (luci.http.formvalue("uuid") and luci.http.formvalue("uuid") ~= '') then
      uuid = luci.http.formvalue("uuid")
    else
      dispatch.error500("No UUID given")
      return
    end
    
    -- get app data from UCI
    uci:foreach("applications", "application",
      function(app)
	if (uuid == app[".name"]) then
	  app_data = app
	  app_data.uuid = uuid
	end
      end
    )
    if (not app_data) then
      dispatch.error500("No application found for given UUID")
      return
    end
  else
    uuid = bad_data.uuid
    app_data = bad_data
  end
  
  tags_string = ''
  for i, category in pairs(categories) do
    local match = nil
    if (app_data.tag) then
      for i, app_tag in pairs(app_data.tag) do
	if (app_tag == category) then match=true end
      end
    end
    if (match) then
      tags_string = tags_string .. co_utils.tprintf(tags_tmpl, {tag=category, tag_escaped=encode.html(category), checked="checked "})
    else
      tags_string = tags_string .. co_utils.tprintf(tags_tmpl, {tag=category, tag_escaped=encode.html(category), checked=""})
    end
  end
  
  luci.template.render("commotion/apps_form", {tags_string=tags_string, app=app_data, err=error_info, page={type="edit", action="/apps/edit_submit", allowpermanent=allowpermanent}})
end

function action_add(edit_app)
  local uci = luci.model.uci.cursor()
  local dispatch = require "luci.dispatcher"
  local encode = require "luci.commotion.encode"
  local co_utils = require "luci.commotion.util"
  local luci_util = require "luci.util"
  local uri = require "uri"
  local bad_data = {}
  local error_info = {}
  local lifetime = uci:get("applications","settings","lifetime") or 86400
  local allowpermanent = uci:get("applications","settings","allowpermanent")
   
  local values = {
    name =  luci.http.formvalue("name"),
    uri =  luci.http.formvalue("uri"),
    icon =  luci.http.formvalue("icon"),
    description =  luci.http.formvalue("description"),
    ttl = luci.http.formvalue("ttl"),
  }
   
  -- ###########################################
  -- #           INPUT VALIDATION              #
  -- ###########################################
  for _,val in pairs({"name","uri","description","icon"}) do
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
  
  if values.ttl ~= '' and not validate.ttl(values.ttl) then
    error_info.ttl = "Invalid TTL value; must be integer greater than zero"
  end
  
  if luci.http.formvalue("permanent") and (luci.http.formvalue("permanent") ~= '1' or allowpermanent == '0') then
    dispatch.error500("Invalid permanent value")
    return
  end
  
  if edit_app then
    if luci.http.formvalue("approved") and luci.http.formvalue("approved") ~= '' and tonumber(luci.http.formvalue("approved")) ~= 0 and tonumber(luci.http.formvalue("approved")) ~= 1 then
      dispatch.error500("Invalid approved value")
      return
    end
    values.approved = luci.http.formvalue("approved")
    if not luci.http.formvalue("key") or luci.http.formvalue("key"):len() ~= 64 or not validate.hex(luci.http.formvalue("key")) then
      dispatch.error500("Invalid key value")
      return
    end
    values.key = luci.http.formvalue("key")
    if not luci.http.formvalue("uuid") or luci.http.formvalue("uuid"):len() ~= 52 then
      dispatch.error500("Invalid UUID value")
      return
    end
    values.uuid = luci.http.formvalue("uuid")
  end
  
  -- escape input strings
  for field, val in pairs(values) do
    if (field ~= 'uri' and field ~= 'icon') then
      values[field] = encode.html(val)
    else
      values[field] = encode.url(val)
    end
    if values[field]:len() > 254 then
      error_info[field] = "Value too long"
    end
  end
  
  -- make sure application tags are within the set of approved categories on node
  if (luci.http.formvalue("tag")) then
    if (not validate.app_category(luci.http.formvalue("tag"))) then
      dispatch.error500("Invalid application category value")
      return
    end
    if type(luci.http.formvalue("tag")) == "table" then
      values.tag = luci.http.formvalue("tag")
    else
      values.tag = {luci.http.formvalue("tag")}
    end
  end
  
  -- if invalid input was found, set error notice at top of page
  if (next(error_info)) then
    error_info.notice = "Invalid entries. Please review the fields below."
  end
  
  -- if not updating application, check for too many applications (arbitrarily set at 100 max)
  local count = luci.sys.exec("cat /etc/config/applications |grep -c \"^config application \"")
  if not edit_app and count and count ~= '' and tonumber(count) >= 100 then 
    error_info.notice = "This node cannot support any more applications at this time. Please contact the node administrator or try again later."
  end
  
  -- if error, send back bad data
  if (next(error_info)) then
    if (edit_app) then
      admin_edit_app(error_info, values)
      return
    else
      add_app(error_info, values)
      return
    end
  end
  
  if ((allowpermanent == '1' and luci.http.formvalue("permanent") == nil) or allowpermanent == '0') then
    values.lifetime = lifetime
  elseif (allowpermanent == '1' and luci.http.formvalue("permanent") and luci.http.formvalue("permanent") == '1') then
    values.lifetime = 0
  end
  if values.ttl == '' then values.ttl = '0' end
  
  csm.init()
  local s = csm.new_service()
  s.version = "2.0"
  s.name = values.name
  s.uri = values.uri
  s.icon = values.icon
  s.description = values.description
  s.ttl = tonumber(values.ttl)
  s.lifetime = tonumber(values.lifetime)
  s.tag = values.tag
  if edit_app then
    s.key = values.key
  end
  if not s:commit() then
    s:free()
    csm.shutdown()
    dispatch.error500("Failed to add application")
    return
  end
  s:free()
  csm.shutdown()
  
  -- Add application to known apps list in UCI
  if (values.approved == "1" or values.approved == "0") then
    judge_app()
  end
  
  if (edit_app) then
    luci.http.redirect("../apps?add=success")
  else
    luci.http.redirect("/cgi-bin/luci/apps?add=success")
  end   
end -- action_add()
