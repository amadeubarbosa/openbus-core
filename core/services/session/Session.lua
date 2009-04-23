-- $Id$

local tostring = tostring
local ipairs = ipairs
local pairs = pairs

local oil = require "oil"
local orb = oil.orb

local luuid = require "uuid"

local Log = require "openbus.common.Log"

local oop = require "loop.base"

---
--Sessão compartilhada pelos membros associados a uma mesma credencial.
---
module "core.services.session.Session"

--------------------------------------------------------------------------------
-- Faceta ISession
--------------------------------------------------------------------------------

Session = oop.class{sessionMembers = {}}

---
--Obtï¿½m o identificador da sessão.
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
  local memberName = member:getComponentId().name
  Log:service("Membro "..memberName.." adicionado a sessão")
  local identifier = self:generateMemberIdentifier()
  self.sessionMembers[identifier] = member

  -- verifica se o membro recebe eventos
  local eventSinkInterface = "IDL:openbusidl/ss/SessionEventSink:1.0"
  local eventSink = member:getFacet(eventSinkInterface)
  if eventSink then
    Log:service("Membro "..memberName.." receberá eventos")
    local eventSinks = self.context.SessionEventSink.eventSinks
    eventSinks[identifier] =  orb:narrow(eventSink,
        eventSinkInterface)
  else
    Log:service("Membro "..memberName.." não receberá eventos")
  end
  return identifier
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
  member = self.sessionMembers[identifier]
  if not member then
    return false
  end
  Log:service("Membro "..member:getComponentId().name.." removido da sessão")
  self.sessionMembers[identifier] = nil
  self.context.SessionEventSink.eventSinks[identifier] = nil
  return true
end

---
--Obtém a lista de membros de uma sessão.
--
--@return Os membros da sessão.
---
function Session:getMembers()
  local members = {}
  for _, member in pairs(self.sessionMembers) do
    table.insert(members, member)
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

SessionEventSink = oop.class{eventSinks = {}}

---
--Repassa evento para membros da sessão.
--
--@param event O evento.
---
function SessionEventSink:push(event)
  Log:service("Repassando evento "..event.type.." para membros de sessão")
  for _, sink in pairs(self.eventSinks) do
    local result, errorMsg = oil.pcall(sink.push, sink, event)
    if not result then
      Log:service("Erro ao enviar evento para membro de sessão: "..errorMsg)
    end
  end
end

---
--Solicita a desconexão de todos os membros da sessão.
---
function SessionEventSink:disconnect(self)
  Log:service("Desconectando os membros da sessão")
  for _, sink in pairs(self.eventSinks) do
    sink:disconnect()
  end
end


