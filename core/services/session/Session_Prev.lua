-- $Id:

local oop = require "loop.base"
local Utils = require "openbus.util.Utils"

---
--Sessão compartilhada pelos membros associados a uma mesma credencial na versão anterior.
---
module "core.services.session.Session_Prev"

--------------------------------------------------------------------------------
-- Faceta ISession
--------------------------------------------------------------------------------

Session = oop.class{}

function Session:getIdentifier()
  return self.context["ISession_" .. Utils.IDL_VERSION]:getIdentifier()
end

function Session:addMember(member)
  return self.context["ISession_" .. Utils.IDL_VERSION]:addMember(member)
end

function Session:removeMember(identifier)
  return self.context["ISession_" .. Utils.IDL_VERSION]:removeMember(identifier)
end

function Session:getMembers()
  return self.context["ISession_" .. Utils.IDL_VERSION]:getMembers()
end

--------------------------------------------------------------------------------
-- Faceta SessionEventSink
--------------------------------------------------------------------------------

SessionEventSink = oop.class{}

function SessionEventSink:push(event)
  self.context["SessionEventSink_" .. Utils.IDL_VERSION]:push(Utils.IDL_PREV, event)
end

function SessionEventSink:disconnect()
  self.context["SessionEventSink_" .. Utils.IDL_VERSION]:disconnect(Utils.IDL_PREV)
end

