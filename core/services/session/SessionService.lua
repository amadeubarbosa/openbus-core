-- $Id$

local oil = require "oil"
local Openbus = require "openbus.Openbus"

local luuid = require "uuid"

local Session = require "core.services.session.Session"
local SessionPrev = require "core.services.session.Session_Prev"

local Log = require "openbus.util.Log"
local Utils = require "openbus.util.Utils"

local oop = require "loop.base"

local ComponentContext = require "scs.core.ComponentContext"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

local tostring = tostring
local table    = table
local pairs    = pairs
local ipairs   = ipairs
local next     = next

local format = string.format

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
    Log:warn(format(
        "A credencial {%s, %s, %s} tentou criar uma sessão e esta já existe",
        credential.identifier, credential.owner, credential.delegate))
    return false, nil, self.invalidMemberIdentifier
  end
  -- Cria nova sessão
  local orb = Openbus:getORB()
  local component = ComponentContext(orb, componentId)
  component:putFacet("SessionEventSink_"..Utils.IDL_VERSION,
                      Utils.SESSION_ES_INTERFACE,
                      Session.SessionEventSink())
  component:putFacet("SessionEventSink",
                      Utils.SESSION_ES_INTERFACE_PREV,
                      SessionPrev.SessionEventSink())
  component:putFacet("ISession_"..Utils.IDL_VERSION,
                      Utils.SESSION_INTERFACE,
                      Session.Session())
  component:putFacet("ISession",
                      Utils.SESSION_INTERFACE_PREV,
                      SessionPrev.Session())
  component:putFacet("IReceptacles",
                      Utils.RECEPTACLES_INTERFACE,
                      AdaptiveReceptacle.AdaptiveReceptacleFacet())
  component:putReceptacle("AccessControlServiceReceptacle", "IDL:scs/core/IComponent:1.0", true)

  local sessionFacet = component["ISession_"..Utils.IDL_VERSION]
  sessionFacet.identifier = self:generateIdentifier()
  sessionFacet.credential = credential
  sessionFacet.sessionService = self
  component["SessionEventSink_"..Utils.IDL_VERSION].sessionService = self
  self.sessions[credential.identifier] = component
  Log:debug(format("A credencial {%s. %s, %s} criou a sessão %s",
      credential.identifier, credential.owner, credential.delegate,
      sessionFacet.identifier))

  -- A credencial deve ser observada!
  local status, acsFacet = oil.pcall(Utils.getReplicaFacetByReceptacle,
    orb, self.context.IComponent, "AccessControlServiceReceptacle",
    "IAccessControlService_" .. Utils.IDL_VERSION, acsIDL)
  if not status or not acsFacet then
    component:deactivateComponent()
    component = nil
    self.sessions[credentialId] = nil
    return false, nil, self.invalidMemberIdentifier
  end

  if not self.observerId then
    self.observerId = acsFacet:addObserver(self.context.SessionServiceCredentialObserver, {})
  end

  -- Adiciona o membro à sessão
  local memberID = sessionFacet:addMember(member)
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
    Log:debug(format(
        "A credencial %s deixou de ser válida e sua sessão foi removida",
        credentialId))
    component:deactivateComponent()
    component = nil
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
  local orb = Openbus:getORB()
  local sessions = self.observed[credentialId]
  if not sessions then
    sessions = {}
    self.observed[credentialId] = sessions
    -- Primeira sessão da credencial, começar a observar
    local status, acsFacet = oil.pcall(Utils.getReplicaFacetByReceptacle,
      orb, self.context.IComponent, "AccessControlServiceReceptacle",
      "IAccessControlService_" .. Utils.IDL_VERSION, acsIDL)
    if status and acsFacet then
      acsFacet:addCredentialToObserver(self.observerId, credentialId)
    else
      if not status then
        Log:error("A credencial não foi adicionada ao observador. Houve um erro ao obter a faceta do Serviço de Controle de Acesso: " .. acsFacet)
      else
        Log:error("A credencial não foi adicionada ao observador. O proxy para a faceta do Serviço de Controle de Acesso é inválido.")
      end
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
  local orb = Openbus:getORB()
  local sessions = self.observed[credentialId]
  sessions[session.identifier] = nil
  if not next(sessions) then
    self.observed[credentialId] = nil
    local status, acsFacet = oil.pcall(Utils.getReplicaFacetByReceptacle,
      orb, self.context.IComponent, "AccessControlServiceReceptacle",
      "IAccessControlService_" .. Utils.IDL_VERSION, acsIDL)
    if status and acsFacet then
      acsFacet:removeCredentialFromObserver(self.observerId, credentialId)
    else
      if not status then
        Log:error("A credencial não foi removida do observador. Houve um erro ao obter a faceta do Serviço de Controle de Acesso: " .. acsFacet)
      else
        Log:error("A credencial não foi removida do observador. O proxy para a faceta do Serviço de Controle de Acesso é inválido.")
      end
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
    Log:warn(format("A credencial {%s, %s, %s} não possui sessão",
        credential.identifier, credential.owner, credential.delegate))
    return nil
  end
  return session.IComponent
end

---
--Procedimento após a reconexão do serviço.
---
function SessionService:expired()

  local acsFacet = Openbus:getAccessControlService()
  if not acsFacet then
    Log:error("Não foi possível reconectar o serviço de sessão.O serviço de controle de acesso não foi encontrado")
    return false
  end

  -- Registra novamente o observador de credenciais
  self.observerId = acsFacet:addObserver(
      self.context.SessionServiceCredentialObserver, {}
  )
  Log:debug(format(
      "O observador de credenciais foi recadastrado com o identificador %s",
      self.observerId))

  -- Mantém apenas as sessões com credenciais válidas
  local invalidCredentials = {}
  for credentialId, sessions in pairs(self.observed) do
    if not acsFacet:addCredentialToObserver(self.observerId,
        credentialId) then
      Log:debug(format("A sessão da credencial %s será removida", credentialId))
      table.insert(invalidCredentials, credentialId)
    else
      Log:debug(format("A sessão da credencial %s será mantida", credentialId))
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
  local acsIComp = Openbus:getACSIComponent()
  local success, conId =
    oil.pcall(self.context.IReceptacles.connect, self.context.IReceptacles,
              "AccessControlServiceReceptacle", acsIComp)
  if not success then
    Log:error(
        "Ocorreu um erro ao conectar com o serviço de controle de acesso: ",
        conId)
    error{"IDL:SCS/StartupFailed:1.0"}
 end
end

--------------------------------------------------------------------------------
-- Faceta ICredentialObserver
--------------------------------------------------------------------------------

Observer = oop.class{}

function Observer:credentialWasDeleted(credential)
  self.context["ISessionService_" .. Utils.IDL_VERSION]:credentialWasDeletedById(credential.identifier)
end
