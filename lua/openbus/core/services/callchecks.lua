local sysex = require "openbus.util.sysex"
local NO_PERMISSION = sysex.NO_PERMISSION

local idl = require "openbus.core.idl"
local NoLoginCode = idl.const.services.access_control.NoLoginCode
local UnauthorizedOperation = idl.throw.services.UnauthorizedOperation

local function assertCaller(self)
  local chain = self.access:getCallerChain()
  if chain == nil then
    NO_PERMISSION{
      minor = NoLoginCode,
      completed = "COMPLETED_NO",
    }
  end
  local callers = chain.callers
  return callers[#callers]
end

local module = { assertCaller = assertCaller }

function module.assertAdmin(self, owner)
  local caller = assertCaller(self)
  local entity = caller.entity
  local logtag
  if entity == owner then
    logtag = "request"
  elseif self.admins[entity] ~= nil then
    logtag = "admin"
  else
    UnauthorizedOperation()
  end
  return caller, logtag
end

return module
