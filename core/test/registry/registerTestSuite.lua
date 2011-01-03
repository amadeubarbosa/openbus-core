--
-- Suite de Teste para operacao 'register' do Serviço de Registro
-- para verificar se um oferta com duas interfaces de mesmo nome
-- foi corretamente registrada.
--
--
local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local Utils = require "openbus.util.Utils"

local utils             = require "core.test.lua.registry.utils"

local scs = require "scs.core.base"

local Check = require "latt.Check"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
local Before = dofile("registry/beforeTestCase.lua")
local beforeTestCase = Before.beforeTestCase
local afterTestCase = dofile("registry/afterTestCase.lua")

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
    ---
    --- Testa se um oferta com duas facetas que implementam a mesma interface
    --- é corretamente registrada.
    testRegister_SameFacetInterface = function(self)
      local success
      local member = scs.newComponent(self.Hello_v2_2.facets, self.Hello_v2_2.receptacles,
        self.Hello_v2_2.componentId)
      success , self.registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = self.Hello_v2_2.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v2_2.facets.IHello_v2.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2_2.properties))
      --
      local offers = self.registryService:find({self.Hello_v2_2.facets.IHello_v2_2.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2_2.properties))
    end,

    ---
    -- Testa se o registro permite criar dois componentes que só diferem pelo
    -- componentId.
    ---
    testRegister_SameComponent_DiferentComponentId = function(self)
      local success, registryIdentifier
      local newComponentId = self.Hello_v2.componentId
      newComponentId.major_version = 2

      local member = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
          self.Hello_v2.componentId)
      local member2 = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
          newComponentId)

      success , self.registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = self.Hello_v2.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      success , registryIdentifier = self.rgsProtected:register({
        member = member2.IComponent,
        properties = self.Hello_v2.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(registryIdentifier)
      Check.assertNotEquals(self.registryIdentifier, registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(2, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v2.properties))
      --
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    ---
    -- Testa se o serviço de registro permite criar réplicas de serviços com
    -- propriedades iguais.
    ---
    testRegister_Replica = function(self)
      local success
      local member1 = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)
      local member2 = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)

      success, self.registryIdentifier = self.rgsProtected:register({
        member = member1.IComponent,
        properties = self.Hello_v1.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      success, registryIdentifier = self.rgsProtected:register({
        member = member2.IComponent,
        properties = self.Hello_v1.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(registryIdentifier)
      Check.assertNotEquals(registryIdentifier,self.registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(2, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, offers[2].properties))
      --
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    ---
    -- Testa se é possível registrar o mesmo componente instanciado duas vezes.
    ---
    testRegister_RegisterTwice = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)

      success, self.registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = self.Hello_v1.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      success, registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = self.Hello_v1.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(registryIdentifier)
      Check.assertEquals(registryIdentifier,self.registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(utils:equalsProps(offers[1].properties, self.Hello_v1.properties))
    end,

    testRegister_Unauthorized = function(self)
      local member = scs.newComponent(self.Hello_v3.facets, self.Hello_v3.receptacles,
        self.Hello_v3.componentId)
      local success, err = self.rgsProtected:register({
        member = member.IComponent,
        properties = {},
      })
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/"..Utils.OB_VERSION..
          "/registry_service/UnathorizedFacets:1.0")
      Check.assertEquals(#err.facets, 1)
    end,

    ---
    -- Testa se as propriedades internas da oferta (componentId e registeredBy)
    -- são corretamente sobrescritas pelo serviço.
    ---
    testRegister_InternalProperties = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)
      -- Tenta sobrescrita de propriedade definidas internamente no RS
      success, self.registryIdentifier = self.rgsProtected:register({
          properties = self.fakeProps,
          member = member.IComponent,
      })
      --
      local offers = self.registryService:findByCriteria(
          {self.Hello_v1.facets.IHello_v1.name}, self.trueProps)
      Check.assertEquals(1, #offers)
    end,
  },
}

return Suite
