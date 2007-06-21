-----------------------------------------------------------------------------
-- Sessão compartilhada pelos membros associados a uma mesma credencial
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local uuid = require "uuid"

local oil = require "oil"
local log = require "openbus.common.Log"
local oop = require "loop.base"

local tostring = tostring
local ipairs = ipairs
local pairs = pairs

module("openbus.services.session.Session", oop.class)

-- Constrói a sessão
function __init(self, identifier, credential)
  log:service("Construindo sessão com id "..tostring(identifier))
  return oop.rawnew(self, {identifier = identifier, credential = credential,
                           sessionMembers = {}, eventSinks = {}})
end

-- Obtém o identificador da sessão
function getIdentifier(self)
  return self.identifier
end

-- Adiciona um membro à sessão
function addMember(self, member)
  local memberName = member:getName()
  log:service("Membro "..memberName.." adicionado à sessão")
  local memberIdentifier = self:generateMemberIdentifier()
  self.sessionMembers[memberIdentifier] = member

  -- verifica se o membro recebe eventos
  local eventSinkInterface = "IDL:openbusidl/ss/SessionEventSink:1.0"
  local facet_descriptions = member:getFacets()
  local is_sink = false
  if #facet_descriptions > 0 then
    for _, facet in ipairs(facet_descriptions) do
      if facet.interface_name == eventSinkInterface then
        log:service("Membro "..memberName.." receberá eventos")
        self.eventSinks[memberIdentifier] = 
          oil.narrow(facet.facet_ref, eventSinkInterface)
        is_sink = true
        break
      end
    end
  end
  if not is_sink then
    log:service("Membro "..memberName.." não receberá eventos")
   end
  return memberIdentifier
end

-- Remove um membro da sessão
function removeMember(self, memberIdentifier)
  member = self.sessionMembers[memberIdentifier]
  if not member then
    return false
  end
  log:service("Membro "..member:getName().." removido da sessão")
  self.sessionMembers[memberIdentifier] = nil
  self.eventSinks[memberIdentifier] = nil
  return true
end

-- Repassa evento para membros da sessão
function push(self, event)
  log:service("Repassando evento "..event.type.." para membros de sessão")
  for _, sink in pairs(self.eventSinks) do
    sink:push(event)
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

function generateMemberIdentifier(self)
    return uuid.new("time")
end
