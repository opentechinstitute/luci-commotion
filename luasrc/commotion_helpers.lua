function DIE(str)
	luci.http.status(500, "Internal Server Error")
	luci.http.write(str)
	luci.http.close()
end

function uci_encode(str)
  if (str) then
    str = string.gsub (str, "([^%w])", function(c) return '_' .. tostring(string.byte(c)) end)
  end
  return str
end

function html_encode(str)
  return string.gsub(str,"[<>&\n\r\"]",function(c) return html_replacements[c] or c end)
end

function url_encode(str)
  return string.gsub(str,"[<>%s]",function(c) return url_replacements[c] or c end)
end

function printf(tmpl,t)
	return (tmpl:gsub('($%b{})', function(w) return t[w:sub(3, -2)] or w end))
end

function log(msg)
	if (type(msg) == "table") then
		for key, val in pairs(msg) do
			log('{')
			log(key)
			log(':')
			log(val)
			log('}')
		end
	else
		luci.sys.exec("logger -t luci \"" .. tostring(msg) .. '"')
	end
end

function is_ip4addr(str)
	i,j, _1, _2, _3, _4 = string.find(str, '^(%d%d?%d?)\.(%d%d?%d?)\.(%d%d?%d?)\.(%d%d?%d?)$')
	if (i and 
	    (tonumber(_1) >= 0 and tonumber(_1) <= 255) and
	    (tonumber(_2) >= 0 and tonumber(_2) <= 255) and
	    (tonumber(_3) >= 0 and tonumber(_3) <= 255) and
	    (tonumber(_4) >= 0 and tonumber(_4) <= 255)) then
		return true
	end
	return false
end

function is_uint(str)
	return str:find("^%d+$")
end

function is_hex(str)
	return str:find("^%x+$")
end

function is_port(str)
	return is_uint(str) and tonumber(str) >= 0 and tonumber(str) <= 65535
end

function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

html_replacements = {
   ["<"] = "&lt;",
   [">"] = "&gt;",
   ["&"] = "&amp;",
   ["\n"] = "&#10;",
   ["\r"] = "&#13;",
   ["\""] = "&quot;"
   }

url_replacements = {
   ["<"] = "%3C",
   [">"] = "%3E",
   [" "] = "%20",
   ['"'] = "%22"
   }