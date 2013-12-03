local db = require "luci.commotion.debugger"
local m = Map("wireless", translate("Passwords"), translate("Commotion basic security settings places all the passwords and other security features in one place for quick configuration. "))

--PASSWORDS
local v0 = true -- track password success across maps

-- CURRENT PASSWORD
-- Allow incorrect root password to prevent settings change
-- Don't prompt for password if none has been set
if luci.sys.user.getpasswd("root") then
   s0 = m:section(TypedSection, "_dummy", translate("Current Password"), translate("Current password required to make changes on this page"))
   s0.addremove = false
   s0.anonymous = true
   pw0 = s0:option(Value, "pw0")
   pw0.password = true
   -- fail by default
   v0 = false
   function s0.cfgsections()
	  return { "_pass0" }
   end
end

local interfaces = {}
uci.foreach("wireless", "wifi-iface",
			function(s)
			   local name = s[".name"]
			   local key = s.key or "NONE"
			   local mode = s.mode or "NONE"
			   local enc = s.encryption or "NONE"
			   table.insert(interfaces, {name=name, mode=mode, key=key, enc=enc})
			end
)

--iface password creator for all other interfaces
--! @name pw_sec_opt
--! @brief create password options to add to interface passed-
function pw_sec_opt(pw_s, iface)
   pw_s.addremove = false
   pw_s.anonymous = true
   pw1 = pw_s:option(Value, (iface.name.."_key"))
   pw1.password = true
   pw1.anonymous = true
   pw2 = pw_s:option(Value, iface.name.."_conf", nil, translate("Confirm Password"))
   pw2.password = true
   pw2.anonymous = true
   function pw_s.cfgsections()
	  return { "_pass" }
   end
end

--MESH ECRYPTION PASSWORD
--Check for mesh interfaces
mesh_ifaces = {}
for i,iface in ipairs(interfaces) do
   if iface.mode == "adhoc" then
	  table.insert(mesh_ifaces, iface)
   end
end

local pw_text = "To encrypt Commotion mesh network data between devices, each device must share a common mesh encryption password. Enter that shared password here."
if #mesh_ifaces > 1 then
   for _,x in pairs(mesh_ifaces) do
	  local meshPW = m:section(NamedSection, x.name, "wifi-iface", x.name, pw_text)
	  meshPW = pw_sec_opt(meshPW, x)
   end
else
   db.log("mesh ifaces")
   db.log(mesh_ifaces[1].name)
   local meshPW = m:section(NamedSection, mesh_ifaces[1].name, "wifi-iface", mesh_ifaces[1].name, pw_text)
   meshPW = pw_sec_opt(meshPW, mesh_ifaces[1])
end

--ADMIN PASSWORD
admin_pw_text = "This password is used to login to this node."
admin_pw_s = m:section(TypedSection,"_dummy", translate("Administration Password"), translate(admin_pw_text))
admin_pw_s.addremove = false
admin_pw_s.anonymous = true

admin_pw1 = admin_pw_s:option(Value, "admin_pw1")
admin_pw1.password = true

admin_pw2 = admin_pw_s:option(Value, "admin_pw2", nil, translate("Confirm Password"))
admin_pw2.password = true

function admin_pw_s.cfgsections()
	return { "_pass" }
end

--Check for other Interfaces
for i,iface in ipairs(interfaces) do
   if iface.mode ~= "adhoc" then
	  local otherPW = m:section(NamedSection, iface.name, "wifi-iface", iface.name.." Interface", translate("Enter the password people should use to connect to this interface."))
	  otherPW = pw_sec_opt(otherPW, iface, iface.name)
   end
end

function m.on_before_commit(map)
	-- if existing password, make sure user has old password
	if s0 then
		v0 = luci.sys.user.checkpasswd("root", formvalue("_pass0"))
	end

	if v0 == false then
		m.message = translate("Incorrect password. Changes rejected!")
		m.save=v0
		m2.save=v0
	end
end

function m.on_commit(map)
   local v1 = pw1:formvalue("_pass")
   local v2 = pw2:formvalue("_pass")
	if v0 == true and v1 and v2 and #v1 > 0 and #v2 > 0 then
	   if v1 == v2 then
		  if luci.sys.user.setpasswd(luci.dispatcher.context.authuser, v1) == 0 then
			 m.message = translate("Password successfully changed!")
		  else
			 m.message = translate("Unknown Error, password not changed!")
		  end
	   else
		  m.message = translate("Given password confirmation did not match, password not changed!")
	   end
	end
end




return m



