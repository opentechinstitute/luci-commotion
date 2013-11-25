local uci = require "luci.model.uci"
local utils = require "luci.util"
--local QS = require "luci.commotion.quickstart"

local m = Map("wireless", translate("Network Interfaces"), translate("Every Commotion node must have one mesh network connection or interface. Commotion can mesh over wireless or wired interfaces. The Setup Wizard has detected all of the network interfaces on this device. Select the network interface that will connect to the mesh."))

local wifi_dev = {}
uci.foreach("wireless", "wifi-device",
			function(s)
			   local name = s[".name"]
			   local mode = s.mode
			   wifi_dev.insert({name, channel})
			end
)

rsec = m:section(TypedSection, "wifi-device", translate("Wireless Interface"), translate("Select the wireless network interface to use for your access point."))

radios = rsec:option(ListValue, "_dummy", translate(""))

--add all the radios we found into this with channels attached
5ghz = {"11a", "11adt", '11na'}
for _,dev in pairs(wifi_dev) do
   if utils.contains(5ghz, dev[2]) then
	  local freq = "5 GHz"
   else
	  local freq = "2.4 GHz"
   end
   radios:value(dev[1].." "..freq, freq)
end


channel = rsec:option(ListValue, "_dummy", translate(""))
--Need to exact results when parsing a wireless config
channel:depends()

protocol = uci.get("wireless", "wifi-device", "hwmode")

if protocol == '11na' then
   c = e:option(ListValue, "channel", translate("5GHz Channel"), translate("The 5GHz backhaul channel of the mesh network, if applicable."))
   c:value(36, "Channel 36 (5.180 GHz)")
   c:value(40, "Channel 40 (5.200 GHz)")
   c:value(44, "Channel 44 (5.220 GHz)")
   c:value(48, "Channel 48 (5.240 GHz)")
   c:value(149, "Channel 149 (5.745 GHz)")
   c:value(153, "Channel 153 (5.765 GHz)")
   c:value(157, "Channel 157 (5.785 GHz)")
   c:value(161, "Channel 161 (5.805 GHz)")
   c:value(165, "Channel 165 (5.825 GHz)")
else
   c = e:option(ListValue, "channel", translate("2GHz Channel"), translate("The 2.4GHz backhaul channel of the mesh network, if applicable"))
   for i=1, 11, 1 do
	  c:value(i, "Channel " .. i .. " (" .. tostring(2.407+(i*0.005)) .. " GHz)")
   end
end


return m
