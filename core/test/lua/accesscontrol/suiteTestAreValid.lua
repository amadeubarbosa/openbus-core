--
-- Testes unit�rios para teste de carga -- Servi�o de Controle de Acesso
--

require "oil"
local orb = oil.orb
local Check = require "latt.Check"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")

local beforeTestCase = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/beforeTestCase.lua")
local afterTestCase = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterTestCase.lua")
local beforeEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterEachTest.lua")


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
