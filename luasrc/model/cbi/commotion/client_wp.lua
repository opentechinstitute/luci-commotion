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

local utils = require "luci.util"
local db = require "luci.commotion.debugger"
local uci = require "luci.model.uci".cursor()
local fs = require "nixio.fs"
local cdisp = require "luci.commotion.dispatch"

m = Map("nodogsplash", translate("Welcome Page"))

--redirect on saved and changed to check changes.
m.on_after_save = cdisp.conf_page


enable = m:section(TypedSection, "settings", translate("On/Off"), translate("Users can be redirected to a “welcome page” when they first connect to this node."))
enable.anonymous = true
toggle = enable:option(Flag, "enable")
--TODO add /etc/init.d/script to run "ndsctl disable or enable" on this value.

ifaces = m:section(TypedSection, "interfaces", translate("For which network connection should this welcome page be active?"), translate("Select list of Aps and /or defined networks on this node's interfaces Auto select the first AP interface if configured."))
ifaces.anonymous = true

iflist = ifaces:option(ListValue, "interface")
current = uci:get("nodogsplash", "interfaces", "interface")
iflist:value(current)
iflist.default = current
uci.foreach("wireless", "wifi-iface",
			function(s)
			   local name = s[".name"]
			   if not utils.contains(iflist.vallist, name) then
				  iflist:value(name)
			   end
			end
   )

stime = m:section(TypedSection, "settings", translate("Time until welcome page is shown again"))
stime.anonymous = true

tfield = stime:option(Value, "splashtime")
tfield.datatype = "uinteger"

timeopt = stime:option(ListValue, "splashunit")
timeopt:value("seconds")
timeopt:value("minutes")
timeopt:value("hours")
timeopt:value("days")
--TODO apply spashtime to nodogsplash config on apply in seconds.

splshtxt = m:section(TypedSection, "_page", translate("Edit Welcome Page Text"), translate("The welcome page can include terms of service, advertisements, or other information. Edit the welcome page text here or upload an HTML file."))
splshtxt.cfgsections = function() return { "_page" } end
splshtxt.anonymous = true
edit = splshtxt:option(Button, "_page", translate("Edit"))
--edit.template = "cbi/cmtn_js_button"
--The following removes the default title for a word button.
edit.inputtitle = edit.title
edit.title = nil
upload = splshtxt:option(Button, "_page", translate("Upload"))
--edit.template = "cbi/cmtn_js_button"
--The following removes the default title for a word button.
upload.inputtitle = upload.title
upload.title = nil

local splashtextfile = "/usr/lib/lua/luci/view/commotion-splash/splashtext.htm"

help = splshtxt:option(DummyValue, "_dummy", translate("Edit Splash text"),
							 translate("You can enter your own text that is displayed to clients here.<br /><br />" ..
										  "It is possible to use the following markers:<br />" ..
										  "$gatewayname: The value of GatewayName as set in nodogsplash.conf.<br />" ..
										  "$authtarget: A URL which encodes a unique token and the URL of the user's original web request.<br />" ..
										  "$imagesdir: The directory in nodogsplash's web hierarchy where images to be displayed in the splash page must be located.<br />"))
help.template = "cbi/nullsection"
t = splshtxt:option(TextValue, "text")
t.rmempty = true
t.rows = 30
function t.cfgvalue()
   return fs.readfile(splashtextfile) or ""
end

uploader = splshtxt:option(FileUpload, "_upload", "UPLOADER TEXT HERE")

function m.on_parse(self)
   local b_press = luci.http.formvalue("cbid.nodogsplash._page._page")
   if b_press ~= "Edit" then
	  function t.render() return nil end
	  function help.render() return nil end
   end
   if b_press ~= "Upload" then
	  function uploader.render() return nil end
   end
   uploaded = "/lib/uci/upload/cbid.nodogsplash._page._upload"
   if luci.fs.isfile(uploaded) then
	  local nfs = require "nixio.fs"
	  nfs.move(uploaded, splashtextfile)
	  m.message = "file uploaded!" 
   end
   text = luci.http.formvalue("cbid.nodogsplash._page.text")
   if text and not b_press then
	  if text ~= "" then
		 fs.writefile(splashtextfile, text:gsub("\r\n", "\n"))
		 m.message = "Splashpage updated successfully!"
	  else
		 fs.unlink(splashtextfile)
		 m.message ="Default Splash page selected!"
	  end
   end
   return true
end

return m
