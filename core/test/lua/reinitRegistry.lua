--
-- Testa a reinicialização do serviço de registro
--
-- $Id$
--
package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
local oil = require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"
local ClientConnectionManager = require "openbus.common.ClientConnectionManager"

oil.verbose:level(3)

local CORE_IDL_DIR = os.getenv("CORE_IDL_DIR")
if CORE_IDL_DIR == nil then
  error("ERRO: A variavel CORE_IDL_DIR nao foi definida.\n")
end

oil.loadidlfile(CORE_IDL_DIR.."/registry_service.idl")
oil.loadidlfile(CORE_IDL_DIR.."/access_control_service.idl")

function main()
  -- Aloca uma thread para o oil
  local success, res = oil.pcall(oil.newthread, oil.run)
  if not success then
    error("ERRO: Falha na execução da thread do oil")
  end

  local user = "tester"
  local password = "tester"

  -- Conecta o cliente ao barramento
  local credentialManager= CredentialManager()
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

  registryService:shutdown()
  print("Shutdown do serviço de registro")

  registryService:startup()
  print("Startup do serviço de registro")

  -- desconecta o cliente do barramento
  connectionManager:disconnect()
  print("Cliente desconectado")
  os.exit(0)
end

print(oil.pcall(oil.main, main))
