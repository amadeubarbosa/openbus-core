-- $Id$

local _G = require "_G"
local ipairs = _G.ipairs
local tostring = _G.tostring

local array = require "table"
local concat = array.concat

local lualdap = require "lualdap"
local openldap = lualdap.open_simple

local msg = require "openbus.core.util.messages"

return function(configs)
	local servers = {}
	for index, server in ipairs(configs.ldap) do
		if not server:match("^.+:%d+$") then
			return nil, msg.LdapBadServerSpec:tag{actual=server}
		end
		servers[#servers+1] = server
	end
	if #servers == 0 then
		return nil, msg.LdapNoServers
	end
	local suffixes = configs.ldapsuffix
	if suffixes == nil or #suffixes == 0 then
		suffixes = { "" }
	end
	return function(name, password)
		local errmsg = {}
		for _, server in ipairs(servers) do
			for _, suffix in ipairs(suffixes) do
				local conn, err = openldap(server, name..suffix, password, false, 5)
				if conn ~= nil then
					conn:close()
					return true
				end
				errmsg[#errmsg+1] = msg.LdapAccessAttemptFailed:tag{
					user = name..suffix,
					errmsg = tostring(err),
				}
			end
		end
		return nil, msg.LdapAccessFailed:tag{user=name,errmsg=concat(errmsg)}
	end
end
