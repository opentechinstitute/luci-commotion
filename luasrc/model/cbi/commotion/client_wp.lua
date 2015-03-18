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

m = Map("luci_splash", translate("Welcome Page"))

--redirect on saved and changed to check changes.
m.on_after_save = ccbi.conf_page

general = m:section(NamedSection, "general", "core", translate("General Settings"))
general.anonymous = true

toggle = general:option(Flag, "enable", translate("On/Off"), translate("Users can be redirected to a “welcome page” when they first connect to this node."))

tfield = general:option(Value, "leasetime", translate("Lease time"), translate("Time in hours until welcome page is shown again"))
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


