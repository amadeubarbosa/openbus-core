require "oil"

require "Member"

local Check = require "latt.Check"

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
      if CORBA_IDL_DIR == nil then
        io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end
      local idlfile = CORBA_IDL_DIR.."/registry_service.idl"

      oil.verbose:level(0)
      oil.loadidlfile(idlfile)

      local user = "csbase"
      local password = "csbLDAPtest"

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:OpenBus/ACS/IAccessControlServiceComponent:1.0")
      local accessControlServiceInterface = "IDL:OpenBus/ACS/IAccessControlService:1.0"
      self.accessControlService = accessControlServiceComponent:getFacet(accessControlServiceInterface)
      self.accessControlService = oil.narrow(self.accessControlService, accessControlServiceInterface)
      local success
      success, self.credential = self.accessControlService:loginByPassword(user, password)

      self.registryService = self.accessControlService:getRegistryService(self.credential)
      local registryServiceInterface = "IDL:OpenBus/RS/IRegistryService:1.0"
      self.registryService = self.registryService:getFacet(registryServiceInterface)
      self.registryService = oil.narrow(self.registryService, registryServiceInterface)
    end,

    testRegister1 = function(self)
      local member = Member{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:OpenBus/IMember:1.0")
      Check.assertEquals(false, (self.registryService:register({identifier = "", entityName = "", }, {type = "", description = "", properties = {}, member = member,})))
    end,

    testRegister2 = function(self)
      local member = Member{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:OpenBus/IMember:1.0")
      local success, registryIdentifier = self.registryService:register(self.credential, {type = "", description = "", properties = {}, member = member, })
      Check.assertNotEquals("", registryIdentifier)
      self.registryService:unregister(registryIdentifier)
    end,

    testUnregister = function(self)
      local member = Member{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:OpenBus/IMember:1.0")
      local success, registryIdentifier = self.registryService:register(self.credential, {type = "", description = "", properties = {}, member = member, })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
      Check.assertFalse(self.registryService:unregister(registryIdentifier))
    end,

    testFind = function(self)
      local member = Member{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:OpenBus/IMember:1.0")
      local success, registryIdentifier = self.registryService:register(self.credential, {type = "X", description = "", properties = {}, member = member, })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      local members = self.registryService:find("X", {})
      Check.assertNotEquals(0, #members)
      members = self.registryService:find("Y", {})
      Check.assertEquals(0, #members)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testRefresh = function(self)
      local member = Member{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:OpenBus/IMember:1.0")
      local serviceOffer = {type = "X", description = "", properties = {}, member = member, }
      Check.assertFalse(self.registryService:refresh("", serviceOffer))
      local success, registryIdentifier = self.registryService:register(self.credential, serviceOffer)
      Check.assertTrue(success)
      serviceOffer.type = "Y"
      Check.assertTrue(self.registryService:refresh(registryIdentifier, serviceOffer))
      local members = self.registryService:find("Y", {})
      Check.assertEquals(members[1].member:getName(), member:getName())
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
    end,
  }
}
