--
-- Suite de Testes do Serviço de Controle de Acesso
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
  local idlfile = IDLPATH_DIR.."/"..Utils.OB_VERSION.."/access_control_service.idl"
  orb:loadidlfile(idlfile)
  idlfile = IDLPATH_DIR.."/"..Utils.OB_PREV.."/access_control_service.idl"
  orb:loadidlfile(idlfile)
end

local beforeTestCase = dofile("accesscontrol/beforeTestCase.lua")
local beforeEachTest = dofile("accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile("accesscontrol/afterEachTest.lua")
local afterEachTest = dofile("accesscontrol/afterEachTest.lua")

local loginByPasswordTestCase = assert(loadfile("accesscontrol/loginByPasswordTestCase.lua"))()
local invalidLoginByPasswordTestCase = assert(loadfile("accesscontrol/invalidLoginByPasswordTestCase.lua"))()
local logoutTestCase = assert(loadfile("accesscontrol/logoutTestCase.lua"))()
local isValidTestCase = assert(loadfile("accesscontrol/isValidTestCase.lua"))()
local areValidTestCase = assert(loadfile("accesscontrol/areValidTestCase.lua"))()
local isValidPasswordDelegateTestCase = assert(loadfile("accesscontrol/isValidPasswordDelegateTestCase.lua"))()
local observersTestCase = assert(loadfile("accesscontrol/observersTestCase.lua"))()
local removeCredentialFromObserverTestCase = assert(loadfile("accesscontrol/removeCredentialFromObserverTestCase.lua"))()
local removeObserverTestCase = assert(loadfile("accesscontrol/removeObserverTestCase.lua"))()
local invalidGetChallengeTestCase = assert(loadfile("accesscontrol/invalidGetChallengeTestCase.lua"))()
local loginByCertificateTestCase = assert(loadfile("accesscontrol/loginByCertificateTestCase.lua"))()
local loginByCertificate_WrongAnswerTestCase = assert(loadfile("accesscontrol/loginByCertificate_WrongAnswerTestCase.lua"))()
local loginByCertificate_NoEncryptionTestCase = assert(loadfile("accesscontrol/loginByCertificate_NoEncryptionTestCase.lua"))()
local logoutAfterLoginByCertificateTestCase = assert(loadfile("accesscontrol/logoutAfterLoginByCertificateTestCase.lua"))()

Suite = {

  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    testLoginByPassword = loginByPasswordTestCase.Test1.testLoginByPassword,

    testInvalidLoginByPassword = invalidLoginByPasswordTestCase.Test1.testInvalidLoginByPassword,

    testLogout = logoutTestCase.Test1.testLogout,
  },

  Test2 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    beforeEachTest = beforeEachTest,

    afterEachTest = afterEachTest,

    testIsValid = isValidTestCase.Test1.testIsValid,

    testIsValidPasswordDelegate = isValidPasswordDelegateTestCase.Test1.testIsValidPasswordDelegate,

    testAreValid = areValidTestCase.Test1.testAreValid,

    testInvalidGetChallenge = invalidGetChallengeTestCase.Test1.testInvalidGetChallenge,

  },

  Test3 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    beforeEachTest = beforeEachTest,

    afterEachTest = afterEachTest,

    testObservers = observersTestCase.Test1.testObservers,

    testRemoveCredentialFromObserver = removeCredentialFromObserverTestCase.Test1.testRemoveCredentialFromObserver,

    testRemoveObserver = removeObserverTestCase.Test1.testRemoveObserver,
  },

  Test4 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    testLoginByCertificate = loginByCertificateTestCase.Test1.testLoginByCertificate,

    testLogoutAfterLoginByCertificate = logoutAfterLoginByCertificateTestCase.Test1.testLogoutAfterLoginByCertificate,

    testLoginByCertificate_WrongAnswer = loginByCertificate_WrongAnswerTestCase.Test1.testLoginByCertificate_WrongAnswer,

    testLoginByCertificate_NoEncryption = loginByCertificate_NoEncryptionTestCase.Test1.testLoginByCertificate_NoEncryption,
  },

}
