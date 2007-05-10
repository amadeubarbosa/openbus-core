-----------------------------------------------------------------------------
-- Componente (membro) respons�vel pelo Servi�o de Registro
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
require "oil"
require "lce"

require "openbus.Member"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local LeaseHolder = require "openbus.common.LeaseHolder"
local CredentialHolder = require "openbus.common.CredentialHolder"
local PICurrent = require "openbus.common.PICurrent"
local log = require "openbus.common.Log"

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
  -- obt�m a refer�ncia para o Servi�o de Controle de Acesso
  self.accessControlService = 
  oil.newproxy("corbaloc::"..self.config.accessControlServerHost.."/"..
                  self.config.accessControlServerKey,
               "IDL:openbusidl/acs/IAccessControlService:1.0")
  if self.accessControlService:_non_existent() then
    log:error("Servico de controle de acesso nao encontrado.")
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- autentica��o junto ao servi�o de controle de acesso
  local challenge = self.accessControlService:getChallenge(self.name)
  if not challenge then
    log:error("O desafio nao foi obtido junto ao Servico de Controle de Acesso.")
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local privateKey, errorMessage = lce.key.readprivatefrompemfile(self.config.privateKeyFile)
  if not privateKey then
    log:error("Erro ao obter a chave privada.")
    log:error(errorMessage)
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local answer = lce.cipher.decrypt(privateKey, challenge)
  privateKey:release()
  local accessControlServiceCertificate = lce.x509.readfromderfile(self.config.accessControlServiceCertificateFile)
  answer = lce.cipher.encrypt(accessControlServiceCertificate:getpublickey(), answer)
  accessControlServiceCertificate:release()
  local success, lease
  success, self.credential, lease = 
    self.accessControlService:loginByCertificate(self.name, answer)
  if not success then
    log:error("Nao foi possivel logar no servico de controle de acesso.")
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

  -- Cria o LeaseHolder que vai renovar o lease junto ao servi�o de acesso.
  self.leaseHolder = LeaseHolder(lease, self.credential,
    self.accessControlService)
  self.leaseHolder:startRenew()

  -- cria e instala a faceta servidora
  local registryService = RegistryService(self.accessControlService, picurrent)
  local registryServiceInterface = "IDL:openbusidl/rs/IRegistryService:1.0"
  registryService = self:addFacet("registryService", registryServiceInterface,
                                  registryService)
  self.accessControlService:setRegistryService(self)

  self.started = true
end

function RegistryServiceComponent:shutdown()
  if not self.started then
    log:error("Servico ja foi finalizado.")
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
