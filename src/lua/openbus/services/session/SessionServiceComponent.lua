--
-- Componente (membro) responsável pelo Serviço de Sessão
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
  local accessControlServiceComponent = 
    oil.newproxy("corbaloc::"..self.config.accessControlServerHost.."/"..
                    self.config.accessControlServerKey, 
                 "IDL:openbusidl/acs/IAccessControlServiceComponent:1.0")
  if accessControlServiceComponent:_non_existent() then
    io.stderr:write("Servico de controle de acesso nao encontrado.\n")
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local accessControlServiceInterface = 
      "IDL:openbusidl/acs/IAccessControlService:1.0"
  self.accessControlService = 
    accessControlServiceComponent:getFacet(accessControlServiceInterface)
  self.accessControlService = 
    oil.narrow(self.accessControlService, accessControlServiceInterface)

  -- autenticação junto ao Serviço de Controle de Acesso
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
    io.stderr:write("Nao foi possivel logar no servico de controle de acesso.\n")
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- instala o interceptador cliente
  local CONF_DIR = os.getenv("CONF_DIR")
  local interceptorsConfig = 
    assert(loadfile(CONF_DIR.."/advanced/SSInterceptorsConfiguration.lua"))()
  self.credentialHolder = CredentialHolder()
  self.credentialHolder:setValue(self.credential)
  oil.setclientinterceptor(ClientInterceptor(interceptorsConfig, 
                           self.credentialHolder))

  -- instala o interceptador servidor
  local picurrent = PICurrent()
  oil.setserverinterceptor(ServerInterceptor(interceptorsConfig, picurrent, 
                                             self.accessControlService))

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
  self.accessControlService:logout(self.credential)
  self.credentialHolder:invalidate()

  self.accessControlService = nil
  self.credential = nil

  self:removeFacets()
end
