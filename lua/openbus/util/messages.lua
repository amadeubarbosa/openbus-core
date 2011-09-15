local _G = require "_G"
local setmetatable = _G.setmetatable

local log = require "openbus.core.util.logger"

local oo = require "openbus.util.oo"
local class = oo.class

local function toword(camelcase)
	return camelcase:lower().." "
end

local MissingMessage = class()
function MissingMessage:tag(values)
	return self:__tostring()..log.viewer:tostring(values)
end
function MissingMessage:__tostring()
	return self.message:gsub("%u[%l%d]*", toword)
end

return setmetatable({}, {
	__index = function(_, message)
		return MissingMessage{ message = message }
	end,
})
