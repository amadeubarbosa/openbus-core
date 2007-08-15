local lualdap = require "lualdap"

local LoginPasswordValidator =
    require "openbus.services.accesscontrol.LoginPasswordValidator"

local oop = require "loop.simple"
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
