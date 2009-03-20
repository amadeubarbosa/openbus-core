--
-- Testes unitários do Serviço de Controle de Acesso
-- $Id$
--
require "oil"
local orb = oil.orb

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"

local Check = require "latt.Check"

Suite = {
  --
  -- este teste não precisa inserir credencial no contexto das requisições
  -- 
  Test1 = {
    beforeTestCase = function(self)
      local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
      if IDLPATH_DIR == nil then
        io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
        os.exit(1)
      end
      local idlfile = IDLPATH_DIR.."/access_control_service.idl"

      oil.verbose:level(5)
      orb:loadidlfile(idlfile)

      self.user = "tester"
      self.password = "tester"

      self.accessControlService = orb:newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
    end,

    testLoginByPassword = function(self)
      local success, credential = self.accessControlService:loginByPassword(self.user, self.password)
      Check.assertTrue(success)

      local success, credential2 = self.accessControlService:loginByPassword(self.user, self.password)
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
      local _, credential = self.accessControlService:loginByPassword(self.user, self.password)
      self.credentialManager:setValue(credential)
      Check.assertFalse(self.accessControlService:logout({identifier = "", owner = "abcd", delegate = "", }))
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialManager:invalidate(credential)
      Check.assertError(self.accessControlService.logout,self.accessControlService,credential)
    end,
  },

  Test2 = {
    beforeTestCase = function(self)
      local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
      if IDLPATH_DIR == nil then
        io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
        os.exit(1)
      end
      local idlfile = IDLPATH_DIR.."/access_control_service.idl"

      oil.verbose:level(0)
      orb:loadidlfile(idlfile)

      self.user = "tester"
      self.password = "tester"

      self.accessControlService = orb:newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
    end,

    beforeEachTest = function(self)
      _, self.credential = self.accessControlService:loginByPassword(self.user, self.password)
      self.credentialManager:setValue(self.credential)
    end,

    afterEachTest = function(self)
      if (self.credentialManager:hasValue()) then
        self.accessControlService:logout(self.credential)
        self.credentialManager:invalidate()
      end
    end,

    testGetRegistryService = function(self)
      Check.assertNil(self.accessControlService:getRegistryService())
    end,

    testSetRegistryService = function(self)
      Check.assertFalse(self.accessControlService:setRegistryService(self.accessControlService))
    end,

    testIsValid = function(self)
      Check.assertTrue(self.accessControlService:isValid(self.credential))
      Check.assertFalse(self.accessControlService:isValid({identifier = "123", owner = self.user, delegate = "",}))
      self.accessControlService:logout(self.credential)

      -- neste caso o proprio interceptador do serviço rejeita o request
      Check.assertError(self.accessControlService.isValid,self.accessControlService,self.credential)
      self.credentialManager:invalidate()
    end,

    testObservers = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential, credential)
      end
      credentialObserver = orb:newservant(credentialObserver, nil, "IDL:openbusidl/acs/ICredentialObserver:1.0")
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
      credentialObserver = orb:newservant(credentialObserver, nil, "IDL:openbusidl/acs/ICredentialObserver:1.0")
      local observersId = {}
      for i=1,3 do
        observersId[i] = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      end
      local oldCredential = self.credential
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      _, self.credential = self.accessControlService:loginByPassword(self.user, self.password)
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
      credentialObserver = orb:newservant(credentialObserver, nil, "IDL:openbusidl/acs/ICredentialObserver:1.0")
      local observerId = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      _, self.credential = self.accessControlService:loginByPassword(self.user, self.password)
      self.credentialManager:setValue(self.credential)
      Check.assertFalse(self.accessControlService:removeObserver(observerId))
    end,
  },
}
