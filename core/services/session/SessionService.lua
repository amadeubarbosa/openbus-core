-- $Id$

local oil = require "oil"
local Openbus = require "openbus.Openbus"
local orb = oil.orb

local luuid = require "uuid"

local Session = require "core.services.session.Session"

local Log = require "openbus.util.Log"

local oop = require "loop.base"

local scs = require "scs.core.base"

local tostring = tostring
local table    = table
local pairs    = pairs
local ipairs   = ipairs

---
--Faceta que disponibiliza a funcionalidade b�sica do servi�o de sess�o.
---
module "core.services.session.SessionService"

--------------------------------------------------------------------------------
-- Faceta ISessionService
--------------------------------------------------------------------------------

SessionService = oop.class{
  sessions = {},                -- Mapeia o dono da sess�o no componente
  observed = {},                -- Mapeia um membro nas sess�es que ele faz parte
  invalidMemberIdentifier = "",
}

-----------------------------------------------------------------------------
-- Descricoes do Componente Sessao
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent       = {}
facetDescriptions.IMetaInterface   = {}
facetDescriptions.SessionEventSink = {}
facetDescriptions.ISession         = {}

facetDescriptions.IComponent.name                 = "IComponent"
facetDescriptions.IComponent.interface_name       = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                = scs.Component

facetDescriptions.IMetaInterface.name             = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name   = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class            = scs.MetaInterface

facetDescriptions.SessionEventSink.name           = "SessionEventSink"
facetDescriptions.SessionEventSink.interface_name = "IDL:openbusidl/ss/SessionEventSink:1.0"
facetDescriptions.SessionEventSink.class          = Session.SessionEventSink

facetDescriptions.ISession.name                   = "ISession"
facetDescriptions.ISession.interface_name         = "IDL:openbusidl/ss/ISession:1.0"
facetDescriptions.ISession.class                  = Session.Session

-- Receptacle Descriptions
local receptacleDescriptions = {}

-- component id
local componentId = {}
componentId.name = "Session"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

---
--Cria uma sess�o associada a uma credencial. A credencial em quest�o �
--recuperada da requisi��o pelo interceptador do servi�o, e repassada atrav�s
--do objeto PICurrent.
--
--@param member O membro que est� solicitando a cria��o da sess�o e que estar�
--inserido na sess�o automaticamente.
--
--@return true, a sess�o e o identificador de membro da sess�o em caso de
--sucesso, ou false, caso contr�rio.
---
function SessionService:createSession(member)
  local credential = Openbus:getInterceptedCredential()
  if self.sessions[credential.identifier] then
    Log:err("Tentativa de criar sess�o j� existente")
    return false, nil, self.invalidMemberIdentifier
  end
  -- Cria nova sess�o
  local component = scs.newComponent(facetDescriptions, receptacleDescriptions,
    componentId)
  component.ISession.identifier = self:generateIdentifier()
  component.ISession.credential = credential
  component.ISession.sessionService = self
  component.SessionEventSink.sessionService = self
  self.sessions[credential.identifier] = component
  Log:service("Sessao criada com id "..component.ISession.identifier)

  -- A credencial deve ser observada!
  if not self.observerId then
    self.observerId =
      self.accessControlService:addObserver(self.context.ICredentialObserver, {})
  end

  -- Adiciona o membro � sess�o
  local memberID = component.ISession:addMember(member)
  return true, component.IComponent, memberID
end

---
--Notifica��o de dele��o de credencial.
--
--@param credentialId Identificador da credencial removida.
---
function SessionService:credentialWasDeletedById(credentialId)
  -- Remove o membro das sess�es que ele participa
  local sessions = self.observed[credentialId]
  if sessions then
    for _, session in pairs(sessions) do
      session:credentialWasDeletedById(credentialId)
    end
    self.observed[credentialId] = nil
  end
  -- Remove a sess�o que o membro possui
  local component = self.sessions[credentialId]
  if component then
    Log:service("Removendo sess�o de credencial deletada ("..
      credentialId..")")
    orb:deactivate(component.ISession)
    orb:deactivate(component.IMetaInterface)
    orb:deactivate(component.SessionEventSink)
    orb:deactivate(component.IComponent)
    self.sessions[credentialId] = nil
  end
end

---
-- Observa o membro para remov�-lo das sess�es.
--
-- @param credentialId Identificador da credencial do membro
-- @param session Sess�o que o membro n�o vai mais participar
--
function SessionService:observe(credentialId, session)
  local sessions = self.observed[credentialId]
  if not sessions then
    sessions = {}
    self.observed[credentialId] = sessions
  end
  sessions[session.identifier] = session
  self.accessControlService:addCredentialToObserver(self.observerId,
    credentialId)
end

---
-- P�ra de observar o membro na repectiva sess�o.
--
-- Se o membro n�o estiver mais relacionado com sess�es,
-- n�o observar mais sua credential junto ao ACS.
--
-- @param credentialId Identificador da credencial do membro.
-- @param session Sess�o que o membro n�o vai mais participar.
--
function SessionService:unObserve(credentialId, session)
  local sessions = self.observed[credentialId]
  sessions[session.identifier] = nil
  if not next(sessions) then
    self.observed[credentialId] = nil
    self.accessControlService:removeCredentialFromObserver(self.observerId, 
      credentialId)
  end
end

---
--Gera um identificador de sess�o.
--
--@return Um identificador de sess�o.
---
function SessionService:generateIdentifier()
  return luuid.new("time")
end

---
--Obt�m a sess�o associada a uma credencial. A credencial em quest�o �
--recuperada da requisi��o pelo interceptador do servi�o, e repassada atrav�s
--do objeto PICurrent.
--
--@return A sess�o, ou nil, caso n�o exista sess�o para a credencial do membro.
---
function SessionService:getSession()
  local credential = Openbus:getInterceptedCredential()
  local session = self.sessions[credential.identifier]
  if not session then
   Log:warn("N�o h� sess�o para "..credential.identifier)
    return nil
  end
  return session.IComponent
end

---
--Procedimento ap�s a reconex�o do servi�o.
---
function SessionService:expired()
  -- registra novamente o observador de credenciais
  self.observerId = self.accessControlService:addObserver(
      self.context.ICredentialObserver, {}
  )
  Log:service("Observador recadastrado")

  -- Mant�m apenas as sess�es com credenciais v�lidas
  local invalidCredentials = {}
  for credentialId, session in pairs(self.observed) do
    if not self.accessService:addCredentialToObserver(self.observerId,
        credentialId) then
      Log:service("Sess�o para "..credentialId.." ser� removida")
      table.insert(invalidCredentials, credentialId)
    else
      Log:service("Sess�o para "..credentialId.." ser� mantida")
    end
  end
  for _, credentialId in ipairs(invalidCredentials) do
    self:credentialWasDeletedById(credentialId)
  end
end

--------------------------------------------------------------------------------
-- Faceta ICredentialObserver
--------------------------------------------------------------------------------

Observer = oop.class{}

function Observer:credentialWasDeleted(credential)
  self.context.ISessionService:credentialWasDeletedById(credential.identifier)
end

