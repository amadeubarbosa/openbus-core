-- $Id$

local oop = require "loop.base"

---
--Representa um validador de usu�rio e senha.
---
module("openbus.services.accesscontrol.LoginPasswordValidator", oop.class)

function validate(self, name, password)
  return false
end
