require "oil"

local Check = require "latt.Check"

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
      if CORBA_IDL_DIR == nil then
        io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end
      local idlfile = CORBA_IDL_DIR.."/session_service_oil.idl"

      oil.verbose.level(1)
      oil.loadidlfile(idlfile)

      local user = "csbase"
      local password = "csbLDAPtest"

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:OpenBus/ACS/IAccessControlServiceComponent:1.0")
      local accessControlServiceInterface = "IDL:OpenBus/ACS/IAccessControlService:1.0"
      self.accessControlService = accessControlServiceComponent:getFacet(accessControlServiceInterface)
      self.accessControlService = oil.narrow(self.accessControlService, accessControlServiceInterface)
      self.credential = self.accessControlService:loginByPassword(user, password)
      local registryService = self.accessControlService:getRegistryService(self.credential)
      local registryServiceInterface = "IDL:OpenBus/RS/IRegistryService:1.0"
      registryService = registryService:getFacet(registryServiceInterface)
      registryService = oil.narrow(registryService, registryServiceInterface)

      local serviceOffers = registryService:find("OpenBus/SS/ISessionService", {})
      Check.assertNotEquals(#serviceOffers, 0)
      local sessionServiceComponent = oil.narrow(serviceOffers[1].member, "IDL:OpenBus/SS/ISessionServiceComponent:1.0")
      local sessionServiceInterface = "IDL:OpenBus/SS/ISessionService:1.0"
      self.sessionService = sessionServiceComponent:getFacet(sessionServiceInterface)
      self.sessionService = oil.narrow(self.sessionService, sessionServiceInterface)
    end,

    testCreateSession = function(self)
      local session = self.sessionService:createSession(self.credential)
      Check.assertNotEquals("", session.identifier)
      self.sessionService:removeSession(self.credential)
    end,

    testGetSession = function(self)
      local session = self.sessionService:createSession(self.credential)
      local session2 = self.sessionService:getSession(self.credential)
      Check.assertNotEquals("", session2.identifier)
      Check.assertEquals(session.identifier, session2.identifier)
      self.sessionService:removeSession(self.credential)
    end,

    testRemoveSession = function(self)
      self.sessionService:createSession(self.credential)
      Check.assertTrue(self.sessionService:removeSession(self.credential))
      local session = self.sessionService:getSession(self.credential)
      Check.assertEquals("", session.identifier)
      Check.assertFalse(self.sessionService:removeSession(self.credential))
    end,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
    end,
  }
}
