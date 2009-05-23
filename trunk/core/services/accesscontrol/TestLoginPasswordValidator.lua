-- $Id$

local LoginPasswordValidator =
    require "core.services.accesscontrol.LoginPasswordValidator"

local oop = require "loop.simple"

---
--Representa um validador de usuário e senha para testes.
---
module("core.services.accesscontrol.TestLoginPasswordValidator")

oop.class(_M, LoginPasswordValidator)

---
--@see core.services.accesscontrol.LoginPasswordValidator#validate
---
function validate(self, name, password)
  if name == "tester" and password == "tester" then
    return true
  end
  return false, "O usuário "..name.." é desconhecido."
end
