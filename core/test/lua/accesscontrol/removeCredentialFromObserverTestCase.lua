--
-- Testes unit�rios para teste de carga -- Servi�o de Controle de Acesso
--

require "oil"
local orb = oil.orb
local Check = require "latt.Check"
local Utils = require "openbus.util.Utils"

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

    testRemoveCredentialFromObserver = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential.identifier, credential.identifier)
      end
      credentialObserver = orb:newservant(credentialObserver, nil,
          Utils.CREDENTIAL_OBSERVER_INTERFACE)
      local observersId = {}
      for i=1,3 do
        observersId[i] = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      end
      local oldCredential = self.credential
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      _, self.credential =
          self.accessControlService:loginByPassword(self.login.user, self.login.password)
      self.credentialManager:setValue(self.credential)
      for i=1,3 do
Check.assertFalse(self.accessControlService:removeCredentialFromObserver(observersId[i], oldCredential.identifier))
      end
    end,

  },

}

return Suite