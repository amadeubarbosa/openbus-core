-- $Id$

local lualdap = require "lualdap"
local oop = require "loop.simple"

local LoginPasswordValidator =
    require "openbus.services.accesscontrol.LoginPasswordValidator"

---
--Representa um validador de usuário e senha através de LDAP.
---
module("openbus.services.accesscontrol.LDAPLoginPasswordValidator")
oop.class(_M, LoginPasswordValidator)

---
--Cria o validador LDAP.
--
--@param ldapHost O endereço do servidor LDAP no formato servidor:porta.
--
--@return O validador.
---
function __init(self, ldapHost)
  return oop.rawnew(self, {
    ldapHost = ldapHost,
  })
end

---
--@see openbus.services.accesscontrol.LoginPasswordValidator#validate
---
function validate(self, name, password)
  local connection, err = lualdap.open_simple(self.ldapHost, name, password,
      false)
  if not connection then
    return false, err
  end
  connection:close()
  return true
end
