-- $Id$

local ipairs = ipairs
local string = string

local lualdap = require "lualdap"
local oop = require "loop.simple"
local Log = require "openbus.util.Log"

local LoginPasswordValidator =
    require "core.services.accesscontrol.LoginPasswordValidator"

---
--Representa um validador de usuário e senha através de LDAP.
---
module("core.services.accesscontrol.ActiveDirectoryLoginValidator")
oop.class(_M, LoginPasswordValidator)


---
--Cria o validador LDAP.
--
--@param config As configurações do AcessControlService.
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
        "O usuário "..name.." não foi validado porque sua senha está vazia."
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
        Log:debug(string.format("O usuário %s foi autenticado por %s",
            who, ldapUrl))
        connection:close()
        return true
      end
    end
  end
  return false, "O usuário "..name.." não foi validado."
end
