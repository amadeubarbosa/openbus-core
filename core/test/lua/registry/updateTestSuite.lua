--
-- Suite de teste da operacao 'update' do Serviço de Registro
--
--
local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local utils = require "core.test.lua.registry.utils"

local scs = require "scs.core.base"

local Check = require "latt.Check"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
local Before = dofile(OPENBUS_HOME .."/core/test/lua/registry/beforeTestCase.lua")
local beforeTestCase = Before.beforeTestCase
local afterTestCase = dofile(OPENBUS_HOME .."/core/test/lua/registry/afterTestCase.lua")

-------------------------------------------------------------------------------

Suite = {
  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    afterEachTest = function(self)
      if self.registryIdentifier then
        self.registryService:unregister(self.registryIdentifier)
      end
    end,


    testUpdate = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register({
          properties = self.Hello_v1.properties,
          member = member.IComponent,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v1.properties))
      --
      Check.assertTrue(self.rgsProtected:update(self.registryIdentifier,
          self.Hello_v2.properties))
      offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertFalse(utils:equalsProps(offers[1].properties, self.Hello_v1.properties))
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testUpdate_Same = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register({
          properties = self.Hello_v1.properties,
          member = member.IComponent,
      })
      --
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v1.properties))
      --
      Check.assertTrue(self.rgsProtected:update(self.registryIdentifier,
          self.Hello_v1.properties))
      --
      offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v1.properties))
    end,

    testUpdate_InternalProperties = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register({
        properties = self.trueProps,
        member = member.IComponent,
      })
      Check.assertTrue(success)
      -- Tenta sobrescrita de propriedade definidas internamente no RS
      Check.assertTrue(self.rgsProtected:update(self.registryIdentifier, self.fakeProps))
      --
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.name}, self.trueProps)
      Check.assertEquals(1, #offers)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.name}, self.fakeProps)
      Check.assertEquals(0, #offers)
    end,

    testUpdate_Invalid = function(self)
      local success, err
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register({
          properties = self.Hello_v1.properties,
          member = member.IComponent,
      })
      success, err = self.rgsProtected:update("INVALID-IDENTIFIER",
          self.Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/registry_service/ServiceOfferNonExistent:1.0")
    end,
  },
}

return Suite
