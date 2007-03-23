--
-- Interceptador de requisições de serviço, responsável por verificar se
--  o emissor da requisição foi autenticado (possui uma credencial válida)
--
local oil = require "oil"
local oop = require "loop.base"

local print = print
local pairs = pairs
local ipairs = ipairs

module("ServerInterceptor", oop.class)

-- Constrói o interceptador
function __init(self, config, accessControlService)

  print("Construindo interceptador para serviço")
  local lir = oil.getLIR()
  -- obtém as operações que devem ser verificadas, se assim configurado
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
    print("  checar todas as operações")
  end

  return oop.rawnew(self, 
                    { checkedOperations = checkedOperations,
                      credentialType = lir:lookup_id(config.credential_type).type,
                      contextID = config.contextID,
                      accessControlService = accessControlService })
end

-- Intercepta o request para obtenção da informação de contexto (credencial)
function receiverequest(self, request)
  print "INTERCEPTAÇÂO SERVIDOR!"

  if not (self.checkedOperations.all or 
          self.checkedOperations[request.operation]) then
    print ("OPERAÇÂO "..request.operation.." NÂO È CHECADA")
    return
  end
  print ("OPERAÇÂO "..request.operation.." É CHECADA")

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
    print "NÂO TEM CREDENCIAL"
    -- mandar exceção quando interceptadores clientes forem implementados !!!
  end
end

--
-- Intercepta a resposta ao request para "limpar" o contexto
--
function sendreply(self, request)
  request.service_context = {}
end
