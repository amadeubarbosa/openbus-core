--
-- Suite de Teste da operacao 'find' do Serviço de Registro
--
--
local oil = require "oil"

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local utils = require "core.test.registry.utils"

local scs = require "scs.core.base"

local Check = require "latt.Check"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
local Before = dofile("registry/beforeTestCase.lua")
local beforeTestCase = Before.beforeTestCase
local afterTestCase = dofile("registry/afterTestCase.lua")

-------------------------------------------------------------------------------

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      beforeTestCase(self)
      -- Registra ofertas para o teste
      local success
      self.member_v1 = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.id_v1 = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = self.member_v1.IComponent,
      })

      --
      self.member_v2 = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
        self.Hello_v2.componentId)
      success, self.id_v2 = self.rgsProtected:register({
        properties = self.Hello_v2.properties,
        member = self.member_v2.IComponent,
      })

      Check.assertNotEquals(self.id_v1, self.id_v2)
    end,

    afterTestCase = function(self)
      Check.assertTrue(self.registryService:unregister(self.id_v1))
      Check.assertTrue(self.registryService:unregister(self.id_v2))
      afterTestCase(self)
    end,

    afterEachTest = function(self)
      if self.registryIdentifier then
        self.registryService:unregister(self.registryIdentifier)
      end
    end,

    testFindByName_NotFound = function(self)
      local offers = self.registryService:find({"IServiceNotRegistered"})
      Check.assertEquals(0, #offers)
    end,

    testFindByName = function(self)
      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByName_MoreResults = function(self)
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (utils:equalsProps(offers[1].properties, self.Hello_v1.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (utils:equalsProps(offers[1].properties, self.Hello_v2.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindByName_List = function(self)
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name,
                                                self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindbyInterfaceName_NotFound = function(self)
      local offers = self.registryService:find({"IDL:service/not/registered/:1.0"})
      Check.assertEquals(0, #offers)
    end,

    testFindbyInterfaceName = function(self)
      offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.interface_name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindbyInterfaceName_MoreResults = function(self)
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.interface_name})
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (utils:equalsProps(offers[1].properties, self.Hello_v1.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (utils:equalsProps(offers[1].properties, self.Hello_v2.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindbyInterfaceName_List = function(self)
      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v1.interface_name,
                                                self.Hello_v2.facets.IHello_v2.interface_name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Equals = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.name}, self.Hello_v1.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v1.properties))
      --
      offers = self.registryService:findByCriteria(
        {self.Hello_v2.facets.IHello_v1.name,
         self.Hello_v2.facets.IHello_v2.name}, self.Hello_v2.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Facet_One = function(self)
      local versionValue
      for _, prop in ipairs(self.Hello_v2.properties) do
        if prop.name == "version" then
          versionValue = prop.value
          break
        end
      end
      local offers = self.registryService:findByCriteria(
        {self.Hello_v2.facets.IHello_v1.name},
        {
          {name = "version",
           value = versionValue}
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Empty = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v2.facets.IHello_v1.name},
        {
          {name = "bugs", value = {}}
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (utils:equalsProps(offers[1].properties, self.Hello_v1.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (utils:equalsProps(offers[1].properties, self.Hello_v2.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindByCriteria_Facet_Any = function(self)
      local versionValue
      for _, prop in pairs(self.Hello_v1.properties) do
        if prop.name == "version" then
          versionValue = prop.value
          break
        end
      end
      local offers = self.registryService:findByCriteria(
        {self.Hello_v2.facets.IHello_v1.name},
        {
          {name = "version", value = versionValue}
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (utils:equalsProps(offers[1].properties, self.Hello_v1.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (utils:equalsProps(offers[1].properties, self.Hello_v2.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindByCriteria_Facet_ComponentId = function(self)
      local componentId = self.Hello_v1.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.name},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v1.properties))
    end,

    testFindByCriteria_Facet_ComponentId_MoreComponents = function(self)
      local componentId = self.Hello_v2.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local offers = self.registryService:findByCriteria(
        {self.Hello_v2.facets.IHello_v1.name},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Interface_Equals = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name}, self.Hello_v1.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v1.properties))
      --
      offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name,
         self.Hello_v2.facets.IHello_v2.interface_name}, self.Hello_v2.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Interface_One = function(self)
      local versionValue
      for _, prop in pairs(self.Hello_v2.properties) do
        if prop.name == "version" then
          versionValue = prop.value
          break
        end
      end
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "version", value = versionValue}
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Interface_Empty = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "bugs", value = {}}
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (utils:equalsProps(offers[1].properties, self.Hello_v1.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (utils:equalsProps(offers[1].properties, self.Hello_v2.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindByCriteria_Interface_Any = function(self)
      local versionValue
      for _, prop in pairs(self.Hello_v1.properties) do
        if prop.name == "version" then
          versionValue = prop.value
          break
        end
      end
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "version", value = versionValue}
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (utils:equalsProps(offers[1].properties, self.Hello_v1.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (utils:equalsProps(offers[1].properties, self.Hello_v2.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindByCriteria_Interface_ComponentId = function(self)
      local componentId = self.Hello_v2.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Interface_ComponentId_MoreComponents = function(self)
      local componentId = self.Hello_v2.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Owner = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v2.facets.IHello_v2.name},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Owner_MoreResults = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.name},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (utils:equalsProps(offers[1].properties, self.Hello_v1.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (utils:equalsProps(offers[1].properties, self.Hello_v2.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindByCriteria_Facet_Owner_NotFound = function(self)
      local offers = self.registryService:findByCriteria(
        {"InvalidFacet"},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(0, #offers)
    end,

    testFindByCriteria_Interface_Owner = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v2.facets.IHello_v2.interface_name},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Interface_Owner_MoreResults = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (utils:equalsProps(offers[1].properties, self.Hello_v1.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (utils:equalsProps(offers[1].properties, self.Hello_v2.properties) or
        utils:equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindByCriteria_Interface_Owner_NotFound = function(self)
      local offers = self.registryService:findByCriteria(
        {"IDL:InvalidFacet:1.0"},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(0, #offers)
    end,

  },
}

return Suite
