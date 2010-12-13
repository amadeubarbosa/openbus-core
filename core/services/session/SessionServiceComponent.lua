-- $Id$

local os = os
local string = string

local error    = error
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
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")

  -- Verifica se � o primeiro startup
  if not self.initialized then
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
  end

  -- autentica o servi�o, conectando-o ao barramento
  local registryService = false
  if not Openbus:isConnected() then
    registryService = Openbus:connectByCertificate(self.context._componentId.name,
      self.privateKeyFile, self.accessControlServiceCertificateFile)
    if not registryService then
      error{"IDL:SCS/StartupFailed:1.0"}
    end
    registryService = orb:newproxy(registryService, "protected")
  end

  -- Cadastra callback para LeaseExpired
  Openbus:setLeaseExpiredCallback( self )

  -- conecta o controle de acesso:   [SS]--( 0--[ACS]
  local acsIComp = Openbus:getACSIComponent()
  local success, conId =
    oil.pcall(self.context.IReceptacles.connect, self.context.IReceptacles,
              "AccessControlServiceReceptacle", acsIComp)
  if not success then
    Log:error("Falha ao conectar ao servi�o de controle de acesso", conId)
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- configura faceta ISessionService
  self.sessionService = self.context.ISessionService

  -- registra sua oferta de servi�o junto ao Servi�o de Registro
  self.serviceOffer = {
    member = self.context.IComponent,
    properties = {},
  }

  local success, identifier = registryService:register(self.serviceOffer)
  if not success then
    if identifier[1] == "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0" then
      Log:error("N�o foi poss�vel registrar a oferta do servi�o de sess�o. As seguintes interfaces n�o foram autorizadas:")
      for _, facet in ipairs(identifier.facets) do
        Log:error(facet)
      end
    else
      Log:error("N�o foi poss�vel registrar a oferta do servico de sessao",
          identifier)
    end
    Openbus:disconnect()
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  self.serviceOfferPrev = {
    member = self.context.IComponent,
    properties = {},
  }

  local success, identifierPrev = registryService:register(self.serviceOfferPrev)
  if not success then
    if identifierPrev[1] == "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0" then
      Log:error(format(
          "N�o foi poss�vel registrar a oferta do servi�o de sess�o (vers�o %d). As seguintes interfaces n�o foram autorizadas:",
          Utils.OB_PREV))
      for _, facet in ipairs(identifierPrev.facets) do
        Log:error(facet)
      end
    else
      Log:error(format(
          "N�o foi poss�vel registrar a oferta do servico de sessao (vers�o %d)",
          identifierPrev, Utils.OB_PREV))
    end
    Openbus:disconnect()
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  self.registryIdentifier = identifier
  self.registryIdentifierPrev = identifierPrev

  self.started = true
end

---
--Procedimento ap�s a reconex�o do servi�o.
---
function SessionServiceComponent:expired()
  Openbus:connectByCertificate(self.context._componentId.name,
    self.privateKeyFile, self.accessControlServiceCertificateFile)

  if not Openbus:isConnected() then
    Log:error("N�o foi poss�vel reconectar ao servi�o de controle de acesso")
    return false
  end

  -- Procedimento realizado pela faceta
  self.sessionService:expired()

  -- Registra novamente a oferta de servi�o, pois a credencial associada
  Log:debug("O servi�o de sess�o foi reautenticado")

  -- agora � outra
  local registryService = Openbus:getRegistryService()
  if not registryService then
    self.registryIdentifier = nil
    self.registryIdentifierPrev = nil
    Log:error("O servi�o de registro n�o foi encontrado")
    return
  end
  registryService = orb:newproxy(registryService, "protected")

  success, self.registryIdentifier = registryService:register(self.serviceOffer)
  if not success then
    if self.registryIdentifier[1] == "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0" then
      Log:error("N�o foi poss�vel registrar a oferta do servi�o de sess�o. As seguintes interfaces n�o foram autorizadas:")
      for _, facet in ipairs(self.registryIdentifier.facets) do
        Log:error(facet)
      end
    else
      Log:error("N�o foi poss�vel registrar a oferta do servico de sessao",
          self.registryIdentifier)
    end
    self.registryIdentifier = nil
    return
  end

  success, self.registryIdentifierPrev = registryService:register(self.serviceOfferPrev)
  if not success then
    if self.registryIdentifierPrev[1] == "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0" then
      Log:error(format(
          "N�o foi poss�vel registrar a oferta do servi�o de sess�o (vers�o %d). As seguintes interfaces n�o foram autorizadas:",
          Utils.OB_PREV))
      for _, facet in ipairs(self.registryIdentifierPrev.facets) do
        Log:error(facet)
      end
    else
      Log:error(format(
          "N�o foi poss�vel registrar a oferta do servico de sessao (vers�o %d)",
          self.registryIdentifierPrev, Utils.OB_PREV))
    end
    self.registryIdentifierPrev = nil
    return
  end
end

---
--Finaliza o servi�o.
--
--@see scs.core.IComponent#shutdown
---
function SessionServiceComponent:shutdown()
  if not self.started then
    Log:error("O servi�o de sess�o j� est� finalizado")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  if self.registryIdentifier then
    local registryService = Openbus:getRegistryService()
    if not registryService then
      Log:error("O servi�o de registro n�o foi encontrado")
    else
      registryService:unregister(self.registryIdentifier)
    end
    self.registryIdentifier = nil
  end

  if self.registryIdentifierPrev then
    local registryService = Openbus:getRegistryService()
    if not registryService then
      Log:error("O servi�o de registro n�o foi encontrado")
    else
      registryService:unregister(self.registryIdentifierPrev)
    end
    self.registryIdentifierPrev = nil
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

  Log:info("O servi�o de sess�o foi finalizado")
end
