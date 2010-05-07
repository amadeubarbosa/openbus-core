-- $Id: Session.lua 103010 2010-03-15 18:12:26Z brunoos $

local oop = require "loop.base"

---
--Sessão compartilhada pelos membros associados a uma mesma credencial na versao 1.04.
---
module "core.services.session.Session_v1_04"

--------------------------------------------------------------------------------
-- Faceta ISession
--------------------------------------------------------------------------------

Session = oop.class{}

function Session:getIdentifier()
  return self.context.ISession:getIdentifier()
end

function Session:addMember(member)
  return self.context.ISession:addMember(member) 
end

function Session:removeMember(identifier)
  return self.context.ISession:removeMember(identifier)
end

function Session:getMembers()
  return self.context.ISession:getMembers()
end

--------------------------------------------------------------------------------
-- Faceta SessionEventSink
--------------------------------------------------------------------------------

SessionEventSink = oop.class{}

function SessionEventSink:push(event)
  self.context.SessionEventSink:push("v1_04", event)
end

function SessionEventSink:disconnect()
  self.context.SessionEventSink:disconnect("v1_04")
end

