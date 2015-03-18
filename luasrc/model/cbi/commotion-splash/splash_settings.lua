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

m = Map("luci_splash", translate("Welcome Page"))
general = m:section(NamedSection, "general", "core", translate("General Settings"))
general.anonymous = true

toggle = general:option(Flag, "enable", translate("On/Off"), translate("Users can be redirected to a “welcome page” when they first connect to this node."))

redirect = general:option(Flag, "redirect", translate("Redirect to Homepage?"), translate("If this is checked, clients will be redirected to your homepage, instead of to their original request."))

--Maps to nodogsplash RedirectURL
homepage = general:option(Value, "redirect_url", translate("Homepage"), translate("After authentication, clients will be redirected to this URL instead of to their original request."))
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

general:option(Value, "limit_up", translate("Upload limit"), translate("Clients upload speed is limited to this value (kbyte/s)"))
general:option(Value, "limit_down", translate("Download limit"), translate("Clients download speed is limited to this value (kbyte/s)"))

general:option(DummyValue, "_tmp", "",
	translate("Bandwidth limit for clients is only activated when both up- and download limit are set. " ..
	"Use a value of 0 here to completely disable this limitation. Whitelisted clients are not limited."))



whitelist = m:section(TypedSection, "whitelist", translate("WHITELIST"), translate("MAC addresses of whitelisted clients. These do not need to be shown the Welcome Page and are not bandwidth limited."))
whitelist.anonymous = true
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


blacklist = m:section(TypedSection, "blacklist", translate("BANNED"), translate("MAC addresses in this list are blocked."))
blacklist.anonymous = true
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

tfield = general:option(Value, "leasetime", translate("Lease time"), translate("Time in hours until welcome page is shown again"))
tfield.anonymous = true
tfield.datatype = "uinteger"
tfield.optional = false
tfield.maxlength = 16
tfield.rmempty = false
tfield.forcewrite = true
function tfield:validate(val)
  if val then
    if #val > 16 then
      return nil, translate("Welcome page lease time too long.")
    elseif #val == 0 then
      return nil, translate("Must include a welcome page lease time.")
    elseif val == "0" then
      return nil, translate("Value must be greater than zero.")
    end
    return val
  end
  return nil, "Empty value."
end

--[[
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
]]--

s = m:section(TypedSection, "iface", translate("Interfaces"), translate("Interfaces that are used for Splash."))
s.template = "cbi/tblsection"
s.addremove = true
s.anonymous = true

local uci = luci.model.uci.cursor()

zone = s:option(ListValue, "zone", translate("Firewall zone"),
	translate("Splash rules are integrated in this firewall zone"))

uci:foreach("firewall", "zone",
	function (section)
		zone:value(section.name)
	end)
	
iface = s:option(ListValue, "network", translate("Network"),
	translate("Intercept client traffic on this Interface"))

uci:foreach("network", "interface",
	function (section)
		if section[".name"] ~= "loopback" then
			iface:value(section[".name"])
		end
	end)
	
uci:foreach("network", "alias",
	function (section)
		iface:value(section[".name"])
	end)

--[[
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
   ]]--
splshtxt = m:section(TypedSection, "_page", translate("Edit Welcome Page Text"), translate("The welcome page can include terms of service, advertisements, or other information. Edit the welcome page text here or upload an HTML file."))
splshtxt.cfgsections = function() return { "_page" } end
splshtxt.anonymous = true

edit2 = splshtxt:option(Flag, "edit", translate("Edit Welcome Page Text"))
upload2 = splshtxt:option(Flag, "upload", translate("Upload Welcome Page Text"))

local splashtextfile = "/usr/lib/luci-splash/splashtext.htm"

local help_text = translate("You can enter text and HTML that will be displayed on the welcome page.<br /><br />" ..
  "These variables can be used to provide custom values from this node on the welcome page :<br />" ..
	"###HOMEPAGE###, ###LEASETIME###, ###LIMIT### and ###ACCEPT###.<br />")

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


