--
-- Testes unitários do Serviço de Controle de Acesso
-- $Id: testAccessControlService.lua 104952 2010-04-30 21:43:16Z augusto $
--
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
local afterEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterEachTest.lua")

local suiteTestLoginByPassword = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestLoginByPassword.lua"))()
local suiteTestInvalidLoginByPassword = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestInvalidLoginByPassword.lua"))()
local suiteTestLogout = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestLogout.lua"))()
local suiteTestIsValid = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestIsValid.lua"))()
local suiteTestAreValid = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestAreValid.lua"))()
local suiteTestObservers = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestObservers.lua"))()
local suiteTestRemoveCredentialFromObserver = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestRemoveCredentialFromObserver.lua"))()
local suiteTestRemoveObserver = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestRemoveObserver.lua"))()
local suiteTestInvalidGetChallenge = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestInvalidGetChallenge.lua"))()
local suiteTestLoginByCertificate = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestLoginByCertificate.lua"))()
local suiteTestLoginByCertificate_WrongAnswer = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestLoginByCertificate_WrongAnswer.lua"))()
local suiteTestLoginByCertificate_NoEncryption = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestLoginByCertificate_NoEncryption.lua"))()
local suiteTestLogoutAfterLoginByCertificate = assert(loadfile(OPENBUS_HOME .."/core/test/lua/accesscontrol/suiteTestLogoutAfterLoginByCertificate.lua"))()

Suite = {
  --
  -- este teste não precisa inserir credencial no contexto das requisições
  --

  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    testLoginByPassword = suiteTestLoginByPassword.Test1.testLoginByPassword,

    testInvalidLoginByPassword = suiteTestInvalidLoginByPassword.Test1.testInvalidLoginByPassword,

    testLogout = suiteTestLogout.Test1.testLogout,
  },

  Test2 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    beforeEachTest = beforeEachTest,

    afterEachTest = afterEachTest,

    testIsValid = suiteTestIsValid.Test1.testIsValid,

    testAreValid = suiteTestAreValid.Test1.testAreValid,

    testInvalidGetChallenge = suiteTestInvalidGetChallenge.Test1.testInvalidGetChallenge,

    testObservers = suiteTestObservers.Test1.testObservers,

    testRemoveCredentialFromObserver = suiteTestRemoveCredentialFromObserver.Test1.testRemoveCredentialFromObserver,

    testRemoveObserver = suiteTestRemoveObserver.Test1.testRemoveObserver,
  },

  Test3 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    testLoginByCertificate = suiteTestLoginByCertificate.Test1.testLoginByCertificate,

    testLogoutAfterLoginByCertificate = suiteTestLogoutAfterLoginByCertificate.Test1.testLogoutAfterLoginByCertificate,

    testLoginByCertificate_WrongAnswer = suiteTestLoginByCertificate_WrongAnswer.Test1.testLoginByCertificate_WrongAnswer,

    testLoginByCertificate_NoEncryption = suiteTestLoginByCertificate_NoEncryption.Test1.testLoginByCertificate_NoEncryption,
  },

}
