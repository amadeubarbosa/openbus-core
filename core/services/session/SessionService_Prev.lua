-- $Id: 

local oop = require "loop.base"

---
--Faceta que disponibiliza a funcionalidade b�sica do servi�o de sess�o na vers�o anterior.
---
module "core.services.session.SessionService_Prev"

--------------------------------------------------------------------------------
-- Faceta ISessionService
--------------------------------------------------------------------------------

SessionService = oop.class{}

function SessionService:createSession(member)
  return self.context.ISessionService:createSession(member)
end

function SessionService:getSession()
  return self.context.ISessionService:getSession()
end

