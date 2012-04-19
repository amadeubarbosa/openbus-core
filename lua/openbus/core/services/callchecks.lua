local module = {}

function module.getCaller(self)
  local callers = self.access:getCallerChain().callers
  return callers[#callers]
end

return module
