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

local orb = oil.orb

---
--Sess�o compartilhada pelos membros associados a uma mesma credencial.
---
module "core.services.session.Session"

local eventSinkInterface = "IDL:tecgraf/openbus/v1_05/session_service/SessionEventSink:1.0"

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
  local memberName = member:getComponentId().name
  Log:session("Membro "..memberName.." adicionado � sess�o "..self.identifier)
  -- Verifica se o membro recebe eventos
  local eventSink = member:getFacet(eventSinkInterface)
  if eventSink then
    Log:session("Membro "..memberName.." receber� eventos")
    self.context.SessionEventSink.eventSinks[info.memberId] =
      orb:narrow(eventSink, eventSinkInterface)
  else
    Log:session("Membro "..memberName.." n�o receber� eventos")
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
  Log:session("Membro "..info.member:getComponentId().name..
    " removido da sess�o "..self.identifier)
  self.sessionMembers[info.memberId] = nil
  self.membersByCredential[info.credentialId][info.memberId] = nil
  self.context.SessionEventSink.eventSinks[info.memberId] = nil
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
  return oop.rawnew(self, {eventSinks = {}})
end

---
--Repassa evento para membros da sess�o.
--
--@param event O evento.
---
function SessionEventSink:push(event)
  Log:session("Repassando evento "..event.type.." para membros de sess�o")
  for memberId, sink in pairs(self.eventSinks) do
    local result, errorMsg = oil.pcall(sink.push, sink, event)
    if not result then
      Log:session("Erro ao enviar evento para membro de sess�o: "..errorMsg)
    end
  end
end

---
--Solicita a desconex�o de todos os membros da sess�o.
---
function SessionEventSink:disconnect()
  Log:session("Desconectando os membros da sess�o")
  for memberId, sink in pairs(self.eventSinks) do
    local result, errorMsg = oil.pcall(sink.disconnect, sink)
    if not result then
      Log:session("Erro ao tentar desconectar membro de sess�o: "..errorMsg)
    end
  end
end
