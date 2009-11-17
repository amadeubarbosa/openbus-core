local newproxy     = newproxy
local pairs        = pairs
local print        = print
local setmetatable = setmetatable
local type         = type

local debug = require "debug"

module "fileleak"

local function memoize(f)
	return setmetatable({}, {
		__index = function(self, key)
			local value = f(key)
			self[key] = value
			return value
		end,
	})
end

local lost = memoize(function() return 0 end)
local open = memoize(function() return 0 end)

function showstats()
	for kind, list in pairs{ lost = lost, open = open } do
		for stack, count in pairs(list) do
			if count > 0 then
				print(count.." "..kind.." files created at\n"..stack)
			end
		end
	end
end

function wrapfactory(factory)
	return function(...)
		local res, err = factory(...)
		if res then
			local stack = debug.traceback()
			local meta = { __newindex = res }
			local delegator = memoize(function(method)
				return function(self, ...)
					return method(res, ...)
				end
			end)
			function meta:__gc()
				lost[stack] = lost[stack] + 1
				open[stack] = open[stack] - 1
			end
			local function close(self, ...)
				open[stack] = open[stack] - 1
				meta.__gc = nil
				return res:close(...)
			end
			function meta:__index(field)
				if field == "close" then
					return close
				else
					local value = res[field]
					if type(value) == "function" then
						value = delegator[value]
					end
					return value
				end
			end
			local proxy = newproxy()
			debug.setmetatable(proxy, meta)
			open[stack] = open[stack] + 1
			return proxy
		end
		return res, err
	end
end
