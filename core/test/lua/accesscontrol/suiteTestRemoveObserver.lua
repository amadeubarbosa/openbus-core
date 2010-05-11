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

    testRemoveObserver =  function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential.identifier, credential.identifier)
      end
      credentialObserver = orb:newservant(credentialObserver, nil, "IDL:tecgraf/openbus/core/v1_05/access_control_service/ICredentialObserver:1.0")
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
