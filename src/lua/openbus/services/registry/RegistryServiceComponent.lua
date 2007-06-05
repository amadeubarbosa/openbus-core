-----------------------------------------------------------------------------
-- Componente (membro) responsável pelo Serviço de Registro
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "oil"
require "openbus.Member"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local CredentialHolder = require "openbus.common.CredentialHolder"
local PICurrent = require "openbus.common.PICurrent"
local log = require "openbus.common.Log"
local ServiceConnectionManager = require "openbus.common.ServiceConnectionManager"

require "openbus.services.registry.RegistryService"

local oop = require "loop.simple"

RegistryServiceComponent = oop.class({}, Member)

function RegistryServiceComponent:__init(name)
  local obj = { name = name,
                config = RegistryServerConfiguration,
              }
  Member:__init(obj)
  return oop.rawnew(self, obj)
end

function RegistryServiceComponent:startup()
  local credentialHolder = CredentialHolder()
  self.connectionManager = 
    ServiceConnectionManager:__init(self.config.accessControlServerHost,
      credentialHolder, self.config.privateKeyFile, 
      self.config.accessControlServiceCertificateFile)
  
  -- obtém a referência para o Serviço de Controle de Acesso
  local accessControlService = self.connectionManager:getAccessControlService()
  if accessControlService == nil then
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- instala o interceptador cliente
  local CONF_DIR = os.getenv("CONF_DIR")
  local interceptorsConfig = 
    assert(loadfile(CONF_DIR.."/advanced/RSInterceptorsConfiguration.lua"))()
  oil.setclientinterceptor(
    ClientInterceptor(interceptorsConfig, credentialHolder))

  -- instala o interceptador servidor
  local picurrent = PICurrent()
  oil.setserverinterceptor(ServerInterceptor(interceptorsConfig, picurrent, 
                                             accessControlService))

  -- autentica o serviço, conectando-o ao barramento

  local success = self.connectionManager:connect(self.name)
  if not success then
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- cria e instala a faceta servidora
  local registryService = RegistryService(accessControlService, picurrent)
  local registryServiceInterface = "IDL:openbusidl/rs/IRegistryService:1.0"
  registryService = self:addFacet("registryService", registryServiceInterface,
                                  registryService)
  accessControlService:setRegistryService(self)

  self.started = true
end

function RegistryServiceComponent:shutdown()
  if not self.started then
    log:error("Servico ja foi finalizado.")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  self.connectionManager:disconnect()
  self.connectionManager = nil

  self:removeFacets()
end
