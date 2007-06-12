-----------------------------------------------------------------------------
-- Componente (membro) respons�vel pelo Servi�o de Sess�o
--
-- �ltima altera��o:
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
  log:service("Pedido de startup para o servi�o de sess�o")

  -- Se � o primeiro startup, deve instanciar ConnectionManager e
  -- instalar interceptadores
  if not self.initialized then
    log:service("Servi�o de sess�o est� inicializando")      
    local credentialHolder = CredentialHolder()
    self.connectionManager = 
      ServiceConnectionManager(self.config.accessControlServerHost,
        credentialHolder, self.config.privateKeyFile,
        self.config.accessControlServiceCertificateFile)

    -- obt�m a refer�ncia para o Servi�o de Controle de Acesso
    self.accessControlService = self.connectionManager:getAccessControlService()
    if self.accessControlService == nil then
      error{"IDL:SCS/StartupFailed:1.0"}
    end

    -- instala o interceptador cliente
    local CONF_DIR = os.getenv("CONF_DIR")
    local interceptorsConfig = 
      assert(loadfile(CONF_DIR.."/advanced/SSInterceptorsConfiguration.lua"))()
    oil.setclientinterceptor(
      ClientInterceptor(interceptorsConfig, credentialHolder))

    -- instala o interceptador servidor
    self.picurrent = PICurrent()
    oil.setserverinterceptor(ServerInterceptor(interceptorsConfig, 
                                               self.picurrent, 
                                               self.accessControlService))
    self.initialized = true
  else
    log:service("Servi�o de sess�o j� foi inicializado")
  end

  -- autentica o servi�o, conectando-o ao barramento
  local success = self.connectionManager:connect(self.name)
  if not success then
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- cria e instala a faceta servidora
  self.sessionService = SessionService(self.accessControlService, 
                                       self.picurrent)
  local sessionServiceInterface = "IDL:openbusidl/ss/ISessionService:1.0"
  self:addFacet("sessionService", sessionServiceInterface, self.sessionService)

  -- registra sua oferta de servi�o junto ao Servi�o de Registro
  local offerType = self.config.sessionServiceOfferType
  local serviceOffer = {
    type = offerType,
    description = "Servico de Sessoes",
    properties = {},
    member = self,
  }
  local registryService = self.accessControlService:getRegistryService()
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
  log:service("Servi�o de sess�o iniciado")
end

function SessionServiceComponent:shutdown()
  log:service("Pedido de shutdown para o servi�o de sess�o")
  if not self.started then
    log:error("Servico ja foi finalizado.\n")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  local accessControlService = self.connectionManager:getAccessControlService()
  local registryService = accessControlService:getRegistryService()
  if not registryService then
    log:error("Servi�o de registro n�o encontrado")
  else
    local registryServiceInterface = "IDL:openbusidl/rs/IRegistryService:1.0"
    registryService = registryService:getFacet(registryServiceInterface)
    registryService = oil.narrow(registryService, registryServiceInterface)
    registryService:unregister(self.registryIdentifier)
  end

  self.sessionService:shutdown()

  self.connectionManager:disconnect()

  self:removeFacets()
  log:service("Servi�o de sess�o finalizado")
end
