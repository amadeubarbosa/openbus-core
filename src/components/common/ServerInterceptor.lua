--
-- Interceptador de requisi��es de servi�o, respons�vel por verificar se
--  o emissor da requisi��o foi autenticado (possui uma credencial v�lida)
--
local oil = require "oil"
local oop = require "loop.base"

local print = print
local pairs = pairs
local ipairs = ipairs

module("ServerInterceptor", oop.class)

-- Constr�i o interceptador
function __init(self, config, accessControlService)

  print("Construindo interceptador para servi�o")
  local lir = oil.getLIR()
  -- obt�m as opera��es que devem ser verificadas, se assim configurado
  local checkedOperations = {}
  local excluded_ops = config.excluded_ops or {}
  if config.interface then
    local iface = lir:resolve(config.interface)
    for op, member in pairs(iface.members) do
      if member._type == "operation" and not excluded_ops[op] then
        checkedOperations[op] = true
        print("  checar "..op)
      end
    end
  else
    checkedOperations.all = true
    print("  checar todas as opera��es")
  end

  return oop.rawnew(self, 
                    { checkedOperations = checkedOperations,
                      credentialType = lir:lookup_id(config.credential_type).type,
                      contextID = config.contextID,
                      accessControlService = accessControlService })
end

-- Intercepta o request para obten��o da informa��o de contexto (credencial)
function receiverequest(self, request)
  print "INTERCEPTA��O SERVIDOR!"

  if not (self.checkedOperations.all or 
          self.checkedOperations[request.operation]) then
    print ("OPERA��O "..request.operation.." N�O � CHECADA")
    return
  end
  print ("OPERA��O "..request.operation.." � CHECADA")

  local credential
  for _, context in ipairs(request.service_context) do
    if context.context_id == self.contextID then
      print "TEM CREDENCIAL!"
      local decoder = oil.newdecoder(context.context_data)
      credential = decoder:get(self.credentialType)
      print("CREDENCIAL: "..credential.identifier..","..credential.entityName)
      break
    end
  end

  if credential then
    if self.accessControlService:isValid(credential) then
      print "CREDENCIAL VALIDADA"
    else
      print "CREDENCIAL INVALIDA"
      request.success = false
      request.count = 1
      request[1] = oil.newexcept{"NO_PERMISSION", minor_code_value = 0}
    end
  else
    print "N�O TEM CREDENCIAL"
    -- mandar exce��o quando interceptadores clientes forem implementados !!!
  end
end

--
-- Intercepta a resposta ao request para "limpar" o contexto
--
function sendreply(self, request)
  request.service_context = {}
end
