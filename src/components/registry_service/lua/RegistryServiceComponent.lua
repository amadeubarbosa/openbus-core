--
-- Componente (membro) responsável pelo Serviço de Registro
--
-- $Id$
--
require "Member"
require "RegistryService"

require "oil"
require "ClientInterceptor"
require "ServerInterceptor"
require "CredentialHolder"
require "PICurrent"

local oop = require "loop.simple"

RegistryServiceComponent = oop.class({}, Member)

function RegistryServiceComponent:startup()

  -- obtém a referência para o Serviço de Controle de Acesso
  local accessControlServiceComponent = 
  oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..
                  self.accessControlServerKey,
               "IDL:OpenBus/ACS/IAccessControlServiceComponent:1.0")
  if accessControlServiceComponent:_non_existent() then
    io.stderr:write("Servico de controle de acesso nao encontrado.\n")
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local accessControlServiceInterface = 
    "IDL:OpenBus/ACS/IAccessControlService:1.0"
  self.accessControlService = 
    accessControlServiceComponent:getFacet(accessControlServiceInterface)
  self.accessControlService = 
    oil.narrow(self.accessControlService, accessControlServiceInterface)

  -- autenticação junto ao serviço de controle de acesso
  local success
  success, self.credential = 
    self.accessControlService:loginByCertificate("RegistryService", "")
  if not success then
    io.stderr:write("Nao foi possivel logar no servico de controle de acesso.\n")
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- instala o interceptador cliente
  local CONF_DIR = os.getenv("CONF_DIR")
  local interceptorsConfig = 
    assert(loadfile(CONF_DIR.."/advanced/RSInterceptorsConfiguration.lua"))()
  self.credentialHolder = CredentialHolder()
  self.credentialHolder:setValue(self.credential)
  oil.setclientinterceptor(ClientInterceptor(interceptorsConfig, 
                           self.credentialHolder))

  -- instala o interceptador servidor
  local picurrent = PICurrent()
  oil.setserverinterceptor(ServerInterceptor(interceptorsConfig, picurrent, 
                                             self.accessControlService))

  -- cria e instala a faceta servidora
  local registryService = RegistryService(picurrent)
  local registryServiceInterface = "IDL:OpenBus/RS/IRegistryService:1.0"
  registryService = self:addFacet("registryService", registryServiceInterface,
                                  registryService)
  self.accessControlService:setRegistryService(self)

  -- instala um observador para deleção de credenciais
  local credentialObserver = {registryService = registryService}
  function credentialObserver:credentialWasDeleted(credential)
    self.registryService:deleteOffersFromCredential(credential)
  end
  credentialObserver = 
    oil.newobject(credentialObserver, 
                  "IDL:OpenBus/ACS/ICredentialObserver:1.0")
  self.observerIdentifier = 
    self.accessControlService:addObserver(credentialObserver, {})

  self.started = true
end

function RegistryServiceComponent:shutdown()
  if not self.started then
    io.stderr:write("Servico ja foi finalizado.\n")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  self.accessControlService:removeObserver(self.observerIdentifier)
  self.accessControlService:logout(self.credential)
  self.credentialHolder:invalidate()

  self.observerIdentifier = nil
  self.credential = nil
  self.accessControlService = nil

  self:removeFacets()
end
