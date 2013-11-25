local uci = require "luci.model.uci".cursor()
local utils = require "luci.util"
--local db = require "luci.commotion.debugger"
--local QS = require "luci.commotion.quickstart"

local m = Map("wireless", translate("Network Interfaces"), translate("Every Commotion node must have one mesh network connection or interface. Commotion can mesh over wireless or wired interfaces. The Setup Wizard has detected all of the network interfaces on this device. Select the network interface that will connect to the mesh."))

local wifi_dev = {}
uci.foreach("wireless", "wifi-device",
			function(s)
			   local name = s[".name"]
			   local mode = s.hwmode
			   table.insert(wifi_dev, {name, mode})
			end
)

function check_ghz(hwm)
   local five_ghz = {"11a", "11adt", '11na'}
   if utils.contains(five_ghz, hwm) then
	  freq = "5GHz"
   else
	  freq = "2.4GHz"
   end
   return freq
end

local function get_freqs(freq)
   if freq == "5GHz" then
	  return {{36, "Channel 36 (5.180 GHz)"},
			  {40, "Channel 40 (5.200 GHz)"},
			  {44, "Channel 44 (5.220 GHz)"},
			  {48, "Channel 48 (5.240 GHz)"},
			  {149, "Channel 149 (5.745 GHz)"},
			  {153, "Channel 153 (5.765 GHz)"},
			  {157, "Channel 157 (5.785 GHz)"},
			  {161, "Channel 161 (5.805 GHz)"},
			  {165, "Channel 165 (5.825 GHz)"}}
   else
	  if freq == "2.4GHz" then
		 local set = {}
		 for i=1, 11, 1 do
			table.insert(set, {i, "Channel " .. i .. " (" .. tostring(2.407+(i*0.005)) .. " GHz)"})
		 end
		 return set
	  end
   end
end

local this_dev = nil
devices = m:section(TypedSection,"_dummy", "")
devices.anonymous = true
--Check for more than one radio, and if not don't offer to change radio's.
if #wifi_dev > 1 then
   radios = devices:option(ListValue, "_dummy",  translate("wifi-device"), translate("Wireless Interface"), translate("Select the wireless network interface to use for your access point."))
   for _,dev in pairs(wifi_dev) do
	  local freq = check_ghz(dev[2])

	  radios:value(dev[1].." "..freq, {dev[1]})

	  local radio = m:section(NamedSection, dev[1] ,translate(""), translate(""))
	  radio.anonymous = true
	  radio.depends("radios", dev[1])
	  
	  local channels = radio:option(ListValue, "channel", translate("Channel"), translate("The channel of this wireless interface."))
	  
	  --adds the values to the list based on frequency
	  for _,x in pairs((get_freqs(freq))) do
		 channels:value(x[1], x[2])
	  end
   end
else
   radios = devices:option(ListValue, "_dummy",  translate("wifi-device"), translate("Wireless Interface"), translate("Select the wireless network interface to use for your access point."))
   
   local radio = m:section(NamedSection, wifi_dev[1][1] ,translate(""), translate(""))

   local channels = radio:option(ListValue, "channel", translate("Channel"), translate("The channel of this wireless interface."))
   for _,x in pairs(get_freqs(check_ghz(wifi_dev[1][2]))) do
	  channels:value(x[1], x[2])
   end
end

return m
