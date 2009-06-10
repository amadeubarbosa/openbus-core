local print = print
local io = io
local assert = assert
local Log = require "openbus.common.Log"
local oop = require "loop.simple"

module ("openbus.common.Properties", oop.class)

function __init(self, fileName)
	local obj = { values = self:loadProperties(fileName) }

	return oop.rawnew(self, obj)
end

function loadProperties(self, fileName)
	local result = {}
	local file = assert(io.open(fileName))

	local linecount = 0
	for line in file:lines() do
	       linecount = linecount + 1
	       if not line:match("^%s*$") and not line:match("^%s*#") then
		       local key, value = line:match("^%s*([^=%s]+)%s*=%s*(.-)%s*$")
		       if key then
		               result[key] = value
		       else
		               error("Erro na linha "..linecount..": "..line)
		       end
	       end
	end
        return result
end

function getProperty(self, key)
	return self.values[key]
end








