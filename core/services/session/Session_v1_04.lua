-- $Id: Session.lua 103010 2010-03-15 18:12:26Z brunoos $

local oop = require "loop.base"

---
--Sess�o compartilhada pelos membros associados a uma mesma credencial na versao 1.04.
---
module "core.services.session.Session_v1_04"

local eventSinkInterface = "IDL:openbusidl/ss/SessionEventSink:1.0"

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
--TODO: aqui pode dar problema pois o event contem um Any. Verificar.
  self.context.SessionEventSink:push(event)
end

function SessionEventSink:disconnect()
  self.context.SessionEventSink:disconnect()
end
