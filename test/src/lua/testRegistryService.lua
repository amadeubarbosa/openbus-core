require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialHolder = require "openbus.common.CredentialHolder"

require "openbus.Member"

local Check = require "latt.Check"

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
      if CORBA_IDL_DIR == nil then
        io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end

      oil.verbose:level(0)

      local idlfile = CORBA_IDL_DIR.."/registry_service.idl"
      oil.loadidlfile(idlfile)
      idlfile = CORBA_IDL_DIR.."/access_control_service.idl"
      oil.loadidlfile(idlfile)

      local user = "csbase"
      local password = "csbLDAPtest"

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlServiceComponent:1.0")
      local accessControlServiceInterface = "IDL:openbusidl/acs/IAccessControlService:1.0"
      self.accessControlService = accessControlServiceComponent:getFacet(accessControlServiceInterface)
      self.accessControlService = oil.narrow(self.accessControlService, accessControlServiceInterface)

      -- instala o interceptador de cliente
      local CONF_DIR = os.getenv("CONF_DIR")
      local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
      self.credentialHolder = CredentialHolder()
      oil.setclientinterceptor(ClientInterceptor(config, self.credentialHolder))

      local success
      success, self.credential = self.accessControlService:loginByPassword(user, password)
      self.credentialHolder:setValue(self.credential)

      self.registryService = self.accessControlService:getRegistryService()
      local registryServiceInterface = "IDL:openbusidl/rs/IRegistryService:1.0"
      self.registryService = self.registryService:getFacet(registryServiceInterface)
      self.registryService = oil.narrow(self.registryService, registryServiceInterface)
print("autenticou o obteve o registryService")
    end,

    testRegister2 = function(self)
      local member = Member{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:openbusidl/IMember:1.0")
      local success, registryIdentifier = self.registryService:register({type = "", description = "", properties = {}, member = member, })
      Check.assertNotEquals("", registryIdentifier)
      self.registryService:unregister(registryIdentifier)
    end,

    testUnregister = function(self)
      local member = Member{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:openbusidl/IMember:1.0")
      local success, registryIdentifier = self.registryService:register({type = "", description = "", properties = {}, member = member, })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
      Check.assertFalse(self.registryService:unregister(registryIdentifier))
    end,

    testFind = function(self)
      local member = Member{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:openbusidl/IMember:1.0")
      local success, registryIdentifier = self.registryService:register({type = "X", description = "", properties = {}, member = member, })
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
      member = oil.newobject(member, "IDL:openbusidl/IMember:1.0")
      local serviceOffer = {type = "X", description = "", properties = {}, member = member, }
      Check.assertFalse(self.registryService:refresh("", serviceOffer))
      local success, registryIdentifier = self.registryService:register(serviceOffer)
      Check.assertTrue(success)
      serviceOffer.type = "Y"
      Check.assertTrue(self.registryService:refresh(registryIdentifier, serviceOffer))
      local members = self.registryService:find("Y", {})
      Check.assertEquals(members[1].member:getName(), member:getName())
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testNoCredential = function(self)
      self.credentialHolder:invalidate()
      Check.assertError(self.registryService.find,self.registryService,"Y",{})
      self.credentialHolder:setValue(self.credential)
    end,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialHolder:invalidate()
    end,
  }
}
