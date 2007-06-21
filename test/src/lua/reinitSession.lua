--
-- Testa a reinicialização dos serviço de sessão
--
-- $Id$
--
require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialHolder = require "openbus.common.CredentialHolder"
local ClientConnectionManager = require "openbus.common.ClientConnectionManager"

require "openbus.Member"

oil.verbose:level(3)

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
  error("ERRO: A variavel CORBA_IDL_DIR nao foi definida.\n")
end

oil.loadidlfile(CORBA_IDL_DIR.."/session_service.idl")
oil.loadidlfile(CORBA_IDL_DIR.."/registry_service.idl")
oil.loadidlfile(CORBA_IDL_DIR.."/access_control_service.idl")

function main()
  -- Aloca uma thread para o oil
  local success, res = oil.pcall(oil.newthread, oil.run)
  if not success then
    error("ERRO: Falha na execução da thread do oil")
  end

  local user = "csbase"
  local password = "csbLDAPtest"

  -- Conecta o cliente ao barramento
  local credentialHolder = CredentialHolder()
  local connectionManager =
    ClientConnectionManager("localhost:2089", credentialHolder, user, password)

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
    oil.setclientinterceptor(ClientInterceptor(config, credentialHolder))
  
  -- autentica o cliente
  success = connectionManager:connect()
  print("Cliente autenticado!")
  
  local registryService = accessControlService:getRegistryService()
  if not registryService then
    error("ERRO: Não obteve referência para serviço de registro")
  end
  print("Obteve referencia para o serviço de registro")

  print("Aguardando...\n")
  io.read()

  local offers = registryService:find("SessionService",{})
  if #offers == 0 then
    error("ERRO: Não obteve oferta de serviço de sessão")
  end
  local sessionServiceComponent = oil.narrow(offers[1].member, 
                 "IDL:openbusidl/ss/ISessionServiceComponent:1.0")
  local sessionServiceInterface = "IDL:openbusidl/ss/ISessionService:1.0"
  local sessionService = 
    sessionServiceComponent:getFacet(sessionServiceInterface)
  sessionService = oil.narrow(sessionService, sessionServiceInterface)
  print("Obteve referencia para o serviço de sessão")

  sessionServiceComponent:shutdown()
  print("Shutdown do serviço de sessão")

  sessionServiceComponent:startup()
  print("Startup do serviço de sessão")

  -- desconecta o cliente do barramento
  connectionManager:disconnect()
  print("Cliente desconectado")
  os.exit(0)
end

print(oil.pcall(oil.main, main))
