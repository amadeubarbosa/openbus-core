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
module("core.services.accesscontrol.ActiveDirectoryLoginValidator")
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
    ldapUrls = config.ldapUrls,
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

  for _, ldapUrl in ipairs(self.ldapUrls) do
    for _, ldapSuffix in ipairs(self.ldapSuffixes) do
      local connection, err
      local who = name..ldapSuffix
      -- security enforcement
      -- if the url indicates LDAP raw protocol, we try use LDAP+StartTLS
      if ldapUrl:match("^ldap://") then
        connection, err = lualdap.open_simple(ldapUrl, who, password, true, 5)
      end
      -- if url already indicates LDAPS or if the server rejects LDAP+StartTLS
      if ldapUrl:match("^ldaps://") or not connection then
        connection, err = lualdap.open_simple(ldapUrl, who, password, false, 5)
      end
      if connection then
        Log:debug(string.format("O usu�rio %s foi autenticado por %s",
            who, ldapUrl))
        connection:close()
        return true
      end
    end
  end
  return false, "O usu�rio "..name.." n�o foi validado."
end
