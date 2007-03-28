--
-- Componente (membro) responsável pelo Serviço de Sessão
--
-- $Id$
--
require "Member"
require "SessionService"

require "oil"
require "ClientInterceptor"
require "ServerInterceptor"
require "CredentialHolder"
require "PICurrent"

local oop = require "loop.simple"

SessionServiceComponent = oop.class({}, Member)

function SessionServiceComponent:startup()

  -- obtém a referência para o Serviço de Controle de Acesso
  local accessControlServiceComponent = 
    oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..
                    self.accessControlServerKey, 
                 "IDL:OpenBus/ACS/IAccessControlServiceComponent:1.0")
  if accessControlServiceComponent:_non_existent() then
    print("Servico de controle de acesso nao encontrado.")
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local accessControlServiceInterface = 
      "IDL:OpenBus/ACS/IAccessControlService:1.0"
  self.accessControlService = 
    accessControlServiceComponent:getFacet(accessControlServiceInterface)
  self.accessControlService = 
    oil.narrow(self.accessControlService, accessControlServiceInterface)

  -- autenticação junto ao Serviço de Controle de Acesso
  local success
  success, self.credential = 
    self.accessControlService:loginByCertificate("SessionService", "")
  if not success then
    print("Nao foi possivel logar no servico de controle de acesso.")
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- instala o interceptador cliente
  local CONF_DIR = os.getenv("CONF_DIR")
  local interceptorsConfig = 
    assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
  self.credentialHolder = CredentialHolder()
  self.credentialHolder:setValue(self.credential)
  oil.setclientinterceptor(ClientInterceptor(interceptorsConfig, 
                           self.credentialHolder))

  -- instala o interceptador servidor
  local picurrent = PICurrent()
  oil.setserverinterceptor(ServerInterceptor(interceptorsConfig, picurrent, 
                                             self.accessControlService))

  -- cria e instala a faceta servidora
  local sessionService = SessionService(picurrent)
  local sessionServiceInterface = "IDL:OpenBus/SS/ISessionService:1.0"
  self:addFacet("sessionService", sessionServiceInterface, sessionService)

  -- registra sua oferta de serviço junto ao Serviço de Registro
  local serviceOffer = {
    type = "OpenBus/SS/ISessionService",
    description = "Servico de Sessoes",
    properties = {},
    member = self,
  }
  local registryService = self.accessControlService:getRegistryService()
  if not registryService then
    print("Servico de registro nao encontrado.")
    self.accessControlService:logout(self.credential)
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local registryServiceInterface = "IDL:OpenBus/RS/IRegistryService:1.0"
  registryService = registryService:getFacet(registryServiceInterface)
  registryService = oil.narrow(registryService, registryServiceInterface)

  success, self.registryIdentifier = registryService:register(serviceOffer);
  if not success then
    print("Erro ao registrar o servico de sessao.")
    self.accessControlService:logout(self.credential)
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  self.started = true
end

function SessionServiceComponent:shutdown()
  if not self.started then
    print("Servico ja foi finalizado.")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  local registryService = self.accessControlService:getRegistryService()
  registryService:unregister(self.registryIdentifier)
  self.accessControlService:logout(self.credential)
  self.credentialHolder:invalidate()

  self.accessControlService = nil
  self.credential = nil

  self:removeFacets()
end
