--
-- Testes unitários para teste de carga -- Serviço de Controle de Acesso
--

require "oil"
local orb = oil.orb
local Check = require "latt.Check"
local Utils = require "openbus.util.Utils"

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

    testRemoveObserver =  function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential.identifier, credential.identifier)
      end
      credentialObserver = orb:newservant(credentialObserver, nil,
          Utils.CREDENTIAL_OBSERVER_INTERFACE)
      local observerId = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      _, self.credential = self.accessControlService:loginByPassword(self.login.user, self.login.password)
      self.credentialManager:setValue(self.credential)
      Check.assertFalse(self.accessControlService:removeObserver(observerId))
    end,

  },

}

return Suite
