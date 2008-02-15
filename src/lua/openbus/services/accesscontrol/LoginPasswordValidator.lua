-- $Id$

local oop = require "loop.base"

---
--Representa um validador de usuário e senha.
---
module("openbus.services.accesscontrol.LoginPasswordValidator", oop.class)

---
--Verifica se um determinado login pode acessar o sistema.
--
--@param name O login do usuário.
--@param password A senha do usuário.
--
--@return true caso o login seja válido, ou false e uma mensagem de erro, caso
--contrário.
---
function validate(self, name, password)
  return false
end
