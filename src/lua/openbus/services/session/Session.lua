--
-- Sessão compartilhada pelos membros associados a uma mesma credencial
--
-- $Id$
--
require "uuid"

local oop = require "loop.base"

Session = oop.class{
  sessionMembers = {},
}

-- Obtém o identificador da sessão
function Session:getIdentifier()
  return self.identifier
end

-- Adiciona um membro à sessão
function Session:addMember(member)
  local memberIdentifier = self:generateMemberIdentifier()
  self.sessionMembers[memberIdentifier] = member
end

-- Remove um membro da sessão
function Session:removeMember(memberIdentifier)
  if not self.sessionMembers[memberIdentifier] then
    return false
  end
  self.sessionMembers[memberIdentifier] = nil
  return true
end

-- Obtém a lista de membros de uma sessão
function Session:getMembers()
  local members = {}
  for _, member in pairs(self.sessionMembers) do
    table.insert(members, member)
  end
  return members
end

function Session:generateMemberIdentifier()
    return uuid.new("time")
end
