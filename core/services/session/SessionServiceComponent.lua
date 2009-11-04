-- $Id$

local os = os

local loadfile = loadfile
local assert = assert
local error = error
local string = string
local print = print

local oil = require "oil"
local orb = oil.orb

local SessionService = require "core.services.session.SessionService"
local Openbus = require "openbus.Openbus"
local OilUtilities = require "openbus.util.OilUtilities"

local Log = require "openbus.util.Log"

local scs = require "scs.core.base"

local oop = require "loop.simple"

---
-- IComponent (membro) do Serviço de Sessão.
---
module "core.services.session.SessionServiceComponent"

SessionServiceComponent = oop.class({}, scs.Component)

---
--Inicia o componente.
--
--@see scs.core.IComponent#startup
---
function SessionServiceComponent:startup()
  Log:service("Pedido de startup para o serviço de sessão")

  local DATA_DIR = os.getenv("OPENBUS_DATADIR")

  -- Verifica se é o primeiro startup
  if not self.initialized then
    Log:service("Serviço de sessão está inicializando")
    if (string.sub(self.config.privateKeyFile,1 , 1) == "/") then
      self.privateKeyFile = self.config.privateKeyFile
    else
      self.privateKeyFile = DATA_DIR.."/"..self.config.privateKeyFile
    end

    if (string.sub(self.config.accessControlServiceCertificateFile,1 , 1) == "/") then
      self.accessControlServiceCertificateFile =
        self.config.accessControlServiceCertificateFile
    else
      self.accessControlServiceCertificateFile = DATA_DIR .. "/" ..
        self.config.accessControlServiceCertificateFile
    end

    self.initialized = true
  else
    Log:service("Serviço de sessão já foi inicializado")
  end

  -- autentica o serviço, conectando-o ao barramento
  local registryService = false
  if not Openbus:isConnected() then
    registryService = Openbus:connectByCertificate(self.context._componentId.name,
      self.privateKeyFile, self.accessControlServiceCertificateFile)
    if not registryService then
      error{"IDL:SCS/StartupFailed:1.0"}
    end
  end

  -- Cadastra callback para LeaseExpired
  Openbus:addLeaseExpiredCallback( self )

  -- configura faceta ISessionService
  self.sessionService = self.context.ISessionService

  -- registra sua oferta de serviço junto ao Serviço de Registro
  self.serviceOffer = {
    member = self.context.IComponent,
    properties = {},
  }

  local success, identifier = registryService:register(self.serviceOffer)
  --local success, suc, identifier =
  --        oil.pcall(registryService.register,registryService, self.serviceOffer)
  if not success then
    Log:error("Erro ao registrar oferta do servico de sessao.\n")
    Log:error(suc)
    Openbus:disconnect()
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  self.registryIdentifier = identifier

  self.started = true
  Log:service("Serviço de sessão iniciado")
end

---
--Procedimento após a reconexão do serviço.
---
function SessionServiceComponent:expired()
  Openbus:connectByCertificate(self.context._componentId.name,
      self.privateKeyFile, self.accessControlServiceCertificateFile)

  -- Procedimento realizado pela faceta
  self.sessionService:expired()

  Log:service("Serviço de sessão foi reconectado")

  -- Registra novamente a oferta de serviço, pois a credencial associada
  -- agora é outra
  local registryService = Openbus:getAccessControlService():getRegistryService()
  if not registryService then
    self.registryIdentifier = nil
    Log:error("Servico de registro nao encontrado.\n")
    return
  end

  success, self.registryIdentifier = registryService:register(self.serviceOffer)
  if not success then
    Log:error("Erro ao registrar oferta do servico de sessao.\n")
    self.registryIdentifier = nil
    return
  end
end

---
--Finaliza o serviço.
--
--@see scs.core.IComponent#shutdown
---
function SessionServiceComponent:shutdown()
  Log:service("Pedido de shutdown para o serviço de sessão")
  if not self.started then
    Log:error("Servico ja foi finalizado.\n")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  local accessControlService = self.AccessControlServiceReceptacle
  if self.registryIdentifier then
    local registryService = Openbus:getAccessControlService():getRegistryService()
    if not registryService then
      Log:error("Serviço de registro não encontrado")
    else
      registryService:unregister(self.registryIdentifier)
    end
    self.registryIdentifier = nil
  end

  if self.sessionService.observerId then
    accessControlService:removeObserver(self.sessionService.observerId)
    self.sessionService.observerId = nil
  end

  if Openbus:isConnected() then
    Openbus:disconnect()
  end

  Log:service("Serviço de sessão finalizado")
end
