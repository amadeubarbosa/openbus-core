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

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:OpenBus/ACS/AccessControlServiceComponent:1.0")
      self.accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/ACS/AccessControlService:1.0")
      self.accessControlService = oil.narrow(self.accessControlService, "IDL:OpenBus/ACS/AccessControlService:1.0")
      self.credential = self.accessControlService:loginByPassword(user, password)
      local registryService = self.accessControlService:getRegistryService(self.credential)

      local serviceOffers = registryService:find("OpenBus/SS/SessionService", {})
      Check.assertNotEquals(#serviceOffers, 0)
      local sessionServiceComponent = oil.narrow(serviceOffers[1].member, "IDL:OpenBus/SS/SessionServiceComponent:1.0")
      self.sessionService = sessionServiceComponent:getFacet("IDL:OpenBus/SS/SessionService:1.0")
      self.sessionService = oil.narrow(self.sessionService, "IDL:OpenBus/SS/SessionService:1.0")
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
