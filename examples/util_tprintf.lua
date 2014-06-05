signing_tmpl = [[<type>_${type}._tcp</type>
<domain-name>mesh.local</domain-name>
<port>${port}</port>
<txt-record>application=${name}</txt-record>
<txt-record>ttl=${ttl}</txt-record>
<txt-record>ipaddr=${ipaddr}</txt-record>]]

values = {type="the best", port=123, name="bob", ttl=1, ipaddr="192.169.1.1"}

local chu = require "luci.commotion.util"

new_template = chu.tprintf(signing_tmpl, values)
