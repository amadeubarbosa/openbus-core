--
-- openbus.lua
--

require 'oil'

orb = oil.init {flavor = "intercepted;corba;typed;cooperative;base"}
oil.orb = orb

oilcorbaidlstring = oil.corba.idl.string


orb:loadidlfile(os.getenv("OPENBUS_HOME" ).."/idlpath/access_control_service.idl")
orb:loadidlfile(os.getenv("OPENBUS_HOME" ).."/idlpath/registry_service.idl")
orb:loadidlfile(os.getenv("OPENBUS_HOME" ).."/idlpath/session_service.idl")

local lir = orb:getLIR()

IComponent = require 'scs.core.IComponent'

oil.verbose:level(0)
oil.tasks.verbose:level(0)
oil.tasks.verbose:flag("threads", false)

-- Metodo utilizado pelo interceptador do OiL
function sendrequest(credential, credentialType, contextID, request)
  local encoder = orb:newencoder()
  encoder:put(credential, lir:lookup_id(credentialType).type)
  request.service_context =  {
     {context_id = contextID, context_data = encoder:getdata()}
   }
end

if not oil.isrunning then
  oil.isrunning = true
  oil.tasks:register(coroutine.create(function() return orb:run() end))
end

-- Invoke with concurrency
function invoke(func, ...)
  local res
  oil.main (function()
    res = {oil.pcall(func, unpack(arg))}
    oil.tasks:halt()
  end )
  if (not res[1]) then
    error(res[2])
  end --if
  return select(2, unpack(res))
end
