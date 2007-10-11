-----------------------------------------------------------------------------
-- Sessão compartilhada pelos membros associados a uma mesma credencial
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local print = print
local tostring = tostring
local ipairs = ipairs
local pairs = pairs

local oil = require "oil"
local luuid = require "luuid"

local Log = require "openbus.common.Log"

local oop = require "loop.base"
module("openbus.services.session.Session", oop.class)

-- Constrói a sessão
function __init(self, identifier, credential)
  Log:service("Construindo sessão com id "..tostring(identifier))
  return oop.rawnew(self, {identifier = identifier, credential = credential,
                           sessionMembers = {}, eventSinks = {}})
end

-- Obtém o identificador da sessão
function getIdentifier(self)
  return self.identifier
end

-- Adiciona um membro à sessão
function addMember(self, member)
  local memberName = member:getClassId().name
  Log:service("Membro "..memberName.." adicionado à sessão")
  local memberIdentifier = self:generateMemberIdentifier()
  self.sessionMembers[memberIdentifier] = member

  -- verifica se o membro recebe eventos
  local eventSinkInterface = "IDL:openbusidl/ss/SessionEventSink:1.0"
  local eventSink = member:getFacet(eventSinkInterface)
  if eventSink then
    Log:service("Membro "..memberName.." receberá eventos")
    self.eventSinks[memberIdentifier] =  oil.narrow(eventSink,
        eventSinkInterface)
  else
    Log:service("Membro "..memberName.." não receberá eventos")
  end
  return memberIdentifier
end

-- Remove um membro da sessão
function removeMember(self, memberIdentifier)
  member = self.sessionMembers[memberIdentifier]
  if not member then
    return false
  end
  Log:service("Membro "..member:getClassId().name.." removido da sessão")
  self.sessionMembers[memberIdentifier] = nil
  self.eventSinks[memberIdentifier] = nil
  return true
end

-- Repassa evento para membros da sessão
function push(self, event)
  Log:service("Repassando evento "..event.type.." para membros de sessão")
  for _, sink in pairs(self.eventSinks) do
    sink:push(event)
  end
end

function disconnect(self)
  Log:service("Desconectando os membros da sessão")
  for _, sink in pairs(self.eventSinks) do
    sink:disconnect()
  end
end

-- Obtém a lista de membros de uma sessão
function getMembers(self)
  local members = {}
  for _, member in pairs(self.sessionMembers) do
    table.insert(members, member)
  end
  return members
end

function generateMemberIdentifier()
  return luuid.new("time")
end
