-----------------------------------------------------------------------------
-- Sess�o compartilhada pelos membros associados a uma mesma credencial
--
-- �ltima altera��o:
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

-- Constr�i a sess�o
function __init(self, identifier, credential)
  Log:service("Construindo sess�o com id "..tostring(identifier))
  return oop.rawnew(self, {identifier = identifier, credential = credential,
                           sessionMembers = {}, eventSinks = {}})
end

-- Obt�m o identificador da sess�o
function getIdentifier(self)
  return self.identifier
end

-- Adiciona um membro � sess�o
function addMember(self, member)
  local memberName = member:getClassId().name
  Log:service("Membro "..memberName.." adicionado � sess�o")
  local memberIdentifier = self:generateMemberIdentifier()
  self.sessionMembers[memberIdentifier] = member

  -- verifica se o membro recebe eventos
  local eventSinkInterface = "IDL:openbusidl/ss/SessionEventSink:1.0"
  local eventSink = member:getFacet(eventSinkInterface)
  if eventSink then
    Log:service("Membro "..memberName.." receber� eventos")
    self.eventSinks[memberIdentifier] =  oil.narrow(eventSink,
        eventSinkInterface)
  else
    Log:service("Membro "..memberName.." n�o receber� eventos")
  end
  return memberIdentifier
end

-- Remove um membro da sess�o
function removeMember(self, memberIdentifier)
  member = self.sessionMembers[memberIdentifier]
  if not member then
    return false
  end
  Log:service("Membro "..member:getClassId().name.." removido da sess�o")
  self.sessionMembers[memberIdentifier] = nil
  self.eventSinks[memberIdentifier] = nil
  return true
end

-- Repassa evento para membros da sess�o
function push(self, event)
  Log:service("Repassando evento "..event.type.." para membros de sess�o")
  for _, sink in pairs(self.eventSinks) do
    sink:push(event)
  end
end

function disconnect(self)
  Log:service("Desconectando os membros da sess�o")
  for _, sink in pairs(self.eventSinks) do
    sink:disconnect()
  end
end

-- Obt�m a lista de membros de uma sess�o
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
