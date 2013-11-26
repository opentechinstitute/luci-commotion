local cursor = require "luci.model.uci".cursor()
--Main title and system config map for hostname value
local m = Map("system", translate("Basic Configuration"), translate("In this section you'll set the basic required settings for this device, and the basic network settings required to connect this device to a Commotion Mesh network. You will be prompted to save your settings along the way and apply them at the end."))

return m
