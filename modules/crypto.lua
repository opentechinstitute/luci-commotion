--! @file crypto

local uci = require "luci.model.uci"
local sys = require "luci.sys"
local http = require "luci.http"
local string = string

module "luci.commotion.crypto"

local crypto = {}

--! @name ssl_cert_fingerprints
--! @brief Gives the md5 and sha1 fingerprints of uhttpd server.
--! @todo Possibly make this smaller. Readability vs. size 
--! @return md5, sha1 hashes of uhttpd
function crypto.ssl_cert_fingerprints()
   --get cert file from /etc/config/uhttpd
   local cursor = uci.cursor()
   local cert = cursor:get('uhttpd','main','cert')
   --get md5 and sha1 hash's of cert file
   local md5 = sys.exec("md5sum "..cert)
   local sha1 = sys.exec("sha1sum "..cert)
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

--! @brief Redirects a page to https if the path is within the "node" path.
--! @param node  node path to check. Format as such to ensure full path -> "/NODE/" 
--! @param env A table containing the REQUEST_URI and the SERVER_NAME. Can take full luci.http.getenv()
--! @return true if page is not https and user has been redirected to https page.
--! @return false if path does not include node or if using an https connection.
--! @example crypto_check_https.htm
function crypto.check_https(node, env)
   if string.match(env.REQUEST_URI, node) then
	  if env.HTTPS ~= "on" then
		 http.redirect("https://"..env.SERVER_NAME..env.REQUEST_URI)
		 return true
	  end
	  return false
   end
   return false
end

return crypto

