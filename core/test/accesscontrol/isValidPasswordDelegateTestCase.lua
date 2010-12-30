--
-- Testes unitários para teste de carga -- Serviço de Controle de Acesso
--

require "oil"
local orb = oil.orb
local Check = require "latt.Check"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")

local beforeTestCase = dofile("accesscontrol/beforeTestCase.lua")
local afterTestCase = dofile("accesscontrol/afterTestCase.lua")
local beforeEachTest = dofile("accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile("accesscontrol/afterEachTest.lua")


Suite = {
  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    beforeEachTest = beforeEachTest,

    afterEachTest = afterEachTest,

    testIsValid =  function(self)
      Check.assertTrue(self.accessControlService:isValid(self.credential))
      local delegatedCredential = {
        identifier = self.credential.identifier,
        owner = self.credential.identifier,
        delegate = "DELEGATE",
      }
      Check.assertFalse(self.accessControlService:isValid(delegatedCredential))
    end,
  },
}

return Suite

