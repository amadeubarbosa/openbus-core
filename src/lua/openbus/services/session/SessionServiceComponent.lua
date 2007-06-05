-----------------------------------------------------------------------------
-- Componente (membro) responsável pelo Serviço de Sessão
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

require "openbus.services.session.SessionService"

local oop = require "loop.simple"

SessionServiceComponent = oop.class({}, Member)

function SessionServiceComponent:__init(name)
  local obj = { name = name,
                config = SessionServerConfiguration,
              }
  Member:__init(obj)
  return oop.rawnew(self, obj)
end

function SessionServiceComponent:startup()
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
    assert(loadfile(CONF_DIR.."/advanced/SSInterceptorsConfiguration.lua"))()
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
  local sessionService = SessionService(accessControlService, picurrent)
  local sessionServiceInterface = "IDL:openbusidl/ss/ISessionService:1.0"
  self:addFacet("sessionService", sessionServiceInterface, sessionService)

  -- registra sua oferta de serviço junto ao Serviço de Registro
  local offerType = self.config.sessionServiceOfferType
  local serviceOffer = {
    type = offerType,
    description = "Servico de Sessoes",
    properties = {},
    member = self,
  }
  local registryService = accessControlService:getRegistryService()
  if not registryService then
    log:error("Servico de registro nao encontrado.\n")
    self.connectionManager:disconnect()
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local registryServiceInterface = "IDL:openbusidl/rs/IRegistryService:1.0"
  registryService = registryService:getFacet(registryServiceInterface)
  registryService = oil.narrow(registryService, registryServiceInterface)

  success, self.registryIdentifier = registryService:register(serviceOffer);
  if not success then
    log:error("Erro ao registrar oferta do servico de sessao.\n")
    self.connectionManager:disconntect()
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  self.started = true
end

function SessionServiceComponent:shutdown()
  if not self.started then
    io.stderr:write("Servico ja foi finalizado.\n")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  local accessControlService = self.connectionManager:getAccessControlService()
  local registryService = accessControlService:getRegistryService()
  registryService:unregister(self.registryIdentifier)

  self.connectionManager:disconnect()
  self.connectionManager = nil

  self:removeFacets()
end
