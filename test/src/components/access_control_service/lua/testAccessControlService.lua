require "oil"

require "Check"

Suite = {
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

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:OpenBus/ACS/AccessControlServiceComponent:1.0")
      self.accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/ACS/AccessControlService:1.0")
      self.accessControlService = oil.narrow(self.accessControlService, "IDL:OpenBus/ACS/AccessControlService:1.0")
    end,

    testLoginByPassword = function(self)
      local credential = self.accessControlService:loginByPassword(self.user, self.password)
      local credential2 = self.accessControlService:loginByPassword(self.user, self.password)
      Check.assertNotEquals(credential.identifier, credential2.identifier)
      Check.assertTrue(self.accessControlService:logout(credential))
      Check.assertFalse(self.accessControlService:logout(credential2))
    end,

    testLogout = function(self)
      local credential = self.accessControlService:loginByPassword(self.user, self.password)
      Check.assertFalse(self.accessControlService:logout({identifier = "", entityName = "abcd", }))
      Check.assertTrue(self.accessControlService:logout(credential))
      Check.assertFalse(self.accessControlService:logout(credential))
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

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:OpenBus/ACS/AccessControlServiceComponent:1.0")
      self.accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/ACS/AccessControlService:1.0")
      self.accessControlService = oil.narrow(self.accessControlService, "IDL:OpenBus/ACS/AccessControlService:1.0")
    end,

    beforeEachTest = function(self)
      self.credential = self.accessControlService:loginByPassword(self.user, self.password)
    end,

    afterEachTest = function(self)
      self.accessControlService:logout(self.credential)
    end,

    testGetRegistryService = function(self)
      Check.assertNil(self.accessControlService:getRegistryService(self.credential))
    end,

    testIsValid = function(self)
      Check.assertTrue(self.accessControlService:isValid(self.credential))
      Check.assertFalse(self.accessControlService:isValid({entityName=self.user, identifier = "123"}))
      self.accessControlService:logout(self.credential)
      Check.assertFalse(self.accessControlService:isValid(self.credential))
    end,

    testObservers = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential, credential)
      end
      credentialObserver = oil.newobject(credentialObserver, "IDL:OpenBus/ACS/CredentialObserver:1.0")
      local observerIdentifier = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      Check.assertNotEquals("", observerIdentifier)
      self.accessControlService:logout(self.credential)
      Check.assertTrue(self.accessControlService:removeObserver(observerIdentifier))
      Check.assertFalse(self.accessControlService:removeObserver(observerIdentifier))
    end,
  },
}
