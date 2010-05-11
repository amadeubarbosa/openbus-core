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

