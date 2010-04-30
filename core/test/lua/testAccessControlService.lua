--
-- Testes unitários do Serviço de Controle de Acesso
-- $Id$
--
require "oil"
local orb = oil.orb

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

local Check = require "latt.Check"

-- Login do administrador
local login = {}
login.user = "tester"
login.password = "tester"

local systemId     = "TesteBarramento"
local deploymentId = systemId
local testKeyFile  = systemId .. ".key"
local acsCertFile  = "AccessControlService.crt"

function loadidls()
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  oil.verbose:level(0)
  local idlfile = IDLPATH_DIR.."/v1_05/access_control_service.idl"
  orb:loadidlfile(idlfile)
  idlfile = IDLPATH_DIR.."/v1_04/access_control_service.idl"
  orb:loadidlfile(idlfile)
end

Suite = {
  --
  -- este teste não precisa inserir credencial no contexto das requisições
  --
  Test1 = {
    beforeTestCase = function(self)
      loadidls()
      local acsComp = orb:newproxy("corbaloc::localhost:2089/openbus_v1_05",
          "IDL:scs/core/IComponent:1.0")
      local facet = acsComp:getFacet("IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
      self.accessControlService = orb:narrow(facet, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
    end,

    testLoginByPassword = function(self)
      local success, credential = self.accessControlService:loginByPassword(login.user, login.password)
      Check.assertTrue(success)

      local success, credential2 = self.accessControlService:loginByPassword(login.user, login.password)
      Check.assertTrue(success)
      Check.assertNotEquals(credential.identifier, credential2.identifier)

      self.credentialManager:setValue(credential)
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialManager:setValue(credential2)
      Check.assertTrue(self.accessControlService:logout(credential2))
      self.credentialManager:invalidate()
    end,

    testLoginByPassword2 = function(self)
      local success, credential = self.accessControlService:loginByPassword("INVALID", "INVALID")
      Check.assertFalse(success)
      Check.assertEquals("", credential.identifier)
    end,

    testLogout = function(self)
      local _, credential =
          self.accessControlService:loginByPassword(login.user, login.password)
      self.credentialManager:setValue(credential)
      Check.assertFalse(self.accessControlService:logout({identifier = "", owner = "abcd", delegate = "", }))
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialManager:invalidate(credential)
      Check.assertError(self.accessControlService.logout,self.accessControlService,credential)
    end,
  },

  Test2 = {
    beforeTestCase = function(self)
      loadidls()
      local acsComp = orb:newproxy("corbaloc::localhost:2089/openbus_v1_05",
          "IDL:scs/core/IComponent:1.0")
      local facet = acsComp:getFacet("IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
      self.accessControlService = orb:narrow(facet, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
    end,

    beforeEachTest = function(self)
      _, self.credential =
          self.accessControlService:loginByPassword(login.user, login.password)
      self.credentialManager:setValue(self.credential)
    end,

    afterEachTest = function(self)
      if (self.credentialManager:hasValue()) then
        self.accessControlService:logout(self.credential)
        self.credentialManager:invalidate()
      end
    end,

    testIsValid = function(self)
      Check.assertTrue(self.accessControlService:isValid(self.credential))
      Check.assertFalse(self.accessControlService:isValid({identifier = "123", owner = login.user, delegate = "",}))
      self.accessControlService:logout(self.credential)

      -- neste caso o proprio interceptador do serviço rejeita o request
      Check.assertError(self.accessControlService.isValid,self.accessControlService,self.credential)
      self.credentialManager:invalidate()
    end,

    testAreValid = function(self)
      local credentials = {self.credential, {identifier = "INVALID_IDENTIFIER", owner = login.user, delegate = "",},}
      local results = self.accessControlService:areValid(credentials)
      Check.assertTrue(results[1])
      Check.assertFalse(results[2])
      credentials = {{identifier = "INVALID_IDENTIFIER", owner = login.user, delegate = "",}, self.credential}
      results = self.accessControlService:areValid(credentials)
      Check.assertFalse(results[1])
      Check.assertTrue(results[2])

      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

    testObservers = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential, credential)
      end
      credentialObserver = orb:newservant(credentialObserver, nil, "IDL:tecgraf/openbus/core/v1_05/access_control_service/ICredentialObserver:1.0")
      local observerIdentifier = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      Check.assertNotEquals("", observerIdentifier)
      Check.assertTrue(self.accessControlService:removeObserver(observerIdentifier))
      Check.assertFalse(self.accessControlService:removeObserver(observerIdentifier))
    end,

    testObserversLogout = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential.identifier, credential.identifier)
      end
      credentialObserver = orb:newservant(credentialObserver, nil, "IDL:tecgraf/openbus/core/v1_05/access_control_service/ICredentialObserver:1.0")
      local observersId = {}
      for i=1,3 do
        observersId[i] = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      end
      local oldCredential = self.credential
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      _, self.credential =
          self.accessControlService:loginByPassword(login.user, login.password)
      self.credentialManager:setValue(self.credential)
      for i=1,3 do
 Check.assertFalse(self.accessControlService:removeCredentialFromObserver(observersId[i], oldCredential.identifier))
      end
    end,

    testObserversLogout2 = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential.identifier, credential.identifier)
      end
      credentialObserver = orb:newservant(credentialObserver, nil, "IDL:tecgraf/openbus/core/v1_05/access_control_service/ICredentialObserver:1.0")
      local observerId = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      _, self.credential = self.accessControlService:loginByPassword(login.user, login.password)
      self.credentialManager:setValue(self.credential)
      Check.assertFalse(self.accessControlService:removeObserver(observerId))
    end,
  },

  Test3 = {
    beforeTestCase = function(self)
      loadidls()
      local acsComp = orb:newproxy("corbaloc::localhost:2089/openbus_v1_05",
          "IDL:scs/core/IComponent:1.0")
      local facet = acsComp:getFacet("IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
      self.accessControlService = orb:narrow(facet, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
    end,

    testGetChallenge_Invalid = function(self)
      local challenge = self.accessControlService:getChallenge("InvalidNameForChallenge")
      Check.assertTrue(not challenge or #challenge == 0)
      challenge = self.accessControlService:getChallenge("")
      Check.assertTrue(not challenge or #challenge == 0)
    end,

    --
    -- Este teste requer que a implantação 'TesteBarramento' esteja cadastrada
    --
    testLoginByCertificate = function(self)
      local challenge =
          self.accessControlService:getChallenge(deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local privateKey = lce.key.readprivatefrompemfile(testKeyFile)
      Check.assertNotNil(privateKey)
      challenge = lce.cipher.decrypt(privateKey, challenge)
      Check.assertNotNil(challenge)
      local certificate = lce.x509.readfromderfile(acsCertFile)
      Check.assertNotNil(certificate)
      local answer = lce.cipher.encrypt(certificate:getpublickey(), challenge)
      Check.assertNotNil(answer)
      local succ, credential, lease = self.accessControlService:loginByCertificate(deploymentId, answer)
      Check.assertTrue(succ)
      self.credentialManager:setValue(credential)
      Check.assertTrue(self.accessControlService:logout(credential))
    end,

    --
    -- Este teste requer que a implantação 'TesteBarramento' esteja cadastrada
    --
    testLoginByCertificate_WrongAnswer = function(self)
      local challenge =
          self.accessControlService:getChallenge(deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local privateKey = lce.key.readprivatefrompemfile(testKeyFile)
      Check.assertNotNil(privateKey)
      challenge = lce.cipher.decrypt(privateKey, challenge)
      Check.assertNotNil(challenge)
      local certificate = lce.x509.readfromderfile(acsCertFile)
      Check.assertNotNil(certificate)
      local answer = lce.cipher.encrypt(certificate:getpublickey(), challenge.."->Wrong")
      Check.assertNotNil(answer)
      local succ =
          self.accessControlService:loginByCertificate(deploymentId,
          answer)
      Check.assertFalse(succ)
    end,

    --
    -- Este teste requer que a implantação 'TesteBarramento' esteja cadastrada
    --
    testLoginByCertificate_NoEncryption = function(self)
      local challenge = self.accessControlService:getChallenge(deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local succ =
          self.accessControlService:loginByCertificate(deploymentId,
          "InvalidAnswer")
      Check.assertFalse(succ)
    end,

    --
    -- Este teste requer que a implantação 'TesteBarramento' esteja cadastrada
    --
    testLogout = function(self)
      local challenge = self.accessControlService:getChallenge(deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local privateKey = lce.key.readprivatefrompemfile(testKeyFile)
      Check.assertNotNil(privateKey)
      challenge = lce.cipher.decrypt(privateKey, challenge)
      Check.assertNotNil(challenge)
      local certificate = lce.x509.readfromderfile(acsCertFile)
      Check.assertNotNil(certificate)
      local answer = lce.cipher.encrypt(certificate:getpublickey(), challenge)
      Check.assertNotNil(answer)
      local succ, credential, lease =
          self.accessControlService:loginByCertificate(deploymentId,
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
