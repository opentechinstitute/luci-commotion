--! @file validate

local dt = require "luci.cbi.datatypes"
local uri = require "uri"
local uci = require "luci.model.uci"
local util = require "luci.util"
local tonumber = tonumber
local type = type
local pairs = pairs

module "luci.commotion.validate"

local validate = {}

function validate.hex(val)
  if val and val:match("^[%x]+$") then
    return true
  end
  return false
end

function validate.printable_ascii(val)
  if val and val:match("^[a-zA-Z0-9!\"#$%%&'()*+,%-%./:;<=>?@%[\\%]^_`{|}~]+$") then
    return true
  end
  return false
end

function validate.hostname(val)
  if val and (#val >= 1) and (#val < 53) and (
    val:match("^[a-zA-Z]$") or
    val:match("^[a-zA-Z][a-zA-Z0-9%-]*[a-zA-Z0-9]$")
  ) then
    return true
  end
  return false
end

function validate.mode(val)
   -- Modes are simple, but also match the "-" in Ad-Hoc
  if val and val:match("^[%w%-]+$") then
    return true
  end
  return false
end

function validate.wireless_pw(val)
  if val and (#val >= 8) and (#val <= 63) and validate.printable_ascii(val) then
    return true
  end
  return false
end

function validate.mesh_ssid(val)
  if val and (#val >= 1) and (#val <= 31) then
    return true
  end
  return false
end

function validate.ap_ssid(val)
  if val and (#val >= 1) and (#val <= 32) then
    return true
  end
  return false
end

function validate.channel_2(val)
  local channels = {1,2,3,4,5,6,7,8,9,10,11,12,13,14}
  if util.table.contains(channels, tonumber(val)) then
    return true
  end
  return false
end

function validate.channel_5(val)
  local channels = {36,40,44,48,149,153,157,161,165}
  if util.table.contains(channels, tonumber(val)) then
    return true
  end
  return false
end

function validate.channel(val)
  if validate.channel_2(tonumber(val)) or validate.channel_5(tonumber(val)) then
    return true
  end
  return false
end

function validate.app_name(val)
  if val and (#val >= 1) and (#val <= 250) then
    return true
  end
  return false
end

function validate.app_description(val)
  if val and (#val >= 1) and (#val <= 243) then
    return true
  end
  return false
end

function validate.app_uri(val)
  if val and (#val >= 1) and (#val <= 251) and (
    dt.ipaddr(val) or
    uri:new(val)
  ) then
    return true
  end
  return false
end

function validate.app_category(val)
  local _uci = uci.cursor()
  local categories = _uci:get_list("applications","settings","category")
  if (type(val) == "table") then
    for _, cat in pairs(val) do
      if (not util.contains(categories, cat)) then
	return false
      end
    end
  else
    if (not util.contains(categories, val)) then
      return false
    end
  end
  return true
end

function validate.ttl(val)
  local n = tonumber(val)
  if dt.uinteger(n) and n < 256 then
    return true
  end
  return false
end

function validate.app_icon(val)
  if val and (#val >= 1) and (#val <= 250) and
      val:match("^[a-zA-Z0-9%-%._~:/?#%[%]@!$&'()*+,;=]+$") then
    return true
  end
  return false
end

function validate.app_settings_category(val)
  if val and (#val >= 1) and (#val <= 250) then
    return true
  end
  return false
end

return validate
