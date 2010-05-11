--
-- Testes unitários para teste de carga -- Serviço de Controle de Acesso
--

require "oil"
local orb = oil.orb
local Check = require "latt.Check"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")

function loadidls(self)
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  local idlfile = IDLPATH_DIR.."/v1_05/access_control_service.idl"
  orb:loadidlfile(idlfile)
  idlfile = IDLPATH_DIR.."/v1_04/access_control_service.idl"
  orb:loadidlfile(idlfile)
end

local beforeTestCase = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/beforeTestCase.lua")
local afterTestCase = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterTestCase.lua")
local beforeEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterEachTest.lua")


Suite = {

  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    testLoginByCertificate = function(self)
      local challenge =
      self.accessControlService:getChallenge(self.deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local privateKey = lce.key.readprivatefrompemfile(self.testKeyFile)
      Check.assertNotNil(privateKey)
      local succ, err
      succ, challenge, err = oil.pcall(lce.cipher.decrypt, privateKey, challenge)
      Check.assertNotNil(challenge)
      local certificate = lce.x509.readfromderfile(self.acsCertFile)
      Check.assertNotNil(certificate)
      local answer = lce.cipher.encrypt(certificate:getpublickey(), challenge)
      Check.assertNotNil(answer)
      local succ, credential, lease = self.accessControlService:loginByCertificate(self.deploymentId, answer)
      Check.assertTrue(succ)
      self.credentialManager:setValue(credential)
      self.accessControlService:logout(credential)
      self.credentialManager:invalidate()
    end,

  },

}

return Suite
