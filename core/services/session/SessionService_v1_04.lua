-- $Id: SessionService.lua 103125 2010-03-17 03:52:33Z mgatti $

local oop = require "loop.base"

---
--Faceta que disponibiliza a funcionalidade básica do serviço de sessão na versao 1.04.
---
module "core.services.session.SessionService_v1_04"

local acsIDL = "IDL:openbusidl/acs/IAccessControlService:1.0"

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

