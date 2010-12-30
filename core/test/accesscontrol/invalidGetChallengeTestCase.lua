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

    testInvalidGetChallenge = function(self)
      local challenge = self.accessControlService:getChallenge("InvalidNameForChallenge")
      Check.assertTrue(not challenge or #challenge == 0)
      challenge = self.accessControlService:getChallenge("")
      Check.assertTrue(not challenge or #challenge == 0)
    end,

  },

}

return Suite
