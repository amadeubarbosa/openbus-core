local oop = require "loop.base"
module("openbus.services.accesscontrol.LoginPasswordValidator", oop.class)

function validate(self, name, password)
  return false
end
