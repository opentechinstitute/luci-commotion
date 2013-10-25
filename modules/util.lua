--! @file util

string = string

module "luci.commotion.util"

local util = {}

--! @name
--! @brief
--! @param
--! @return
function util.printf(tmpl,t)
	return (tmpl:gsub('($%b{})', function(w) return t[w:sub(3, -2)] or w end))
end

return util

