--! @file encode

local sys = require "luci.sys"
local string, tostring = string, tostring

module "luci.commotion.encode"

local encode = {}

--! @name html_replacements
--! @brief A table of html replacements
local html_replacements = {
   ["<"] = "&lt;",
   [">"] = "&gt;",
   ["&"] = "&amp;",
   ["\n"] = "&#10;",
   ["\r"] = "&#13;",
   ["\""] = "&quot;"
   }

--! @name url_replacements
--! @brief A table of url replacements
local url_replacements = {
   ["<"] = "%3C",
   [">"] = "%3E",
   [" "] = "%20",
   ['"'] = "%22"
   }

--! @name uci
--! @brief replaces non alphanumeric characters in a string with an underscore followed by a numerical representation of the character
--! @param str a string to be translated to be uci compliant.
--! @return the string formatted to be uci compliant.
function encode.uci(str)
  if (str) then
    str = string.gsub (str, "([^%w])", function(c) return '_' .. tostring(string.byte(c)) end)
  end
  return str
end

--! @name html
--! @brief  translates a html address into a properly encoded html
--! @param str a html address string to be encoded into a properly formatted encoded html address
--! @return a properly formatted encoded html address, if it was a html address to begin with
function encode.html(str)
  if (str) then
    str = string.gsub(str,"[<>&\n\r\"]",function(c) return html_replacements[c] or c end)
  end
  return str
end

--! @name url
--! @brief translates a url into a encoded url
--! @param str a url string to be made into a properly formatted encoded url
--! @return a properly formatted encoded url, if it was a url to begin with 
function encode.url(str)
  if (str) then
    str = string.gsub(str,"[<>%s]",function(c) return url_replacements[c] or c end)
  end
  return str
end

return encode

