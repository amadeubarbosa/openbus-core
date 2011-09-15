local _G = require "_G"
local error = _G.error

local table = require "loop.table"
local memoize = table.memoize

local log = require "openbus.core.util.logger"
local msg = require "openbus.core.util.messages"

return memoize(function(name)
	local repId = "IDL:omg.org/CORBA/"..name..":1.0"
	return function(fields)
		fields[1] = repId
		log:exception(msg.CorbaExceptionRaised:tag(fields))
		error(fields)
	end
end)
