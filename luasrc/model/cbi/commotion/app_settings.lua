local ccbi = require "luci.commotion.ccbi"
local db = require "luci.commotion.debugger"
local ccbi = require "luci.commotion.ccbi"
local validate = require "luci.commotion.validate"

local m = Map("applications", translate("Application Settings"), translate("Change settings for applications publicly announced by this node."))
m.on_after_save = ccbi.conf_page

s = m:section(TypedSection, "settings", translate("Categories"))

categories = s:option(DynamicList, "category")
categories.optional = false
function categories.validate(self, value)
	if validate.app_settings_category(value) then
		return value
	else
		return nil, "Categories must be less than 251 characters"
	end
end

expire = s:option(Flag, "allowpermanent", translate("Force local applications to expire?"), translate("When checked, all applications expire after a time period you specify. Un-check this box if applications should not expire."))
expire.enabled = "0"
expire.disabled = "1"
expire.default = expire.disabled
expire.write=ccbi.flag_write
expire.optional = false

function expire.remove(self, section)
   value = self.map:get(section, self.option)
   if value ~= expire.disabled then
	  self.section.changed = true
	  return self.map:set(section, self.option, expire.disabled)
   end
end


ex_time_num = s:option(Value, "lifetime", translate("Time before applications expire"))

--! ex_time_num.write
--! @brief Multiple the lifetime by the unit chosen to modify it to seconds.
function ex_time_num.write(self, section, value)
   local units = {seconds=1, minutes=60, hours=3600, days=86400}
   local unit = ex_time_units:formvalue(section)
   local sets = nil
   
   for unt,num in pairs(units) do
	  if unit == unt then
		 value = tonumber(value) * num
		 sets = true
	  end
   end
   if sets and value > 0 then
	  return self.map:set(section, self.option, value)
   else
	  return nil
   end
end



ex_time_units = s:option(ListValue, "_units")
ex_time_units:value("seconds")
ex_time_units:value("minutes")
ex_time_units:value("hours")
ex_time_units:value("days")

function ex_time_units.write() return true end

apprv = s:option(Flag, "autoapprove", translate("Automatically approve all publicly announced applications on this network"))
apprv.remove=ccbi.flag_off
apprv.write=ccbi.flag_write
apprv.optional = false

chk_conn = s:option(Flag, "checkconnect", translate("Periodically check connection to announced applications on this network"), translate("If 'Yes' is selected here, applications are checked to see if they are still online. If they are not responsive, they will be removed from the application list. Select 'No' to disable this option If you have poor or intermittent connectivity."))
chk_conn.remove=ccbi.flag_off
chk_conn.write=ccbi.flag_write
chk_conn.optional = false

allow_anon = s:option(Flag, "enable_unauth", translate("Allow users to add application advertisements from your access point."), translate("If 'Yes' is selected here, any user on your device can add an application from the view apps mainpage. Select 'No' to disable this option If you would like to require administrator access to add advertisements."))
allow_anon.remove=ccbi.flag_off
allow_anon.write=ccbi.flag_write
allow_anon.optional = false

return m

