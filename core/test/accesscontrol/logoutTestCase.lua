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

Suite = {

  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    beforeEachTest = beforeEachTest,

    testLogout =  function(self)
      local _, credential =
          self.accessControlService:loginByPassword(self.login.user, self.login.password)
      self.credentialManager:setValue(credential)
      Check.assertFalse(self.accessControlService:logout({identifier = "", owner = "abcd", delegate = "", }))
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialManager:invalidate(credential)
      Check.assertError(self.accessControlService.logout,self.accessControlService,credential)
    end,

  },

}

return Suite
