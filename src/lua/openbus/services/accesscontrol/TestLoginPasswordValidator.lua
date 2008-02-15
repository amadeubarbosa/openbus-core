-- $Id$

local LoginPasswordValidator =
    require "openbus.services.accesscontrol.LoginPasswordValidator"

local oop = require "loop.simple"

---
--Representa um validador de usuário e senha para testes.
---
module("openbus.services.accesscontrol.TestLoginPasswordValidator")

oop.class(_M, LoginPasswordValidator)

---
--@see openbus.services.accesscontrol.LoginPasswordValidator#validate
---
function validate(self, name, password)
  if name == "tester" and password == "tester" then
    return true
  end
  return false, "O usuário "..name.." é desconhecido."
end
