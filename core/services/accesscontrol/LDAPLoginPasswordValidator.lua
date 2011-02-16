-- $Id$

local ipairs = ipairs
local string = string

local lualdap = require "lualdap"
local oop = require "loop.simple"
local Log = require "openbus.util.Log"

local LoginPasswordValidator =
    require "core.services.accesscontrol.LoginPasswordValidator"

---
--Representa um validador de usu�rio e senha atrav�s de LDAP.
---
module("core.services.accesscontrol.LDAPLoginPasswordValidator")
oop.class(_M, LoginPasswordValidator)


---
--Cria o validador LDAP.
--
--@param config As configura��es do AcessControlService.
--
--@return O validador.
---
function __init(self, config)
  return oop.rawnew(self, {
    ldapHosts = config.ldapHosts,
    ldapSuffixes = config.ldapSuffixes,
  })
end

---
--@see core.services.accesscontrol.LoginPasswordValidator#validate
---
function validate(self, name, password)
  if not password or string.match(password, "^%s*$") then
    return false,
        "O usu�rio "..name.." n�o foi validado porque sua senha est� vazia."
  end

  for _, ldapHost in ipairs(self.ldapHosts) do
    for _, ldapSuffix in ipairs(self.ldapSuffixes) do
      local connection, err = lualdap.open_simple(
          ldapHost.name..":"..ldapHost.port, name..ldapSuffix, password, false, 5)
      if connection then
        Log:debug(string.format("O usu�rio %s foi autenticado por %s",
            name..ldapSuffix, ldapHost.name))
        connection:close()
        return true
      end
    end
  end
  return false, "O usu�rio "..name.." n�o foi validado."
end
