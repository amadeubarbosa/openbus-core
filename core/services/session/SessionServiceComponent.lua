-- $Id$

local os = os
local string = string

local error    = error
local print    = print
local pairs    = pairs
local ipairs   = ipairs
local assert   = assert
local loadfile = loadfile

local oil = require "oil"
local orb = oil.orb

local SessionService = require "core.services.session.SessionService"
local Openbus = require "openbus.Openbus"
local OilUtilities = require "openbus.util.OilUtilities"
local Utils = require "openbus.util.Utils"

local Log = require "openbus.util.Log"

local scs = require "scs.core.base"

local oop = require "loop.simple"

---
-- IComponent (membro) do Servi�o de Sess�o.
---
module "core.services.session.SessionServiceComponent"

SessionServiceComponent = oop.class({}, scs.Component)

---
--Inicia o componente.
--
--@see scs.core.IComponent#startup
---
function SessionServiceComponent:startup()
  Log:session("Pedido de startup para o servi�o de sess�o")

  local DATA_DIR = os.getenv("OPENBUS_DATADIR")

  -- Verifica se � o primeiro startup
  if not self.initialized then
    Log:session("Servi�o de sess�o est� inicializando")
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
    Log:session("Servi�o de sess�o j� foi inicializado")
  end

  -- autentica o servi�o, conectando-o ao barramento
  local registryService = false
  if not Openbus:isConnected() then
    registryService = Openbus:connectByCertificate(self.context._componentId.name,
      self.privateKeyFile, self.accessControlServiceCertificateFile)
    if not registryService then
      error{"IDL:SCS/StartupFailed:1.0"}
    end
  end

  -- Cadastra callback para LeaseExpired
  Openbus:setLeaseExpiredCallback( self )

  -- conecta o controle de acesso:   [SS]--( 0--[ACS]
  local acsIComp = Openbus:getACSIComponent()
  local success, conId =
    oil.pcall(self.context.IReceptacles.connect, self.context.IReceptacles,
              "AccessControlServiceReceptacle", acsIComp)
  if not success then
    Log:error("Erro durante conex�o com servi�o de Controle de Acesso.")
    Log:error(conId)
    error{"IDL:SCS/StartupFailed:1.0"}
 end

  -- configura faceta ISessionService
  self.sessionService = self.context.ISessionService

  -- registra sua oferta de servi�o junto ao Servi�o de Registro
  self.serviceOffer = {
    member = self.context.IComponent,
    properties = {
      {
        name  = "facets",
        value = {Utils.SESSION_SERVICE_INTERFACE},
      },
    },
  }

  local success, identifier = registryService.__try:register(self.serviceOffer)
  if not success then
    if identifier[1] == "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0" then
      Log:error("Erro ao registrar oferta do servi�o de sess�o")
      for _, facet in ipairs(identifier.facets) do
        Log:error(string.format("Faceta '%s' n�o autorizada", facet))
      end
    else
      Log:error(string.format("Erro ao registrar oferta do servico de sessao: %s\n",
        identifier[1]))
    end
    Openbus:disconnect()
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  self.registryIdentifier = identifier

  self.started = true
  Log:session("Servi�o de sess�o iniciado")
end

---
--Procedimento ap�s a reconex�o do servi�o.
---
function SessionServiceComponent:expired()
  Openbus:connectByCertificate(self.context._componentId.name,
      self.privateKeyFile, self.accessControlServiceCertificateFile)

  -- Procedimento realizado pela faceta
  self.sessionService:expired()

  Log:session("Servi�o de sess�o foi reconectado")

  -- Registra novamente a oferta de servi�o, pois a credencial associada
  -- agora � outra
  local registryService = Openbus:getRegistryService()
  if not registryService then
    self.registryIdentifier = nil
    Log:error("Servico de registro nao encontrado.\n")
    return
  end

  success, self.registryIdentifier = registryService.__try:register(self.serviceOffer)
  if not success then
    if self.registryIdentifier[1] == "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0" then
      Log:error("Erro ao registrar oferta do servi�o de sess�o")
      for _, facet in ipairs(self.registryIdentifier.facets) do
        Log:error(string.format("Facet '%s' n�o autorizada", facet))
      end
    else
      Log:error(string.format("Erro ao registrar oferta do servico de sessao: %s\n",
        self.registryIdentifier[1]))
    end
    self.registryIdentifier = nil
    return
  end
end

---
--Finaliza o servi�o.
--
--@see scs.core.IComponent#shutdown
---
function SessionServiceComponent:shutdown()
  Log:session("Pedido de shutdown para o servi�o de sess�o")
  if not self.started then
    Log:error("Servico ja foi finalizado.\n")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  if self.registryIdentifier then
    local registryService = Openbus:getRegistryService()
    if not registryService then
      Log:error("Servi�o de registro n�o encontrado")
    else
      registryService:unregister(self.registryIdentifier)
    end
    self.registryIdentifier = nil
  end

  if self.sessionService.observerId then
    local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle,
                  orb,
                            self.context.IComponent,
                            "AccessControlServiceReceptacle",
                            "IAccessControlService_v" .. Utils.OB_VERSION,
                            Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
    if not status or not acsFacet then
      -- erro ja foi logado, s� retorna
      return nil
    end
    acsFacet:removeObserver(self.sessionService.observerId)
    self.sessionService.observerId = nil
  end

  if Openbus:isConnected() then
    Openbus:disconnect()
  end

  Log:session("Servi�o de sess�o finalizado")
end
