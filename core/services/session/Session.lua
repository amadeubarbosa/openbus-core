-- $Id$

local tostring = tostring
local ipairs   = ipairs
local pairs    = pairs
local next     = next
local format   = string.format

local oil     = require "oil"
local luuid   = require "uuid"
local oop     = require "loop.base"
local Openbus = require "openbus.Openbus"
local Log     = require "openbus.util.Log"
local Utils   = require "openbus.util.Utils"

local orb = oil.orb

---
--Sess�o compartilhada pelos membros associados a uma mesma credencial.
---
module "core.services.session.Session"

local eventSinkInterface = Utils.SESSION_ES_INTERFACE
local eventSinkInterfacePrev = Utils.SESSION_ES_INTERFACE_V1_04

--------------------------------------------------------------------------------
-- Faceta ISession
--------------------------------------------------------------------------------

Session = oop.class{}

function Session:__init()
  return oop.rawnew(self, {sessionMembers = {}, membersByCredential = {}})
end

---
--Obt�m o identificador da sess�o.
--
--@return O identificador da sess�o.
---
function Session:getIdentifier()
  return self.identifier
end

---
--Adiciona um membro a sess�o.
--
--@param member O membro a ser adicionado.
--
--@return O identificador do membro na sess�o.
---
function Session:addMember(member)
  local credential = Openbus:getInterceptedCredential()
  local info = {
    member = member,
    credentialId = credential.identifier,
    memberId = self:generateMemberIdentifier(),
  }
  self.sessionMembers[info.memberId] = info
  local members = self.membersByCredential[info.credentialId]
  if not members then
    members = {}
    self.membersByCredential[info.credentialId] = members
    self.sessionService:observe(info.credentialId, self)
  end
  members[info.memberId] = info
  local componentId = member:getComponentId()
  Log:info(format("O membro %s:%d.%d.%d adicionado � sess�o %s",
      componentId.name, componentId.major_version, componentId.minor_version,
      componentId.patch_version, self.identifier))

  -- Verifica se o membro recebe eventos
  local eventSink = member:getFacet(eventSinkInterface)
  local eventSinkPrev = member:getFacet(eventSinkInterfacePrev)
  if eventSink then
    Log:debug(format("O membro %s:%d.%d.%d receber� eventos", componentId.name,
        componentId.major_version, componentId.minor_version,
        componentId.patch_version))
    self.context.SessionEventSink.eventSinks[info.memberId] =
      orb:narrow(eventSink, eventSinkInterface)
  else
    if eventSinkPrev then
      Log:debug("O membro %s:%d.%d.%d receber� eventos da vers�o %d",
          componentId.name, componentId.major_version, componentId.minor_version,
          componentId.patch_version, Utils.OB_PREV)
      self.context.SessionEventSink.eventSinksPrev[info.memberId] =
        orb:narrow(eventSinkPrev, eventSinkInterfacePrev)
    else
      Log:warn(format("O membro %s:%d.%d.%d n�o receber� eventos",
          componentId.name, componentId.major_version, componentId.minor_version,
          componentId.patch_version))
    end
  end
  return info.memberId
end

---
--Remove um membro da sess�o.
--
--@param identifier O identificador do membro na sess�o.
--
--@return true caso o membro tenha sido removido da sess�o, ou false caso
--contr�rio.
---
function Session:removeMember(identifier)
  local info = self.sessionMembers[identifier]
  if not info then
    Log:error("Imposs�vel remover membro "..identifier..
      ": n�o faz parte da sess�o "..self.identifier)
    return false
  end
  local componentId = info.member:getComponentId()
  Log:info(format("O membro %s:%d.%d.%d foi removido da sess�o %s",
      componentId.name, componentId.major_version, componentId.minor_version,
      componentId.patch_version, self.identifier))
  self.sessionMembers[info.memberId] = nil
  self.membersByCredential[info.credentialId][info.memberId] = nil
  self.context.SessionEventSink.eventSinks[info.memberId] = nil
  self.context.SessionEventSink.eventSinksPrev[info.memberId] = nil
  if not (next(self.membersByCredential[info.credentialId])) then
    self.membersByCredential[info.credentialId] = nil
    self.sessionService:unObserve(info.credentialId, self)
  end
  return true
end

---
-- Membro saiu do barramento, limpar contexto
--
-- @param credential Credencial do membro
--
function Session:credentialWasDeletedById(credentialId)
  local members = self.membersByCredential[credentialId]
  for memberId in pairs(members) do
    self.sessionMembers[memberId] = nil
    self.context.SessionEventSink.eventSinks[memberId] = nil
    self.context.SessionEventSink.eventSinksPrev[memberId] = nil
  end
  self.membersByCredential[credentialId] = nil
end

---
--Obt�m a lista de membros de uma sess�o.
--
--@return Os membros da sess�o.
---
function Session:getMembers()
  local members = {}
  for _, info in pairs(self.sessionMembers) do
    members[#members+1] = info.member
  end
  return members
end

---
--Gera um identificador de membros de sess�o.
--
--@return O identificador de membro de sess�o.
---
function Session:generateMemberIdentifier()
  return luuid.new("time")
end

--------------------------------------------------------------------------------
-- Faceta SessionEventSink
--------------------------------------------------------------------------------

SessionEventSink = oop.class{}

function SessionEventSink:__init()
  return oop.rawnew(self, {eventSinks = {}, eventSinksPrev = {}})
end

---
--Repassa evento para membros da sess�o.
--
--@param event O evento.
---
function SessionEventSink:push(sender, event)
  Log:info(format("O membro %s enviou um evento do tipo %s", sender,
      event.type))

  for memberId, sink in pairs(self.eventSinks) do
    local result, errorMsg = oil.pcall(sink.push, sink, sender, event)
    if not result then
      Log:debug(format("Falha ao tentar enviar um evento do tipo %s ao membro %s (vers�o %s",
          event.type, memberId, Utils.OB_VERSION), errorMsg)
    end
  end
  for memberId, sink in pairs(self.eventSinksPrev) do
    local result, errorMsg = oil.pcall(sink.push, sink, event)
    if not result then
      Log:debug(format("Falha ao tentar enviar um evento do tipo %s ao membro %s (vers�o %s)",
          event.type, memberId, Utils.OB_PREV),errorMsg)
    end
  end
end

---
--Solicita a desconex�o de todos os membros da sess�o.
---
function SessionEventSink:disconnect(sender)
  Log:info(format("O membro %s enviou um evento de desconex�o", sender))

  for memberId, sink in pairs(self.eventSinks) do
    local result, errorMsg = oil.pcall(sink.disconnect, sink, sender)
    if not result then
      Log:warn(format("Falha ao tentar enviar um evento de desconex�o ao membro %s (vers�o %s)",
          memberId, Utils.OB_VERSION), errorMsg)
    end
  end
  for memberId, sink in pairs(self.eventSinksPrev) do
    local result, errorMsg = oil.pcall(sink.disconnect, sink)
    if not result then
      Log:warn(format("Falha ao tentar enviar um evento de desconex�o ao membro %s (vers�o %s)",
          memberId, Utils.OB_PREV), errorMsg)
    end
  end
end

