require "oil"

require "Check"

Suite = {
  name = "AccessControlService",

  Test1 = {
    beforeTestCase = function(self)
      local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
      if CORBA_IDL_DIR == nil then
        io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end
      local idlfile = CORBA_IDL_DIR.."/access_control_service_oil.idl"

      oil.verbose.level(1)
      oil.loadidlfile(idlfile)

      self.user = "csbase"
      self.password = "csbLDAPtest"

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:OpenBus/AS/AccessControlServiceComponent:1.0")
      self.accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/AS/AccessControlService:1.0")
      self.accessControlService = oil.narrow(self.accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")
    end,

    testLoginByPassword = function(self)
      local credentialLoginIdentifier = self.accessControlService:loginByPassword(self.user, self.password)
      local credentialLoginIdentifier2 = self.accessControlService:loginByPassword(self.user, self.password)
      Check.assertNotEquals(credentialLoginIdentifier.credential.identifier, credentialLoginIdentifier2.credential.identifier)
      Check.assertNotEquals(credentialLoginIdentifier.loginIdentifier, credentialLoginIdentifier2.loginIdentifier)
      Check.assertTrue(self.accessControlService:logout(credentialLoginIdentifier.loginIdentifier))
      Check.assertFalse(self.accessControlService:logout(credentialLoginIdentifier2.loginIdentifier))
    end,

    testLogout = function(self)
      local credentialLoginIdentifier = self.accessControlService:loginByPassword(self.user, self.password)
      Check.assertFalse(self.accessControlService:logout("abcd"))
      Check.assertTrue(self.accessControlService:logout(credentialLoginIdentifier.loginIdentifier))
      Check.assertFalse(self.accessControlService:logout(credentialLoginIdentifier.loginIdentifier))
    end,
  },

  Test2 = {
    beforeTestCase = function(self)
      local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
      if CORBA_IDL_DIR == nil then
        io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end
      local idlfile = CORBA_IDL_DIR.."/access_control_service_oil.idl"

      oil.verbose.level(1)
      oil.loadidlfile(idlfile)

      self.user = "csbase"
      self.password = "csbLDAPtest"

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:OpenBus/AS/AccessControlServiceComponent:1.0")
      self.accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/AS/AccessControlService:1.0")
      self.accessControlService = oil.narrow(self.accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")
    end,

    beforeEachTest = function(self)
      self.credentialLoginIdentifier = self.accessControlService:loginByPassword(self.user, self.password)
    end,

    afterEachTest = function(self)
      self.accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)
    end,

    testGetRegistryService = function(self)
      Check.assertNil(self.accessControlService:getRegistryService(self.credentialLoginIdentifier.credential))
    end,

    testIsValid = function(self)
      Check.assertTrue(self.accessControlService:isValid(self.credentialLoginIdentifier.credential))
      Check.assertFalse(self.accessControlService:isValid({memberName=user, identifier = "123"}))
      self.accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)
      Check.assertFalse(self.accessControlService:isValid(self.credentialLoginIdentifier.credential))
    end,

    testObservers = function(self)
      local credentialObserver = { credential = self.credentialLoginIdentifier.credential}
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential, credential)
      end
      credentialObserver = oil.newobject(credentialObserver, "IDL:OpenBus/AS/CredentialObserver:1.0")
      local observerIdentifier = self.accessControlService:addObserver(credentialObserver, {self.credentialLoginIdentifier.credential.identifier,})
      Check.assertNotEquals("", observerIdentifier)
      self.accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)
      Check.assertTrue(self.accessControlService:removeObserver(observerIdentifier))
      Check.assertFalse(self.accessControlService:removeObserver(observerIdentifier))
    end,
  },
}
