--
-- Testa o envio de eventos em uma sessão
--
-- $Id$
--
package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
local oil = require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"
local ClientConnectionManager = require "openbus.common.ClientConnectionManager"

local IComponent = require "scs.core.IComponent"

local CORE_IDL_DIR = os.getenv("CORE_IDL_DIR")
if CORE_IDL_DIR == nil then
  error("ERRO: A variavel CORE_IDL_DIR nao foi definida.\n")
end

oil.loadidlfile(CORE_IDL_DIR.."/session_service.idl")
oil.loadidlfile(CORE_IDL_DIR.."/registry_service.idl")
oil.loadidlfile(CORE_IDL_DIR.."/access_control_service.idl")

local createSink = function(name)
   return {
     push = function(self, event)
              local val = event.value. _anyval
              print("Evento "..event.type.." valor "..val..
                    " recebido por "..name)
            end,
     disconnect = function(self)
                    print("Aviso de desconexão para "..name)
                  end,
   }
end

function main()
  -- Aloca uma thread para o oil
  local success, res = oil.pcall(oil.newthread, oil.run)
  if not success then
    error("ERRO: Falha na execução da thread do oil")
  end

  local user = "tester"
  local password = "tester"

  -- Conecta o cliente ao barramento
  local credentialManager = CredentialManager()
  local connectionManager =
    ClientConnectionManager("localhost:2089", credentialManager, user, password)

  -- obtém a referência para o Serviço de Controle de Acesso
  local accessControlService = connectionManager:getAccessControlService()
  if accessControlService == nil then
    error("ERRO: Não obteve serviço de controle de acesso")
  end

  -- instala o interceptador de cliente
  local CONF_DIR = os.getenv("CONF_DIR")
  if CONF_DIR == nil then
    error("ERRO: A variavel CONF_DIR nao foi definida.\n")
  end
    local config =
      assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
    oil.setclientinterceptor(ClientInterceptor(config, credentialManager))

  -- autentica o cliente
  success = connectionManager:connect()
  print("Cliente autenticado!")

  local registryService = accessControlService:getRegistryService()
  if not registryService then
    error("ERRO: Não obteve referência para serviço de registro")
  end
  print("Obteve referencia para o serviço de registro")

  local offers = registryService:find("SessionService",{})
  if #offers == 0 then
    error("ERRO: Não obteve oferta de serviço de sessão")
  end
  local sessionServiceComponent = oil.narrow(offers[1].member,
                 "IDL:scs/core/IComponent:1.0")
  local sessionServiceInterface = "IDL:openbusidl/ss/ISessionService:1.0"
  local sessionService =
    sessionServiceComponent:getFacet(sessionServiceInterface)
  sessionService = oil.narrow(sessionService, sessionServiceInterface)
  print("Obteve referencia para o serviço de sessão")

  -- cria sessão com membros receptores de eventos
  local eventSinkInterface = "IDL:openbusidl/ss/SessionEventSink:1.0"
  local member1 = IComponent("membro1", 1, 0, 0, "")
  member1 = oil.newservant(member1, "IDL:scs/core/IComponent:1.0")
  member1:addFacet("sink1", eventSinkInterface, createSink("sink1"))
  local success, session, id1 = sessionService:createSession(member1)

  local member2 = IComponent("membro2", 1, 0, 0, "")
  member2 = oil.newservant(member2, "IDL:scs/core/IComponent:1.0")
  member2:addFacet("sink2", eventSinkInterface, createSink("sink2"))
  local id2 = session:addMember(member2)

  -- adiciona membro não receptor
  local member3 = IComponent("membro3", 1, 0, 0, "")
  member3 = oil.newservant(member3, "IDL:scs/core/IComponent:1.0")
  local id3 = session:addMember(member3)

  -- envio de eventos
  local my_any_value1 = { _anyval = "valor1", _anytype = oil.corba.idl.string }
  local my_any_value2 = { _anyval = "valor2", _anytype = oil.corba.idl.string }
  session:push({type = "tipo1", value = my_any_value1})
  session:push({type = "tipo2", value = my_any_value2})

  session:disconnect()

  -- remove o segundo e o terceiro membros do barramento
  session:removeMember(id2)
  session:removeMember(id3)

  -- desconecta o cliente do barramento
  connectionManager:disconnect()
  print("Cliente desconectado")
  os.exit(0)
end

print(oil.pcall(oil.main, main))
