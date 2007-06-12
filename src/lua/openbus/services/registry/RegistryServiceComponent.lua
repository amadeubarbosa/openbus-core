-----------------------------------------------------------------------------
-- Componente (membro) respons�vel pelo Servi�o de Registro
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
  log:service("Pedido de startup para servi�o de registro")

  -- Se � o primeiro startup, deve instanciar ConnectionManager e
  -- instalar interceptadores
  if not self.initialized then
    log:service("Servi�o de registro est� inicializando")
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
      assert(loadfile(CONF_DIR.."/advanced/RSInterceptorsConfiguration.lua"))()
    oil.setclientinterceptor(
      ClientInterceptor(interceptorsConfig, credentialHolder))

    -- instala o interceptador servidor
    self.picurrent = PICurrent()
    oil.setserverinterceptor(ServerInterceptor(interceptorsConfig, 
                                               self.picurrent,
                                               self.accessControlService))
    self.initialized = true
  else
    log:service("Servi�o de registro j� foi inicializado")
  end

  -- autentica o servi�o, conectando-o ao barramento
  local success = self.connectionManager:connect(self.name)
  if not success then
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- cria e instala a faceta servidora
  self.registryService = RegistryService(self.accessControlService, 
                                         self.picurrent)
  local registryServiceInterface = "IDL:openbusidl/rs/IRegistryService:1.0"
  self:addFacet("registryService", registryServiceInterface,
                self.registryService)
  self.accessControlService:setRegistryService(self)

  self.started = true
  log:service("Servi�o de registro iniciado")
end

function RegistryServiceComponent:shutdown()
  log:service("Pedido de shutdown para servi�o de registro")
  if not self.started then
    log:error("Servico ja foi finalizado.")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false
 
  self.registryService:shutdown()

  self.connectionManager:disconnect()

  self:removeFacets()
  log:service("Servi�o de registro finalizado")
end
