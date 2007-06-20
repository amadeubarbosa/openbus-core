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

--
-- Constroi a implementação do componente
--
function SessionServiceComponent:__init(name)
  local obj = { name = name,
                config = SessionServerConfiguration,
              }
  Member:__init(obj)
  return oop.rawnew(self, obj)
end

--
-- Inicia o componente
--
function SessionServiceComponent:startup()
  log:service("Pedido de startup para o serviço de sessão")

  -- Se é o primeiro startup, deve instanciar ConnectionManager e
  -- instalar interceptadores
  if not self.initialized then
    log:service("Serviço de sessão está inicializando")      
    local credentialHolder = CredentialHolder()
    self.connectionManager = 
      ServiceConnectionManager(self.config.accessControlServerHost,
        credentialHolder, self.config.privateKeyFile,
        self.config.accessControlServiceCertificateFile)

    -- obtém a referência para o Serviço de Controle de Acesso
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
    log:service("Serviço de sessão já foi inicializado")
  end

  -- autentica o serviço, conectando-o ao barramento
  local success = self.connectionManager:connect(self.name,
    function() self.wasReconnected(self) end)
  if not success then
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- cria e instala a faceta servidora
  self.sessionService = SessionService(self.accessControlService, 
                                       self.picurrent)
  local sessionServiceInterface = "IDL:openbusidl/ss/ISessionService:1.0"
  self:addFacet("sessionService", sessionServiceInterface, self.sessionService)

  -- registra sua oferta de serviço junto ao Serviço de Registro
  self.offerType = self.config.sessionServiceOfferType
  self.serviceOffer = {
    type = self.offerType,
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

  success, self.registryIdentifier = registryService:register(self.serviceOffer)
  if not success then
    log:error("Erro ao registrar oferta do servico de sessao.\n")
    self.connectionManager:disconntect()
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  self.started = true
  log:service("Serviço de sessão iniciado")
end

--
-- Procedimento após a reconexão do serviço
--
function SessionServiceComponent:wasReconnected()
log:service("Serviço de sessão foi reconectado")

  -- Procedimento realizado pela faceta
  self.sessionService:wasReconnected()

  -- Registra novamente a oferta de serviço, pois a credencial associada
  -- agora é outra
  local registryService = self.accessControlService:getRegistryService()
  if not registryService then
    self.registryIdentifier = nil
    log:error("Servico de registro nao encontrado.\n")
    return
  end

  success, self.registryIdentifier = registryService:register(self.serviceOffer)
  if not success then
    log:error("Erro ao registrar oferta do servico de sessao.\n")
    self.registryIdentifier = nil
    return
  end
end

--
-- Finaliza o serviço
--
function SessionServiceComponent:shutdown()
  log:service("Pedido de shutdown para o serviço de sessão")
  if not self.started then
    log:error("Servico ja foi finalizado.\n")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  if self.registryIdentifier then
    local accessControlService = self.connectionManager:getAccessControlService()
    local registryService = accessControlService:getRegistryService()
    if not registryService then
      log:error("Serviço de registro não encontrado")
    else
      registryService:unregister(self.registryIdentifier)
    end
    self.registryIdentifier = nil
  end

  self.sessionService:shutdown()

  self.connectionManager:disconnect()

  self:removeFacets()
  log:service("Serviço de sessão finalizado")
end
