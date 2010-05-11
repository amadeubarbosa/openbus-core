--
-- Testes unitários para teste de carga -- Serviço de Controle de Acesso
--
local Check = require "latt.Check"
require "oil"
local orb = oil.orb

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
local beforeEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterEachTest.lua")


Suite = {

  Test1 = {
    beforeTestCase = beforeTestCase,

    beforeEachTest = beforeEachTest,

    afterEachTest = afterEachTest,

    testLoginByPassword = function(self)
      local success, credential = self.accessControlService:loginByPassword(self.login.user, self.login.password)
      Check.assertTrue(success)

      local success, credential2 = self.accessControlService:loginByPassword(self.login.user, self.login.password)
      Check.assertTrue(success)
      Check.assertNotEquals(credential.identifier, credential2.identifier)

      self.credentialManager:setValue(credential)
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialManager:setValue(credential2)
      Check.assertTrue(self.accessControlService:logout(credential2))
      self.credentialManager:invalidate()
    end,

  },

}

return Suite
