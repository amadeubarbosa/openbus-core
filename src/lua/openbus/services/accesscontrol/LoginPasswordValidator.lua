-- $Id$

local oop = require "loop.base"

---
--Representa um validador de usuário e senha.
---
module("openbus.services.accesscontrol.LoginPasswordValidator", oop.class)

function validate(self, name, password)
  return false
end
