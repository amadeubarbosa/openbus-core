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
--Sessão compartilhada pelos membros associados a uma mesma credencial.
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
--Obtém o identificador da sessão.
--
--@return O identificador da sessão.
---
function Session:getIdentifier()
  return self.identifier
end

---
--Adiciona um membro a sessão.
--
--@param member O membro a ser adicionado.
--
--@return O identificador do membro na sessão.
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
  Log:info(format("O membro %s:%d.%d.%d adicionado à sessão %s",
      componentId.name, componentId.major_version, componentId.minor_version,
      componentId.patch_version, self.identifier))

  -- Verifica se o membro recebe eventos
  local eventSink = member:getFacet(eventSinkInterface)
  local eventSinkPrev = member:getFacet(eventSinkInterfacePrev)
  if eventSink then
    Log:debug(format("O membro %s:%d.%d.%d receberá eventos", componentId.name,
        componentId.major_version, componentId.minor_version,
        componentId.patch_version))
    self.context.SessionEventSink.eventSinks[info.memberId] =
      orb:narrow(eventSink, eventSinkInterface)
  else
    if eventSinkPrev then
      Log:debug("O membro %s:%d.%d.%d receberá eventos da versão %d",
          componentId.name, componentId.major_version, componentId.minor_version,
          componentId.patch_version, Utils.OB_PREV)
      self.context.SessionEventSink.eventSinksPrev[info.memberId] =
        orb:narrow(eventSinkPrev, eventSinkInterfacePrev)
    else
      Log:warn(format("O membro %s:%d.%d.%d não receberá eventos",
          componentId.name, componentId.major_version, componentId.minor_version,
          componentId.patch_version))
    end
  end
  return info.memberId
end

---
--Remove um membro da sessão.
--
--@param identifier O identificador do membro na sessão.
--
--@return true caso o membro tenha sido removido da sessão, ou false caso
--contrário.
---
function Session:removeMember(identifier)
  local info = self.sessionMembers[identifier]
  if not info then
    Log:error("Impossível remover membro "..identifier..
      ": não faz parte da sessão "..self.identifier)
    return false
  end
  local componentId = info.member:getComponentId()
  Log:info(format("O membro %s:%d.%d.%d foi removido da sessão %s",
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
--Obtém a lista de membros de uma sessão.
--
--@return Os membros da sessão.
---
function Session:getMembers()
  local members = {}
  for _, info in pairs(self.sessionMembers) do
    members[#members+1] = info.member
  end
  return members
end

---
--Gera um identificador de membros de sessão.
--
--@return O identificador de membro de sessão.
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
--Repassa evento para membros da sessão.
--
--@param event O evento.
---
function SessionEventSink:push(sender, event)
  Log:info(format("O membro %s enviou um evento do tipo %s", sender,
      event.type))

  for memberId, sink in pairs(self.eventSinks) do
    local result, errorMsg = oil.pcall(sink.push, sink, sender, event)
    if not result then
      Log:debug(format("Falha ao tentar enviar um evento do tipo %s ao membro %s (versão %s",
          event.type, memberId, Utils.OB_VERSION), errorMsg)
    end
  end
  for memberId, sink in pairs(self.eventSinksPrev) do
    local result, errorMsg = oil.pcall(sink.push, sink, event)
    if not result then
      Log:debug(format("Falha ao tentar enviar um evento do tipo %s ao membro %s (versão %s)",
          event.type, memberId, Utils.OB_PREV),errorMsg)
    end
  end
end

---
--Solicita a desconexão de todos os membros da sessão.
---
function SessionEventSink:disconnect(sender)
  Log:info(format("O membro %s enviou um evento de desconexão", sender))

  for memberId, sink in pairs(self.eventSinks) do
    local result, errorMsg = oil.pcall(sink.disconnect, sink, sender)
    if not result then
      Log:warn(format("Falha ao tentar enviar um evento de desconexão ao membro %s (versão %s)",
          memberId, Utils.OB_VERSION), errorMsg)
    end
  end
  for memberId, sink in pairs(self.eventSinksPrev) do
    local result, errorMsg = oil.pcall(sink.disconnect, sink)
    if not result then
      Log:warn(format("Falha ao tentar enviar um evento de desconexão ao membro %s (versão %s)",
          memberId, Utils.OB_PREV), errorMsg)
    end
  end
end

