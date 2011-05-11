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
local getEntryCredentialTestCase = assert(loadfile("accesscontrol/getEntryCredentialTestCase.lua"))()
local getAllEntryCredentialTestCase = assert(loadfile("accesscontrol/getAllEntryCredentialTestCase.lua"))()

Suite = {

  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    testLoginByPassword = loginByPasswordTestCase.Test1.testLoginByPassword,

    testInvalidLoginByPassword = invalidLoginByPasswordTestCase.Test1.testInvalidLoginByPassword,

    testLogout = logoutTestCase.Test1.testLogout,
    
    testLoginByCertificate = loginByCertificateTestCase.Test1.testLoginByCertificate,

    testLogoutAfterLoginByCertificate = logoutAfterLoginByCertificateTestCase.Test1.testLogoutAfterLoginByCertificate,

    testLoginByCertificate_WrongAnswer = loginByCertificate_WrongAnswerTestCase.Test1.testLoginByCertificate_WrongAnswer,

    testLoginByCertificate_NoEncryption = loginByCertificate_NoEncryptionTestCase.Test1.testLoginByCertificate_NoEncryption,
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

    testObservers = observersTestCase.Test1.testObservers,

    testRemoveCredentialFromObserver = removeCredentialFromObserverTestCase.Test1.testRemoveCredentialFromObserver,

    testRemoveObserver = removeObserverTestCase.Test1.testRemoveObserver,

    testGetEntryCredentialNoPermission = getEntryCredentialTestCase.Test2.testGetEntryCredentialNoPermission,

    testGetAllEntryCredentialNoPermission = getEntryCredentialTestCase.Test2.testGetEntryCredentialNoPermission,

  },

  Test3 = {
    beforeTestCase = beforeTestCase,

    beforeEachTest = function(self)
          -- loga com uma conta de administração
          _, self.admCredential =
              self.accessControlService:loginByPassword("tester", "tester")
          self.credentialManager:setValue(self.admCredential)
        end,

    afterTestCase = afterTestCase,

    afterEachTest = function(self)
          -- desloga o administrador
          if (self.credentialManager:hasValue()) then
            self.accessControlService:logout(self.admCredential)
            self.credentialManager:invalidate()
          end
        end,

    testGetEntryCredential = getEntryCredentialTestCase.Test1.testGetEntryCredential,

    testGetEntryCredentialOfOtherUser = getEntryCredentialTestCase.Test1.testGetEntryCredentialOfOtherUser,

    testGetEntryCredentialInvalidCredential = getEntryCredentialTestCase.Test1.testGetEntryCredentialInvalidCredential,

    testGetAllEntryCredential = getAllEntryCredentialTestCase.Test1.testGetAllEntryCredential,

    testGetAllEntryCredentialLogginOtherUser = getAllEntryCredentialTestCase.Test1.testGetAllEntryCredentialLogginOtherUser,

  }
}
