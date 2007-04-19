-----------------------------------------------------------------------------
-- Sess�o compartilhada pelos membros associados a uma mesma credencial
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
local uuid = require "uuid"

local tostring = tostring

local log = require "openbus.common.Log"

local oop = require "loop.base"

module("openbus.services.session.Session", oop.class)

-- Constr�i a sess�o
function __init(self, identifier, credential)
  log:service("Construindo sess�o com id "..tostring(identifier))
  return oop.rawnew(self, {identifier = identifier, credential = credential,
                           sessionMembers = {}})
end

-- Obt�m o identificador da sess�o
function getIdentifier(self)
  return self.identifier
end

-- Adiciona um membro � sess�o
function addMember(self, member)
  log:service("Membro "..member:getName().." adicionado � sess�o")
  local memberIdentifier = self:generateMemberIdentifier()
  self.sessionMembers[memberIdentifier] = member
  return memberIdentifier
end

-- Remove um membro da sess�o
function removeMember(self, memberIdentifier)
  member = self.sessionMembers[memberIdentifier]
  if not member then
    return false
  end
  log:service("Membro "..member:getName().." removido da sess�o")
  self.sessionMembers[memberIdentifier] = nil
  return true
end

-- Obt�m a lista de membros de uma sess�o
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
