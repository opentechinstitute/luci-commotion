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
local ccbi = require "luci.commotion.ccbi"
local lfs = require "luci.fs"
local dt = require "luci.cbi.datatypes"
local cvd = require "luci.commotion.validate"
local uri = require "uri"

m = Map("nodogsplash", translate("Welcome Page"))

enable = m:section(TypedSection, "settings", translate("On/Off"), translate("Users can be redirected to a “welcome page” when they first connect to this node."))
enable.anonymous = true

toggle = enable:option(Flag, "enable")

general = m:section(TypedSection, "settings", translate("General"))
general.anonymous = true

redirect = general:option(Flag, "redirect", translate("Redirect to Homepage?"), translate("If this is checked, clients will be redirected to your homepage, instead of to their original request."))

--Maps to nodogsplash RedirectURL
homepage = general:option(Value, "redirecturl", translate("Homepage"), translate("After authentication, clients will be redirected to this URL instead of to their original request."))
homepage:depends("redirect", 1) --Flags return "" if unchecked and self.enabled if true
function homepage:validate(val)
   if val then
	local v = uri:new(val)
	  if v then
		if v._scheme then
			return val
		end
	  else
		 return nil
	  end
   end
   return nil
end

--AuthenticateImmediately
autoauth = general:option(Flag, "autoauth", translate("Immediately Authenticate"), translate(" If this is checked, clients will be immediately directed to their original request or your homepage (if set above), instead of being shown the Welcome Page."))


whitelist = m:section(NamedSection, "whitelist", "MACList", translate("WHITELIST"), translate("MAC addresses of whitelisted clients. These do not need to be shown the Welcome Page and are not bandwidth limited."))
wlOn = whitelist:option(Flag, "wlOn")
wlMacs = whitelist:option(DynamicList, "mac", translate("MAC Address"))
wlMacs:depends("wlOn", 1)
wlMacs.placeholder = "00:00:00:00:00:00"
function wlMacs:validate(val)
   if val and next(val) then
	  for _,mac in ipairs(val) do
		 if dt.macaddr(tostring(mac)) then
			return val
		 else
			return nil
		 end
	  end
   end
   return {}
end


blacklist = m:section(NamedSection, "blacklist", "MACList", translate("BANNED"), translate("MAC addresses in this list are blocked."))
blOn = blacklist:option(Flag, "blOn")
blMacs = blacklist:option(DynamicList, "mac", translate("MAC Address"))
blMacs:depends("blOn", 1)
blMacs.placeholder = "00:00:00:00:00:00"
blMacs.default = "00:00:00:00:00:00"
function blMacs:validate(val)
   if val and next(val) then
	  for _,mac in ipairs(val) do 
		 if dt.macaddr(tostring(mac)) then
			return val
		 else
			return nil
		 end
	  end
   end
   return {}
end

--maps to FirewallRuleSet preauthenticated-users
firewallRules = m:section(NamedSection, "preauthenticated_users", "FirewallRuleSet",  translate("ALLOWED HOSTS/SUBNETS"), translate("Hosts and Networks that are listed here are excluded from splashing, i.e. they are always allowed."))
fwOn = firewallRules:option(Flag, "fwOn")
rules = firewallRules:option(DynamicList, "UsrFirewallRule", translate("IP Address"), translate("CIDR notation optional (e.g. 192.168.1.0/24)"))
rules:depends("fwOn", 1)
rules.datatype = "ipaddr"
rules.placeholder = "192.0.2.1"
function rules:validate(val)
   if val then
	  for _,ip in ipairs(val) do 
		 if dt.ipaddr(tostring(ip)) then
			return val
		 else
			return nil
		 end
	  end
   end
end

function toggle.write(self, section, fvalue)
   value = self.map:get(section, self.option)
   if value ~= fvalue then
	  self.section.changed = true
	  self.map:set("interfaces", "interface", "br-lan")
	  return self.map:set(section, self.option, fvalue)
   end
end

function toggle.remove(self, section)
   value = self.map:get(section, self.option)
   if value ~= self.disabled then
	  self.section.changed = true
	  return self.map:del(section, self.option)
   end
end

stime = m:section(TypedSection, "settings", translate("Time until welcome page is shown again"))
stime.anonymous = true

tfield = stime:option(Value, "splashtime")
tfield.datatype = "uinteger"
tfield.forcewrite = true

timeopt = stime:option(ListValue, "splashunit")
timeopt:value("minutes")
timeopt:value("hours")
timeopt:value("days")

splshtxt = m:section(TypedSection, "_page", translate("Edit Welcome Page Text"), translate("The welcome page can include terms of service, advertisements, or other information. Edit the welcome page text here or upload an HTML file."))
splshtxt.cfgsections = function() return { "_page" } end
splshtxt.anonymous = true

edit2 = splshtxt:option(Flag, "edit", translate("Edit Welcome Page Text"))
upload2 = splshtxt:option(Flag, "upload", translate("Upload Welcome Page Text"))

local splashtextfile = "/usr/lib/lua/luci/view/commotion-splash/splashtext.htm"

local help_text = translate("You can enter text and HTML that will be displayed on the welcome page.").."<br /><br />"..translate("These variables can be used to provide custom values from this node on the welcome page :").."<br />"..translate("$gatewayname: The value of GatewayName as set in the Welcome Page configuration file (/path/nodogsplash.conf).").."<br />"..translate("$authtarget: The URL of the user's original web request.").."<br />"..translate("$imagesdir: The directory in on this node where images to be displayed in the splash page must be located.").."<br />"..translate("The welcome page might include terms of service, advertisements, or other information. Edit the welcome page text here or upload an HTML file.").."<br />"

help = splshtxt:option(DummyValue, "_dummy", nil, help_text)
--help.template = "cbi/nullsection"
help:depends("edit", "1")
help:depends("upload", "1")

t = splshtxt:option(TextValue, "text")
t.rmempty = true
t.rows = 30
t:depends("edit", "1")

function t.cfgvalue()
   return fs.readfile(splashtextfile) or ""
end

uploader = splshtxt:option(FileUpload, "_upload")
uploader:depends("upload", "1")

function m.on_parse(self)
   local b_press = luci.http.formvalue("cbid.nodogsplash._page._page")
   uploaded = "cbid.nodogsplash._page._upload"
   if lfs.isfile("/lib/uci/upload/"..uploaded) then
	  if fs.move("/lib/uci/upload/"..uploaded, splashtextfile) then
		 m.proceed = true
		 m.message = "Success! Your welcome page text has been updated!"
	  else
		 m.proceed = true
		 m.message = "Sorry! There was a problem moving your welcome text to the correct location. You can find it in ".."/lib/uci/upload/"..uploaded.. " and move it to "..splashtextfile
	  end
   elseif luci.http.formvalue(uploaded) ~= nil then
	  m.proceed = true
	  m.message = "Sorry! There was a problem updating your welcome page text. Please try again."
   end
   text = luci.http.formvalue("cbid.nodogsplash._page.text")
   if text then
	  if text ~= "" then
		 fs.writefile(splashtextfile, text:gsub("\r\n", "\n"))
		 m.proceed = true
		 m.message = "Success! Your welcome page text has been updated!"
	  else
		 fs.unlink(splashtextfile)
		 m.proceed = true
		 m.message ="The default welcome page has been restored."
	  end
   end
   return true
end

return m


