--
-- Interceptador de requisições de serviço, responsável por verificar se
--  o emissor da requisição foi autenticado (possui uma credencial válida)
--
local oil = require "oil"
local oop = require "loop.base"
local verbose = require "Verbose" 

local pairs = pairs
local ipairs = ipairs

module("ServerInterceptor", oop.class)

-- Constrói o interceptador
function __init(self, config, picurrent, accessControlService)
  verbose:interceptor("Construindo interceptador para serviço")
  local lir = oil.getLIR()
  -- obtém as operações que devem ser verificadas, se assim configurado
  local checkedOperations = {}
  local excluded_ops = config.excluded_ops or {}
  if config.interface then
    local iface = lir:resolve(config.interface)
    for op, member in pairs(iface.members) do
      if member._type == "operation" and not excluded_ops[op] then
        checkedOperations[op] = true
        verbose:interceptor("  checar "..op)
      end
    end
  else
    checkedOperations.all = true
    verbose:interceptor("  checar todas as operações")
  end

  return oop.rawnew(self, 
                    { checkedOperations = checkedOperations,
                      credentialType = lir:lookup_id(config.credential_type).type,
                      contextID = config.contextID,
                      picurrent = picurrent,
                      accessControlService = accessControlService })
end

-- Intercepta o request para obtenção da informação de contexto (credencial)
function receiverequest(self, request)
  verbose:interceptor "INTERCEPTAÇÂO SERVIDOR!"

  if not (self.checkedOperations.all or 
          self.checkedOperations[request.operation]) then
    verbose:interceptor ("OPERAÇÂO "..request.operation.." NÂO È CHECADA")
    return
  end
  verbose:interceptor ("OPERAÇÂO "..request.operation.." É CHECADA")

  local credential
  for _, context in ipairs(request.service_context) do
    if context.context_id == self.contextID then
      verbose:interceptor "TEM CREDENCIAL!"
      local decoder = oil.newdecoder(context.context_data)
      credential = decoder:get(self.credentialType)
      verbose:interceptor("CREDENCIAL: "..credential.identifier..","..credential.entityName)
      break
    end
  end

  if credential and self.accessControlService:isValid(credential) then
      verbose:interceptor("CREDENCIAL VALIDADA PARA "..request.operation)
      self.picurrent:setValue(credential)
      return
  end

  -- Credencial inválida ou sem credencial
  if credential then
    verbose:interceptor("\n ***CREDENCIAL INVALIDA ***\n")
  else
    verbose:interceptor("\n***NÂO TEM CREDENCIAL ***\n")
  end
  request.success = false
  request.count = 1
  request[1] = oil.newexcept{"NO_PERMISSION", minor_code_value = 0}
end

--
-- Intercepta a resposta ao request para "limpar" o contexto
--
function sendreply(self, request)
  request.service_context = {}
end
