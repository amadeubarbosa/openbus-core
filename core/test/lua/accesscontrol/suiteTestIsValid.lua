--
-- Testes unitários para teste de carga -- Serviço de Controle de Acesso
--

require "oil"
local orb = oil.orb
local Check = require "latt.Check"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")

local beforeTestCaseWithoutManagement = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/beforeTestCaseWithoutManagement.lua")
local afterTestCase = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterTestCase.lua")
local beforeEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterEachTest.lua")

oil.verbose:level(2)

Suite = {

  Test1 = {
    beforeTestCase = beforeTestCaseWithoutManagement,

    beforeEachTest = beforeEachTest,

    testIsValid =  function(self)

      Check.assertTrue(self.accessControlService:isValid(self.credential))
      Check.assertFalse(self.accessControlService:isValid({identifier = "123", owner = self.login.user, delegate = "",}))
      self.accessControlService:logout(self.credential)

      -- neste caso o proprio interceptador do serviço rejeita o request
      Check.assertFalse(self.accessControlService:isValid(self.credential))
      self.credentialManager:invalidate()
    end,

  },

}

return Suite

