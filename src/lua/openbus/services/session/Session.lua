-----------------------------------------------------------------------------
-- Sessão compartilhada pelos membros associados a uma mesma credencial
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local uuid = require "uuid"

local tostring = tostring

local log = require "openbus.common.Log"

local oop = require "loop.base"

module("openbus.services.session.Session", oop.class)

-- Constrói a sessão
function __init(self, identifier, credential)
  log:service("Construindo sessão com id "..tostring(identifier))
  return oop.rawnew(self, {identifier = identifier, credential = credential,
                           sessionMembers = {}})
end

-- Obtém o identificador da sessão
function getIdentifier(self)
  return self.identifier
end

-- Adiciona um membro à sessão
function addMember(self, member)
  log:service("Membro "..member:getName().." adicionado à sessão")
  local memberIdentifier = self:generateMemberIdentifier()
  self.sessionMembers[memberIdentifier] = member
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
  return true
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
