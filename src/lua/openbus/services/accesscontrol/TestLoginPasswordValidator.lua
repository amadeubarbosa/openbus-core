local LoginPasswordValidator =
    require "openbus.services.accesscontrol.LoginPasswordValidator"

local oop = require "loop.simple"
module("openbus.services.accesscontrol.TestLoginPasswordValidator")
oop.class(_M, LoginPasswordValidator)

function validate(self, name, password)
  if name == "tester" and password == "tester" then
    return true
  end
  return false, "O usuário "..name.." é desconhecido."
end
