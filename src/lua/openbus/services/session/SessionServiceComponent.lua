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
  -- obtém a referência para o Serviço de Controle de Acesso
  self.accessControlService = 
    oil.newproxy("corbaloc::"..self.config.accessControlServerHost.."/"..
                    self.config.accessControlServerKey, 
                 "IDL:openbusidl/acs/IAccessControlService:1.0")
  if self.accessControlService:_non_existent() then
    io.stderr:write("Servico de controle de acesso nao encontrado.\n")
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- instala o interceptador cliente
  local credentialHolder = CredentialHolder()
  local CONF_DIR = os.getenv("CONF_DIR")
  local interceptorsConfig = 
    assert(loadfile(CONF_DIR.."/advanced/SSInterceptorsConfiguration.lua"))()
  oil.setclientinterceptor(
    ClientInterceptor(interceptorsConfig, credentialHolder))

  -- instala o interceptador servidor
  local picurrent = PICurrent()
  oil.setserverinterceptor(ServerInterceptor(interceptorsConfig, picurrent, 
                                             self.accessControlService))

  -- autentica o serviço, conectando-o ao barramento
  self.connectionManager = 
    ServiceConnectionManager:__init(self.accessControlService,
      credentialHolder, self.config.privateKeyFile,
      self.config.accessControlServiceCertificateFile)

  local success = self.connectionManager:connect(self.name)
  if not success then
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- cria e instala a faceta servidora
  local sessionService = SessionService(self.accessControlService, picurrent)
  local sessionServiceInterface = "IDL:openbusidl/ss/ISessionService:1.0"
  self:addFacet("sessionService", sessionServiceInterface, sessionService)

  -- registra sua oferta de serviço junto ao Serviço de Registro
  local serviceOffer = {
    type = "openbusidl/ss/ISessionService",
    description = "Servico de Sessoes",
    properties = {},
    member = self,
  }
  local registryService = self.accessControlService:getRegistryService()
  if not registryService then
    io.stderr:write("Servico de registro nao encontrado.\n")
    self.accessControlService:logout(self.credential)
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local registryServiceInterface = "IDL:openbusidl/rs/IRegistryService:1.0"
  registryService = registryService:getFacet(registryServiceInterface)
  registryService = oil.narrow(registryService, registryServiceInterface)

  success, self.registryIdentifier = registryService:register(serviceOffer);
  if not success then
    io.stderr:write("Erro ao registrar o servico de sessao.\n")
    self.accessControlService:logout(self.credential)
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

  local registryService = self.accessControlService:getRegistryService()
  registryService:unregister(self.registryIdentifier)

  self.connectionManager:disconnect()

  self.accessControlService = nil
  self.connectionManager = nil

  self:removeFacets()
end
