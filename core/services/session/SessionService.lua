-- $Id$

local oil = require "oil"
local Openbus = require "openbus.Openbus"
local orb = oil.orb

local luuid = require "uuid"

local Session = require "core.services.session.Session"

local Log = require "openbus.util.Log"
local Utils = require "openbus.util.Utils"

local oop = require "loop.base"

local scs = require "scs.core.base"

local tostring = tostring
local table    = table
local pairs    = pairs
local ipairs   = ipairs

local AdaptiveReceptacle = require "openbus.faulttolerance.AdaptiveReceptacle"

---
--Faceta que disponibiliza a funcionalidade b�sica do servi�o de sess�o.
---
module "core.services.session.SessionService"

--------------------------------------------------------------------------------
-- Faceta ISessionService
--------------------------------------------------------------------------------

SessionService = oop.class{sessions = {}, invalidMemberIdentifier = ""}

-----------------------------------------------------------------------------
-- Descricoes do Componente Sessao
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent       = {}
facetDescriptions.IMetaInterface   = {}
facetDescriptions.SessionEventSink = {}
facetDescriptions.ISession         = {}
facetDescriptions.IReceptacles     = {}

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
  Log:session("Criando sess�o")
  local session = scs.newComponent(facetDescriptions, receptacleDescs, componentId)
  session.ISession.identifier = self:generateIdentifier()
  session.ISession.credential = credential
  self.sessions[credential.identifier] = session
  Log:session("Sessao criada com id "..
      tostring(session.ISession.identifier).." !")

  -- A credencial deve ser observada!
  local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle, 
  					 		  orb, 
                         	  self.context.IComponent, 
                         	  "AccessControlServiceReceptacle", 
                         	  "IAccessControlService", 
                         	  "IDL:openbusidl/acs/IAccessControlService:1.0")
  if not status then
	    -- erro ja foi logado, s� retorna
	    return nil
  end     
  
  if not self.observerId then
    self.observerId =
      acsFacet:addObserver(self.context.ICredentialObserver,
                           {credential.identifier})
  else
    acsFacet:addCredentialToObserver(self.observerId,credential.identifier)
  end

  -- Adiciona o membro � sess�o
  local memberID = session.ISession:addMember(member)
  return true, session.IComponent, memberID
end

---
--Notifica��o de dele��o de credencial (logout).
--
--@param credential A credencial removida.
---
function SessionService:credentialWasDeleted(credential)

  -- Remove a sess�o
  local session = self.sessions[credential.identifier]
  if session then
    Log:session("Removendo sess�o de credencial deletada ("..
        credential.identifier..")")
    orb:deactivate(session.ISession)
    orb:deactivate(session.IMetaInterface)
    orb:deactivate(session.SessionEventSink)
    orb:deactivate(session.IComponent)

    self.sessions[credential.identifier] = nil
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
  local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle, 
  					 		  orb, 
                         	  self.context.IComponent, 
                         	  "AccessControlServiceReceptacle", 
                         	  "IAccessControlService", 
                         	  "IDL:openbusidl/acs/IAccessControlService:1.0")
                         	  
  if not status then
	  -- erro ja foi logado, s� retorna
	  return nil
  end     
  -- registra novamente o observador de credenciais
  self.observerId = acsFacet:addObserver(
      self.context.ICredentialObserver, {}
  )
  Log:session("Observador recadastrado")

  -- Mant�m apenas as sess�es com credenciais v�lidas
  local invalidCredentials = {}
  for credentialId, session in pairs(self.sessions) do
    if not acsFacet:addCredentialToObserver(self.observerId,
        credentialId) then
      Log:session("Sess�o para "..credentialId.." ser� removida")
      table.insert(invalidCredentials, credentialId)
    else
      Log:session("Sess�o para "..credentialId.." ser� mantida")
    end
  end
  for _, credentialId in ipairs(invalidCredentials) do
    self.sessions[credentialId] = nil
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
    Log:error("Erro durante conex�o com servi�o de Controle de Acesso.")
    Log:error(conId)
    error{"IDL:SCS/StartupFailed:1.0"}
 end
end

--------------------------------------------------------------------------------
-- Faceta ICredentialObserver
--------------------------------------------------------------------------------

Observer = oop.class{}

function Observer:credentialWasDeleted(credential)
  self.context.ISessionService:credentialWasDeleted(credential)
end



