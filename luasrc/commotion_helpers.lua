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

function setFileHandler(location, input_name, file_name)
   --[=[Uploads a file to a specified location, and possible file name.

	  Use:
	  add a call to this function within the index entry function called by an submit button  on a luci page.
	  eg.
	  function index()
	      entry({"admin", "commotion", "submit_clicked"}, call("start_upload"))
	  end
	  function start_upload()
	       setFileHandler("/tmp/", "image", "tmp_image.jpg")
	       local values = luci.http.formvalue()
	       local dl = values["image"] reload_page()
	  end

	  Inputs:
      location: (string) The full path to where the file should be saved.
	  input_name: (string) The name specified by the input html field. <input type="submit" name="input_name_here" value="whatever you want"/>
	  file_name: (string, optional) The optional name you would like the file to be saved as. If left blank the file keeps its uploaded name.

	  --]=]
   local sys = require "luci.sys"
   local fs = require "luci.fs"
   local configLoc = location
   local fp
   luci.http.setfilehandler(
	  function(meta, chunk, eof)
		 log("file handler activated")
		 if not fp then
			complete = nil
			if meta and meta.name == input_name then
			   if file_name ~= nil then
				  log("starting download")
				  fp = io.open(configLoc .. file_name, "w")
			   else
				  log("starting download")
				  fp = io.open(configLoc .. meta.file, "w")
			   end
			else
			   log("file not of specified input type (input name variable)")
			end
			if chunk then
			   fp:write(chunk)
			end
			if eof then
			   fp:close()
			   log("file downloaded")
			end
		 else
			log("unknown error: File handler activated but not completed")
		 end
	  end)
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