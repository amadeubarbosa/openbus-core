-- $Id:

local oop = require "loop.base"

---
--Sessão compartilhada pelos membros associados a uma mesma credencial na versão anterior.
---
module "core.services.session.Session_Prev"

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

function SessionEventSink:push(sender, event)
  self.context.SessionEventSink:push(sender, event)
end

function SessionEventSink:disconnect(sender)
  self.context.SessionEventSink:disconnect(sender)
end

