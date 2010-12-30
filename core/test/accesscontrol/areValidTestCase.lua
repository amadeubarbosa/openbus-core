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

    testAreValid = function(self)
      local credentials = {self.credential, {identifier = "INVALID_IDENTIFIER", owner = self.login.user, delegate = "",},}
      local results = self.accessControlService:areValid(credentials)
      Check.assertTrue(results[1])
      Check.assertFalse(results[2])
      credentials = {{identifier = "INVALID_IDENTIFIER", owner = self.login.user, delegate = "",}, self.credential}
      results = self.accessControlService:areValid(credentials)
      Check.assertFalse(results[1])
      Check.assertTrue(results[2])

      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

  },

}

return Suite

