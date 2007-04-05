--
-- Sessão compartilhada pelos membros associados a uma mesma credencial
--
-- $Id$
--
require "uuid"

local oop = require "loop.base"

module("openbus.services.session.Session", oop.class)

sessionMembers = {}

-- Obtém o identificador da sessão
function getIdentifier(self)
  return self.identifier
end

-- Adiciona um membro à sessão
function addMember(self, member)
  local memberIdentifier = self:generateMemberIdentifier()
  self.sessionMembers[memberIdentifier] = member
end

-- Remove um membro da sessão
function removeMember(self, memberIdentifier)
  if not self.sessionMembers[memberIdentifier] then
    return false
  end
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
