function DIE(str)
	luci.http.status(500, "Internal Server Error")
	luci.http.write(str)
	luci.http.close()
end

--- Redirects a page to https if the path is within the "node" path.
-- @param node  node path to check. format as such -> "/NODE/" 
-- @param env A table containing the REQUEST_URI and the SERVER_NAME. Can take full luci.http.getenv()
-- @return True if page is to be redirected. False if path does not include node or if https is already on.
function check_https(node, env)
   if string.match(env.REQUEST_URI, node) then
	  if env.HTTPS ~= "on" then
		 luci.http.redirect("https://"..env.SERVER_NAME..env.REQUEST_URI)
		 return true
	  end
	  return false
   end
   return false
end

--- Gives the md5 and sha1 fingerprints of uhttpd server.
--- Call as such: md5, sha1 = ssl_cert_fingerprints() If you only give one var name it will only give you md5. Call like: _, sha1 = to throw away md5
-- @return md5 and sha1 hash of uhttpd.
function ssl_cert_fingerprints()
   --get cert file from /etc/config/uhttpd
   local uci = luci.model.uci.cursor()
   local cert = uci:get('uhttpd','main','cert')
   --get md5 and sha1 hash's of cert file
   local md5 = luci.sys.exec("md5sum "..cert)
   local sha1 = luci.sys.exec("sha1sum "..cert)
   -- remove the filename and extra spaces then uppercase the cert string
   sha1 = string.upper(sha1:match("(%w*)%s*"..cert))
   md5 = string.upper(md5:match("(%w*)%s*"..cert))
   --add colons between pairs of two chars
   sha1 = sha1:gsub("(%w%w)", "%1:")
   md5 = md5:gsub("(%w%w)", "%1:")
   --remove the final colon
   sha1 = sha1:sub(1, -2)
   md5 = md5:sub(1,-2)
   return md5, sha1
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
	local i,j, _1, _2, _3, _4 = string.find(str, '^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$')
	if (i and 
	    (tonumber(_1) >= 0 and tonumber(_1) <= 255) and
	    (tonumber(_2) >= 0 and tonumber(_2) <= 255) and
	    (tonumber(_3) >= 0 and tonumber(_3) <= 255) and
	    (tonumber(_4) >= 0 and tonumber(_4) <= 255)) then
		return true
	end
	return false
end

function is_ip4addr_cidr(str)
	local i,j, _1, _2 = string.find(str, '^(.+)/(%d+)$')
	if i and is_ip4addr(_1) and tonumber(_2) >= 0 and tonumber(_2) <= 32 then
		return true
	end
	return false
end

function is_ssid(str)
   -- SSID can have almost anything in it
   if #tostring(str) < 32 then
	  return tostring(str):match("[%w%p]+[%s]*[%w%p]*]*")
   else
	  return nil
   end
end

function is_mode(str)
   -- Modes are simple, but also match the "-" in Ad-Hoc
   return tostring(str):match("[%w%-]*")
end

function is_chan(str)
   -- Channels are plain digits
   return tonumber(string.match(str, "[%d]+"))
end

function is_bitRate(br)
   -- Bitrate can start with a space and we want to display Mb/s
   return br:match("[%s]?[%d%.]*[%s][%/%a]+")
end

function is_email(email)
   return tostring(email):match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?")
end

function is_hostname(str)
--alphanumeric and hyphen Less than 63 chars
--cannot start or end with a hyphen
   if #tostring(str) < 63 then
	  return tostring(str):match("^%w[%w%-]*%w$")
   else
	  return nil
   end
end

function is_fqdn(str)
-- alphanumeric and hyphen less than 255 chars
-- each label must be less than 63 chars
   if #tostring(str) < 255 then
	-- Should check that each label is < 63 chars --
	return tostring(str):match("^[%w%.%-]+$")
   else
	return nil
   end
end

function is_macaddr(str)
  local i,j, _1, _2, _3, _4, _5, _6 = string.find(str, '^(%x%x):(%x%x):(%x%x):(%x%x):(%x%x):(%x%x)$')
	if i then return true end
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

function is_valid_uci(str)
	return str:find("^[%w_]+$")
end

function pass_to_shell(str)
	return str:gsub("$(","\\$"):gsub("`","\\`")
end

function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function list_ifaces()
  local uci = luci.model.uci.cursor()
  local r = {zone_to_iface = {}, iface_to_zone = {}}
  uci:foreach("network", "interface", 
    function(zone)
      if zone['.name'] == 'loopback' then return end
      local iface = luci.sys.exec("ubus call network.interface." .. zone['.name'] .. " status |grep '\"device\"' | cut -d '\"' -f 4"):gsub("%s$","")
      r.zone_to_iface[zone['.name']]=iface
      r.iface_to_zone[iface]=zone['.name']
    end
  )
  return r
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
