--
-- Testes unitários do Serviço de Registro
--
-- $Id$
--
local oil = require "oil"
local orb = oil.orb
local oop = require "loop.base"

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

local scs = require "scs.core.base"

local Check = require "latt.Check"

---- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent = {
  name = "IComponent",
  interface_name = "IDL:scs/core/IComponent:1.0",
  class = scs.Component
}
facetDescriptions.IMetaInterface = {
  name = "IMetaInterface",
  interface_name = "IDL:scs/core/IMetaInterface:1.0",
  class = scs.MetaInterface
}

-- Receptacle Descriptions
local receptacleDescriptions = {}

-- component id
local componentId = {}
componentId.name = "Membro Mock"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

-- Openbus login
local login = {}
login.user = "tester"
login.password = "tester"


Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
      if IDLPATH_DIR == nil then
        io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
        os.exit(1)
      end

      oil.verbose:level(0)

      local idlfile = IDLPATH_DIR.."/registry_service.idl"
      orb:loadidlfile(idlfile)
      idlfile = IDLPATH_DIR.."/access_control_service.idl"
      orb:loadidlfile(idlfile)

      self.accessControlService = orb:newproxy("corbaloc::localhost:2089/ACS",
        "IDL:openbusidl/acs/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(loadfile(
        DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config,
        self.credentialManager))

      local success
      success, self.credential = self.accessControlService:loginByPassword(
        login.user,
        login.password)
      self.credentialManager:setValue(self.credential)
      self.registryService = self.accessControlService:getRegistryService()
    end,

    testRegister = function(self)
      local member = scs.newComponent(facetDescriptions,
        receptacleDescriptions,
        componentId)
      local success, registryIdentifier = self.registryService:register({
        properties = {
          {name = "type", value = {"type1"}},
          {name = "description", value = {"bla bla bla"}},
        },
        member = member.IComponent,
      })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testFind_byName = function(self)
      local member = scs.newComponent(facetDescriptions,
        receptacleDescriptions,
        componentId)
      local success, registryIdentifier = self.registryService:register({
        properties = {
          {name = "type", value = {"X"}},
          {name = "description", value = {"bla"}},
        },
        member = member.IComponent,
      })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      local offers = self.registryService:find({"IComponent"})
      Check.assertNotEquals(0, #offers)
      for name, values in pairs (offers[1].properties) do
        if name == "description" then
          Check.assertEquals("bla", value[1])
        end
      end
      offers = self.registryService:find({"IDataService"})
      Check.assertEquals(0, #offers)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,
    
    testFind_byInterfaceName = function(self)
      local member = scs.newComponent(facetDescriptions,
        receptacleDescriptions,
        componentId)
      local success, registryIdentifier = self.registryService:register({
        properties = {},
        member = member.IComponent,
      })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      local offers = self.registryService:find({"IDL:scs/core/IComponent:1.0"})
      Check.assertNotEquals(0, #offers)
      
      offers = self.registryService:find({"IDL:scs/core/IComponent:2.0"})
      Check.assertEquals(0, #offers)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testFindByCriteria_ComponentId = function(self)
       local member = scs.newComponent(facetDescriptions,
        receptacleDescriptions,
        componentId)
      local success, registryIdentifier = self.registryService:register({
        properties = {},
        member = member.IComponent, 
      })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local offers = self.registryService:findByCriteria(
        {"IComponent"},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertNotEquals(0, #offers)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testFindByCriteria_Owner = function(self)
       local member = scs.newComponent(facetDescriptions,
        receptacleDescriptions,
        componentId)
      local success, registryIdentifier = self.registryService:register({
        properties = {},
        member = member.IComponent, 
      })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      local onwer = login.user
      local offers = self.registryService:findByCriteria(
        {"IComponent"},
        {
          {name = "registered_by", value = {owner}},
        }
      )
      Check.assertNotEquals(0, #offers)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,


    testUpdate = function(self)
      local member = scs.newComponent(facetDescriptions,
        receptacleDescriptions, componentId)
      local serviceOffer = {
        properties = {
          {name = "type", value = {"X"}},
          {name = "description", value = {"bla"}},
        }, member = member.IComponent, }
      Check.assertFalse(self.registryService:update("", {}))
      local success, registryIdentifier =
        self.registryService:register(serviceOffer)
      Check.assertTrue(success)
      local offers = self.registryService:findByCriteria(
        {"IComponent"},
        {
          {name = "type", value = {"X"}},
          {name = "p1", value = {"b"}
        }
      })
      Check.assertEquals(0, #offers)
      local newProps = {
        {name = "type", value = {"X"}},
        {name = "description", value = {"bla"}},
        {name = "p1", value = {"c", "a", "b"}}
      }
      Check.assertTrue(self.registryService:update(registryIdentifier,
        newProps))
      offers = self.registryService:findByCriteria(
        {"IComponent"},
        {
          {name = "type", value = {"X"}},
          {name = "p1", value = {"b"}
        }
      })
      Check.assertEquals(1, #offers)
      Check.assertEquals(offers[1].member:getComponentId().name,
        member._componentId.name)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testFacets = function(self)
      local dummyObserver = oop.class{
        credentialWasDeleted = function(self, credential) end
      }
      facetDescriptions.ICredentialObserver = {
        name = "facet1",
        interface_name = "IDL:openbusidl/acs/ICredentialObserver:1.0",
        class = dummyObserver
      }
      facetDescriptions.ICredentialObserver2 = {
        name = "facet2",
        interface_name = "IDL:openbusidl/acs/ICredentialObserver:1.0",
        class = dummyObserver
      }
      local member = scs.newComponent(facetDescriptions,
        receptacleDescriptions, componentId)
      local serviceOffer = {
        properties = {
          {name = "type", value = {"WithFacets"}},
          {name = "description", value = {"bla"}},
          {name = "p1", value = {"b"}}
        },
        member = member.IComponent
      }
      local success, registryIdentifier =
        self.registryService:register(serviceOffer)
      Check.assertTrue(success)
      local offers = self.registryService:find({"facet1", "facet2"})
      Check.assertEquals(1, #offers)
      offers = self.registryService:find({"facet2"})
      Check.assertEquals(1, #offers)
      offers = self.registryService:find({"facet3"})
      Check.assertEquals(0, #offers)
      local newProps = {
        {name = "type", value = {"WithFacets"}},
        {name = "description", value = {"bla"}},
        {name = "p1", value = {"b"}},
        {name = "facets", value = {"facet1"}}
      }
      Check.assertTrue(self.registryService:update(registryIdentifier,
        newProps))
      offers = self.registryService:find({"facet1", "facet4"})
      Check.assertEquals(0, #offers)
      offers = self.registryService:find({"facet1"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testNoCredential = function(self)
      self.credentialManager:invalidate()
      Check.assertError(self.registryService.find, self.registryService,
        {"IComponent"}, {name = "type", value = {"Y"}})
      self.credentialManager:setValue(self.credential)
    end,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,
  }
}
