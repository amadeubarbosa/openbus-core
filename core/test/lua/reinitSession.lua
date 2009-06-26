--
-- Testa a reinicialização dos serviço de sessão
--
-- $Id$
--
local oil = require "oil"

local orb = oil.init {flavor = "intercepted;corba;typed;cooperative;base",}
oil.orb = orb

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local ClientConnectionManager = require "openbus.common.ClientConnectionManager"

oil.verbose:level(3)

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  Log:error("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end
orb:loadidlfile(IDLPATH_DIR.."/session_service.idl")
orb:loadidlfile(IDLPATH_DIR.."/registry_service.idl")
orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")

function main()
  -- Aloca uma thread para o oil
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
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
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  if DATA_DIR == nil then
    error("ERRO: A variavel OPENBUS_DATADIR nao foi definida.\n")
  end
    local config =
      assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
    orb:setclientinterceptor(ClientInterceptor(config, credentialManager))

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

  local offers = registryService:find({
        {name = "facets", value = {"sessionService"}},
      })
  if #offers == 0 then
    error("ERRO: Não obteve oferta de serviço de sessão")
  end
  local sessionServiceComponent = orb:narrow(offers[1].member,
                 "IDL:scs/core/IComponent:1.0")
  local sessionServiceInterface = "IDL:openbusidl/ss/ISessionService:1.0"
  local sessionService =
    sessionServiceComponent:getFacet(sessionServiceInterface)
  sessionService = orb:narrow(sessionService, sessionServiceInterface)
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
