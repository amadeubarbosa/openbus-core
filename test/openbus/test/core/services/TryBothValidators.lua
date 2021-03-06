local array = require "table"
local concat = array.concat

local msg = require "openbus.core.services.messages"
local AccessControl = require("openbus.core.services.AccessControl").AccessControl

do -- TODO: resolve this ugly workaround!
	local server = require "openbus.util.server"
	local backup = server.setuplog
	function server.setuplog() end
require "openbus.test.configs"
	server.setuplog = backup
end
local domains = { domain, baddomain }

return function (configs)
	return function (entity, password)
		local errors = {}
		for _, domain in ipairs(domains) do
			local validator = AccessControl.passwordValidators[domain]
			if validator ~= nil then
				local valid, errmsg = validator.validate(entity, password)
				if valid then
					return true
				else
					errors[#errors+1] = msg.FailedPasswordValidation:tag{
						domain = domain,
						entity = entity,
						validator = validator.name,
						errmsg = errmsg,
					}
				end
			else
				errors[#errors+1] = msg.UnknownDomainInTryManyValidator:tag{ domain = domain }
			end
		end
		return false, concat(errors, "; ")
	end
end
