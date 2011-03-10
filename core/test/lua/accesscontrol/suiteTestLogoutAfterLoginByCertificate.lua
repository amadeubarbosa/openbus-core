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

    testLogoutAfterLoginByCertificate =  function(self)
      local challenge = self.accessControlService:getChallenge(self.deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local privateKey = lce.key.readprivatefrompemfile(self.testKeyFile)
      Check.assertNotNil(privateKey)
      challenge = lce.cipher.decrypt(privateKey, challenge)
      Check.assertNotNil(challenge)
      local certificate = lce.x509.readfromderfile(self.acsCertFile)
      Check.assertNotNil(certificate)
      local answer = lce.cipher.encrypt(certificate:getpublickey(), challenge)
      Check.assertNotNil(answer)
      local succ, credential, lease =
          self.accessControlService:loginByCertificate(self.deploymentId,
          answer)
      Check.assertTrue(succ)
      self.credentialManager:setValue(credential)
      Check.assertFalse(self.accessControlService:logout({
        identifier = "InvalidIdentifier",
        owner = "InvalidName",
        delegate = "",
      }))
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialManager:invalidate(credential)
      Check.assertError(self.accessControlService.logout, self.accessControlService, credential)
    end,

  },

}

return Suite
