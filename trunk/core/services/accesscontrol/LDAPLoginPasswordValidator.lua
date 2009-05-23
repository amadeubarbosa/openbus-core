-- $Id$

local ipairs = ipairs

local lualdap = require "lualdap"
local oop = require "loop.simple"

local LoginPasswordValidator =
    require "core.services.accesscontrol.LoginPasswordValidator"

---
--Representa um validador de usuário e senha através de LDAP.
---
module("core.services.accesscontrol.LDAPLoginPasswordValidator")
oop.class(_M, LoginPasswordValidator)

---
--Cria o validador LDAP.
--
--@param ldapHost O endereço do servidor LDAP no formato servidor:porta.
--
--@return O validador.
---
function __init(self, ldapHosts, ldapSuffixes)
  return oop.rawnew(self, {
    ldapHosts = ldapHosts,
    ldapSuffixes = ldapSuffixes,
  })
end

---
--@see core.services.accesscontrol.LoginPasswordValidator#validate
---
function validate(self, name, password)
  for _, ldapHost in ipairs(self.ldapHosts) do
    for _, ldapSuffix in ipairs(self.ldapSuffixes) do
      local connection, err = lualdap.open_simple(
          ldapHost.name..":"..ldapHost.port, name..ldapSuffix, password, false)
      if connection then
        connection:close()
        return true
      end
    end
  end
  return false, "O usuário "..name.." não foi validado."
end
