--! @file encode

local sys = require "luci.sys"
local string, tostring = string, tostring

module "luci.commotion.encode"

local encode = {}

local html_replacements = {
   ["<"] = "&lt;",
   [">"] = "&gt;",
   ["&"] = "&amp;",
   ["\n"] = "&#10;",
   ["\r"] = "&#13;",
   ["\""] = "&quot;"
   }

local url_replacements = {
   ["<"] = "%3C",
   [">"] = "%3E",
   [" "] = "%20",
   ['"'] = "%22"
   }

--! @name
--! @brief
--! @param
--! @return
function encode.uci(str)
  if (str) then
    str = string.gsub (str, "([^%w])", function(c) return '_' .. tostring(string.byte(c)) end)
  end
  return str
end

--! @name
--! @brief
--! @param
--! @return
function encode.html(str)
  return string.gsub(str,"[<>&\n\r\"]",function(c) return html_replacements[c] or c end)
end

--! @name
--! @brief
--! @param
--! @return
function encode.url(str)
  return string.gsub(str,"[<>%s]",function(c) return url_replacements[c] or c end)
end

return encode

