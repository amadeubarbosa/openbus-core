--
-- Componente (membro) responsável pelo Serviço de Registro
--
-- $Id$
--
require "oil"
require "lce"

require "openbus.Member"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local CredentialHolder = require "openbus.common.CredentialHolder"
local PICurrent = require "openbus.common.PICurrent"
local verbose = require "openbus.common.Log"

require "openbus.services.registry.RegistryService"

local oop = require "loop.simple"

RegistryServiceComponent = oop.class({}, Member)

function RegistryServiceComponent:__init(name)
  self = oop.rawnew(self, {
    name = name,
    config = RegistryServerConfiguration,
  })
  return self
end

function RegistryServiceComponent:startup()
  -- obtém a referência para o Serviço de Controle de Acesso
  local accessControlServiceComponent = 
  oil.newproxy("corbaloc::"..self.config.accessControlServerHost.."/"..
                  self.config.accessControlServerKey,
               "IDL:openbusidl/acs/IAccessControlServiceComponent:1.0")
  if accessControlServiceComponent:_non_existent() then
    verbose:error("Servico de controle de acesso nao encontrado.")
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local accessControlServiceInterface = 
    "IDL:openbusidl/acs/IAccessControlService:1.0"
  self.accessControlService = 
    accessControlServiceComponent:getFacet(accessControlServiceInterface)
  self.accessControlService = 
    oil.narrow(self.accessControlService, accessControlServiceInterface)

  -- autenticação junto ao serviço de controle de acesso
  local challenge = self.accessControlService:getChallenge(self.name)
  if not challenge then
    verbose:error("O desafio nao foi obtido junto ao Servico de Controle de Acesso.")
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local privateKey, errorMessage = lce.key.readprivatefrompemfile(self.config.privateKeyFile)
  if not privateKey then
    verbose:error("Erro ao obter a chave privada.")
    verbose:error(errorMessage)
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local answer = lce.cipher.decrypt(privateKey, challenge)
  privateKey:release()
  local accessControlServiceCertificate = lce.x509.readfromderfile(self.config.accessControlServiceCertificateFile)
  answer = lce.cipher.encrypt(accessControlServiceCertificate:getpublickey(), answer)
  accessControlServiceCertificate:release()
  local success
  success, self.credential = 
    self.accessControlService:loginByCertificate(self.name, answer)
  if not success then
    verbose:error("Nao foi possivel logar no servico de controle de acesso.")
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
  local registryService = RegistryService(self.accessControlService, picurrent)
  local registryServiceInterface = "IDL:openbusidl/rs/IRegistryService:1.0"
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
                  "IDL:openbusidl/acs/ICredentialObserver:1.0")
  self.observerIdentifier = 
    self.accessControlService:addObserver(credentialObserver, {})

  self.started = true
end

function RegistryServiceComponent:shutdown()
  if not self.started then
    verbose:error("Servico ja foi finalizado.")
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
