local idl = require "openbus.core.idl"
local UnauthorizedOperation = idl.throw.services.UnauthorizedOperation

local module = {}

function module.assertCaller(self, owner)
  local entity = self.access:getCallerChain().caller.entity
  local logtag
  if entity == owner then
    logtag = "request"
  elseif self.admins[entity] ~= nil then
    logtag = "admin"
  else
    UnauthorizedOperation()
  end
  return logtag
end

return module