-- $Id$

local oil = require "oil"
local Openbus = require "openbus.Openbus"
local orb = oil.orb

local luuid = require "uuid"

local Session = require "core.services.session.Session"
local Session_v1_04 = require "core.services.session.Session_v1_04"

local Log = require "openbus.util.Log"
local Utils = require "openbus.util.Utils"

local oop = require "loop.base"

local scs = require "scs.core.base"

local tostring = tostring
local table    = table
local pairs    = pairs
local ipairs   = ipairs
local next     = next

local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

---
--Faceta que disponibiliza a funcionalidade básica do serviço de sessão.
---
module "core.services.session.SessionService"

local acsIDL = Utils.ACCESS_CONTROL_SERVICE_INTERFACE

--------------------------------------------------------------------------------
-- Faceta ISessionService
--------------------------------------------------------------------------------

SessionService = oop.class{
  sessions = {},                -- Mapeia o dono da sessão no componente
  observed = {},                -- Mapeia um membro nas sessões que ele faz parte
  invalidMemberIdentifier = "",
}

-----------------------------------------------------------------------------
-- Descricoes do Componente Sessao
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent             = {}
facetDescriptions.IMetaInterface         = {}
facetDescriptions.SessionEventSink       = {}
facetDescriptions.SessionEventSink_Prev  = {}
facetDescriptions.ISession               = {}
facetDescriptions.ISession_Prev          = {}
facetDescriptions.IReceptacles           = {}

facetDescriptions.IComponent.name                 = "IComponent"
facetDescriptions.IComponent.interface_name       = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                = scs.Component

facetDescriptions.IMetaInterface.name             = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name   = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class            = scs.MetaInterface

facetDescriptions.SessionEventSink.name           = "SessionEventSink_v" .. Utils.OB_VERSION
facetDescriptions.SessionEventSink.interface_name = Utils.SESSION_ES_INTERFACE
facetDescriptions.SessionEventSink.class          = Session.SessionEventSink

facetDescriptions.SessionEventSink_Prev.name           = "SessionEventSink"
facetDescriptions.SessionEventSink_Prev.interface_name = Utils.SESSION_ES_INTERFACE_V1_04
facetDescriptions.SessionEventSink_Prev.class          = Session_v1_04.SessionEventSink

facetDescriptions.ISession.name                   = "ISession_v" .. Utils.OB_VERSION
facetDescriptions.ISession.interface_name         = Utils.SESSION_INTERFACE
facetDescriptions.ISession.class                  = Session.Session

facetDescriptions.ISession_Prev.name             = "ISession"
facetDescriptions.ISession_Prev.interface_name   = Utils.SESSION_INTERFACE_V1_04
facetDescriptions.ISession_Prev.class            = Session_v1_04.Session

facetDescriptions.IReceptacles.name           = "IReceptacles"
facetDescriptions.IReceptacles.interface_name = "IDL:scs/core/IReceptacles:1.0"
facetDescriptions.IReceptacles.class          = AdaptiveReceptacle.AdaptiveReceptacleFacet

-- Receptacle Descriptions
local receptacleDescs = {}
receptacleDescs.AccessControlServiceReceptacle = {}
receptacleDescs.AccessControlServiceReceptacle.name           = "AccessControlServiceReceptacle"
receptacleDescs.AccessControlServiceReceptacle.interface_name = "IDL:scs/core/IComponent:1.0"
receptacleDescs.AccessControlServiceReceptacle.is_multiplex   = true

-- component id
local componentId = {}
componentId.name = "Session"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

---
--Cria uma sessão associada a uma credencial. A credencial em questão é
--recuperada da requisição pelo interceptador do serviço, e repassada através
--do objeto PICurrent.
--
--@param member O membro que está solicitando a criação da sessão e que estará
--inserido na sessão automaticamente.
--
--@return true, a sessão e o identificador de membro da sessão em caso de
--sucesso, ou false, caso contrário.
---
function SessionService:createSession(member)
  local credential = Openbus:getInterceptedCredential()
  if self.sessions[credential.identifier] then
    Log:err("Tentativa de criar sessão já existente")
    return false, nil, self.invalidMemberIdentifier
  end
  -- Cria nova sessão
  local component = scs.newComponent(facetDescriptions, receptacleDescs,
    componentId)
  component.ISession.identifier = self:generateIdentifier()
  component.ISession.credential = credential
  component.ISession.sessionService = self
  component.SessionEventSink.sessionService = self
  self.sessions[credential.identifier] = component
  Log:session("Sessão criada com id "..component.ISession.identifier)

  -- A credencial deve ser observada!
  local status, acsFacet = oil.pcall(Utils.getReplicaFacetByReceptacle, 
    orb, self.context.IComponent, "AccessControlServiceReceptacle", 
    "IAccessControlService_v" .. Utils.OB_VERSION, acsIDL)
  if not status then
    orb:deactivate(component.ISession)
    orb:deactivate(component.IMetaInterface)
    orb:deactivate(component.SessionEventSink)
    orb:deactivate(component.IComponent)
    self.sessions[credentialId] = nil
    return false, nil, self.invalidMemberIdentifier
  end
  
  if not self.observerId then
    self.observerId = acsFacet:addObserver(self.context.ICredentialObserver, {})
  end

  -- Adiciona o membro à sessão
  local memberID = component.ISession:addMember(member)
  return true, component.IComponent, memberID
end

---
--Notificação de deleção de credencial.
--
--@param credential A credencial removida.
---
function SessionService:credentialWasDeletedById(credentialId)
  -- Remove o membro das sessões que ele participa
  local sessions = self.observed[credentialId]
  if sessions then
    for _, session in pairs(sessions) do
      session:credentialWasDeletedById(credentialId)
    end
    self.observed[credentialId] = nil
  end
  -- Remove a sessão que o membro possui
  local component = self.sessions[credentialId]
  if component then
    Log:session("Removendo sessão de credencial deletada ("..
        credentialId..")")
    orb:deactivate(component.ISession)
    orb:deactivate(component.IMetaInterface)
    orb:deactivate(component.SessionEventSink)
    orb:deactivate(component.IComponent)
    self.sessions[credentialId] = nil
  end
end

---
-- Observa o membro para removê-lo das sessões.
--
-- @param credentialId Identificador da credencial do membro
-- @param session Sessão que o membro não vai mais participar
--
function SessionService:observe(credentialId, session)
  local sessions = self.observed[credentialId]
  if not sessions then
    sessions = {}
    self.observed[credentialId] = sessions
    -- Primeira sessão da credencial, começar a observar
    local status, acsFacet = oil.pcall(Utils.getReplicaFacetByReceptacle, 
      orb, self.context.IComponent, "AccessControlServiceReceptacle", 
      "IAccessControlService_v" .. Utils.OB_VERSION, acsIDL)
    if status then
      acsFacet:addCredentialToObserver(self.observerId, credentialId)
    end
  end
  sessions[session.identifier] = session
end

---
-- Pára de observar o membro na repectiva sessão.
--
-- Se o membro não estiver mais relacionado com sessões,
-- não observar mais sua credential junto ao ACS.
--
-- @param credentialId Identificador da credencial do membro.
-- @param session Sessão que o membro não vai mais participar.
--
function SessionService:unObserve(credentialId, session)
  local sessions = self.observed[credentialId]
  sessions[session.identifier] = nil
  if not next(sessions) then
    self.observed[credentialId] = nil
    local status, acsFacet = oil.pcall(Utils.getReplicaFacetByReceptacle, 
      orb, self.context.IComponent, "AccessControlServiceReceptacle", 
      "IAccessControlService_v" .. Utils.OB_VERSION, acsIDL)
    if status then
      acsFacet:removeCredentialFromObserver(self.observerId, credentialId)
    end
  end
end

---
--Gera um identificador de sessão.
--
--@return Um identificador de sessão.
---
function SessionService:generateIdentifier()
  return luuid.new("time")
end

---
--Obtém a sessão associada a uma credencial. A credencial em questão é
--recuperada da requisição pelo interceptador do serviço, e repassada através
--do objeto PICurrent.
--
--@return A sessão, ou nil, caso não exista sessão para a credencial do membro.
---
function SessionService:getSession()
  local credential = Openbus:getInterceptedCredential()
  local session = self.sessions[credential.identifier]
  if not session then
    Log:warn("Não há sessão para "..credential.identifier)
    return nil
  end
  return session.IComponent
end

---
--Procedimento após a reconexão do serviço.
---
function SessionService:expired()
  local status, acsFacet = oil.pcall(Utils.getReplicaFacetByReceptacle, 
    orb, self.context.IComponent, "AccessControlServiceReceptacle", 
    "IAccessControlService_v" .. Utils.OB_VERSION, acsIDL)
  if not status then
    -- Erro ja foi logado, só retorna
    return nil
  end     

  -- Registra novamente o observador de credenciais
  self.observerId = acsFacet:addObserver(
      self.context.ICredentialObserver, {}
  )
  Log:session("Observador recadastrado")

  -- Mantém apenas as sessões com credenciais válidas
  local invalidCredentials = {}
  for credentialId, sessions in pairs(self.observed) do
    if not acsFacet:addCredentialToObserver(self.observerId,
        credentialId) then
      Log:session("Sessão para "..credentialId.." será removida")
      table.insert(invalidCredentials, credentialId)
    else
      Log:session("Sessão para "..credentialId.." será mantida")
    end
  end
  for _, credentialId in ipairs(invalidCredentials) do
    self:credentialWasDeletedById(credentialId)
  end
end

---
--Inicia o componente.
--
--@see scs.core.IComponent#startup
---
function SessionService:startup()
  -- conecta-se com o controle de acesso:   [SS]--( 0--[ACS]
  local acsIComp = Openbus:getACSIComponent()
  local success, conId =
    oil.pcall(self.context.IReceptacles.connect, self.context.IReceptacles,
              "AccessControlServiceReceptacle", acsIComp)
  if not success then
    Log:error("Erro durante conexão com serviço de Controle de Acesso.")
    Log:error(conId)
    error{"IDL:SCS/StartupFailed:1.0"}
 end
end

--------------------------------------------------------------------------------
-- Faceta ICredentialObserver
--------------------------------------------------------------------------------

Observer = oop.class{}

function Observer:credentialWasDeleted(credential)
  self.context.ISessionService:credentialWasDeletedById(credential.identifier)
end
