--
-- Testes unitários para teste de carga -- Serviço de Controle de Acesso
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

    testInvalidGetChallenge = function(self)
      local challenge = self.accessControlService:getChallenge("InvalidNameForChallenge")
      Check.assertTrue(not challenge or #challenge == 0)
      challenge = self.accessControlService:getChallenge("")
      Check.assertTrue(not challenge or #challenge == 0)
    end,

  },

}

return Suite
