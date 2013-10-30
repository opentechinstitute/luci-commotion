--! @file identify

local string, tonumber, tostring = string, tonumber, tostring

module "luci.commotion.identify"

local identify = {}

--! @name is_ip4addr
--! @brief identifies if a string is an ipv4 address
--! @param str string that may, or may not be a ipv4 address.
--! @return true if ipv4 address
--! @return false if not ipv4 address
function identify.is_ip4addr(str)
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


--! @see is_ip4addr
--! @name is_ip4addr_cidr
--! @brief Identifies classless inter-domain routing CIDR formatted IP addr and routing prefix
--! @param str string that may, or may not be a ipv4 address.
--! @return true if ipv4 address and prefix size per CIDR notation
--! @return false if not CIDR notated IP addr and routing prefix
function identify.is_ip4addr_cidr(str)
	local i,j, _1, _2 = string.find(str, '^(.+)/(%d+)$')
	if i and identify.is_ip4addr(_1) and tonumber(_2) >= 0 and tonumber(_2) <= 32 then
		return true
	end
	return false
end

--! @name is_ssid
--! @brief Identifies a properly formatted SSID
--! @param str string that may, or may not be a ipv4 address.
--! @return str if correctly formatted
--! @return nil if incorrectly formatted
function identify.is_ssid(str)
   -- SSID can have almost anything in it
   if #tostring(str) < 32 then
	  return tostring(str):match("^[%w%p]+[%s]*[%w%p]*]*$")
   else
	  return nil
   end
end

--! @name is_mode
--! @brief Checks if a string is a properly formatted mode.
--! @param str string that may, or may not be a mode
--! @return str if properly formatted
--! @return nil if string is not proper format for a mode
function identify.is_mode(str)
   -- Modes are simple, but also match the "-" in Ad-Hoc
   return tostring(str):match("^[%w%-]*$")
end

--! @name is_chan
--! @brief Identifies if the string passed to it is a properly formatted channel
--! @param str string that is thought to be a channel
--! @return number If properly formatted the channel string as a number 
--! return nil if incorrectly formatted channel
function identify.is_chan(str)
   -- Channels are plain digits
   return tonumber(string.match(str, "^[%d]+$"))
end

--! @name is_bitrate
--! @brief Identifies if the value passed to it is the bitrate
--! @param br string that may be a bitrate value with speed  
--! @return str if properly formatted
--! @return nil if string is not proper bit rate
function identify.is_bitRate(br)
   -- Bitrate can start with a space and we want to display Mb/s
   return br:match("^[%s]?[%d%.]*[%s][%/%a]+$")
end

--! @name is_email
--! @brief Identifies if a string is a properly formatted email.
--! @param email string that represents an e-mail.
--! @return email if properly formatted
--! @return nil if string is not proper bit rate
function identify.is_email(email)
   return tostring(email):match("^[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?$")
end

--! @name is_hostname
--! @brief Identifies if a string is a properly formatted hostname.
--! @param str a string that contains a hostname. 
--! @return str if it is properly formatted
--! @return nil if string is not properly formatted
function identify.is_hostname(str)
--alphanumeric and hyphen Less than 63 chars
--cannot start or end with a hyphen
   if #tostring(str) < 63 then
	  return tostring(str):match("^%w[%w%-]*%w$")
   else
	  return nil
   end
end

--! @name is_macaddr
--! @brief Identifies if a string is a properly formatted mac address.
--! @param str a string that contains a  macaddress. 
--! @return true if str passed is a macaddress
--! @return false if str in an unproperly formatted mac adress
function identify.is_macaddr(str)
  local i,j, _1, _2, _3, _4, _5, _6 = string.find(str, '^(%x%x):(%x%x):(%x%x):(%x%x):(%x%x):(%x%x)$')
	if i then return true end
	return false
end

--! @name is_uint
--! @brief Identifies if a string is a properly formatted unsigned intiger.
--! @param str str a string that is assumed to be a usigned int
--! @return the string if it is formatted as an unsigned integer or nil if it is not formatted correctly
function identify.is_uint(str)
	return str:find("^%d+$")
end

--! @name is_fqdn
--! @brief Identifies if a string is a properly formatted fully qualified domain name.
--! @param str str a string that is assumed to be a usigned fully qualified domain name
--! @return the string if it is formatted as a fully qualified domain name or nil if it is not formatted correctly
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


--! @name is_hex
--! @brief Identifies if a string is a properly formatted set of hexidecimal strings.
--! @param str a string that is assumed to only consists of hexideicmal chars
--! @return 
function identify.is_hex(str)
	return str:find("^%x+$")
end

--! @name is_port
--! @brief Identifies if a string of a number is a legitmate port number.
--! @param str a string that is assumed to be a port
--! @return returns the port number as a number 
function identify.is_port(str)
	return identify.is_uint(str) and tonumber(str) >= 0 and tonumber(str) <= 65535
end

return identify

