-- $Id$

local lualdap = require "lualdap"
local oop = require "loop.simple"

local LoginPasswordValidator =
    require "openbus.services.accesscontrol.LoginPasswordValidator"

---
--Representa um validador de usu�rio e senha atrav�s de LDAP.
---
module("openbus.services.accesscontrol.LDAPLoginPasswordValidator")
oop.class(_M, LoginPasswordValidator)

function __init(self, ldapHost)
  return oop.rawnew(self, {
    ldapHost = ldapHost,
  })
end

function validate(self, name, password)
  local connection, err = lualdap.open_simple(self.ldapHost, name, password,
      false)
  if not connection then
    return false, err
  end
  connection:close()
  return true
end
