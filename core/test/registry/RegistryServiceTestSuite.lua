--
-- Suite de Testes do Serviço de Registro
--
require "oil"
local orb = oil.orb
local Utils = require "openbus.util.Utils"
local Check = require "latt.Check"

local ComponentContext = require "scs.core.ComponentContext"

local Before = dofile("registry/beforeTestCase.lua")
local beforeTestCase = Before.beforeTestCase
local afterTestCase = dofile("registry/afterTestCase.lua")

--------------------------------------------------------------------------------
-- Funções auxiliares dos testes
--------------------------------------------------------------------------------

-- Muda de array para hash
local function props2hash(props)
  local hash = {}
  for _, prop in ipairs(props) do
    local values = {}
    for _, v in ipairs(prop.value) do
      values[v] = true
    end
    hash[prop.name] = values
  end
  return hash
end

-- Verifica se propsA contém propsB
local function contains(propsA, propsB)
  for nameB, valuesB in pairs(propsB) do
    -- Verifica se a propriedade existe
    local valuesA = propsA[nameB]
    if not valuesA then
      return false
    end
    -- Verifica se os valores da propriedade são iguais
    for vB in pairs(valuesB) do
      if not valuesA[vB] then
        return false
      end
    end
  end
  return true
end

-- Verifica se duas propriedades são iguais
local function equalsProps(propsA, propsB)
  local propsA = props2hash(propsA)
  local propsB = props2hash(propsB)

  -- Só é verdade de as duas forem iguais
  return (contains(propsA, propsB) and contains(propsB, propsA))
end

--------------------------------------------------------------------------------

Suite = {
  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    afterEachTest = function(self)
      if self.registryIdentifier then
        self.registryService:unregister(self.registryIdentifier)
      end
    end,

    testRegister = function(self)
      local member = ComponentContext(orb, self.Hello_v2.componentId)
      member:addFacet(self.Hello_v2.facets.IHello_v1.name,
                      self.Hello_v2.facets.IHello_v1.interface_name,
                      self.Hello_v2.facets.IHello_v1.class())
      member:addFacet(self.Hello_v2.facets.IHello_v2.name,
                      self.Hello_v2.facets.IHello_v2.interface_name,
                      self.Hello_v2.facets.IHello_v2.class())
      -- Identificar local propositalmente
      local success
      success, self.registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = self.Hello_v2.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)

      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)

      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(1, #offers)
      --
    end,

    testRegister_NoMetaInterfaceFacet = function(self)
      local member = ComponentContext(orb, self.Hello_v2.componentId)
      member:addFacet(self.Hello_v2.facets.IHello_v1.name,
                      self.Hello_v2.facets.IHello_v1.interface_name,
                      self.Hello_v2.facets.IHello_v1.class())
      member:addFacet(self.Hello_v2.facets.IHello_v2.name,
                      self.Hello_v2.facets.IHello_v2.interface_name,
                      self.Hello_v2.facets.IHello_v2.class())
      -- removendo a faceta IMetaInterface
      member:removeFacet("IMetaInterface")
      local success, err = self.rgsProtected:register({
        member = member.IComponent,
        properties = self.Hello_v2.properties,
      })
      Check.assertFalse(success)
      -- TODO: Complementar o teste para recupera a exceção correta após o
      -- témino do item de revisão das exceções das interfaces principais
      local success, err = self.rgsProtected:register({
        member = member.IComponent,
        properties = {},
      })
      Check.assertFalse(success)
      -- TODO: Complementar o teste para recupera a exceção correta após o
      -- témino do item de revisão das exceções das interfaces principais
      end,

    testFind_AfterLogout = function(self)
      local success, member_v1, member_v2, id_v1, id_v2
      member_v1 = ComponentContext(orb, self.Hello_v1.componentId)
      member_v1:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      success, id_v1 = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member_v1.IComponent,
      })
      --
      member_v2 = ComponentContext(orb, self.Hello_v2.componentId)
      member_v2:addFacet(self.Hello_v2.facets.IHello_v1.name,
                      self.Hello_v2.facets.IHello_v1.interface_name,
                      self.Hello_v2.facets.IHello_v1.class())
      member_v2:addFacet(self.Hello_v2.facets.IHello_v2.name,
                      self.Hello_v2.facets.IHello_v2.interface_name,
                      self.Hello_v2.facets.IHello_v2.class())
      success, id_v2 = self.rgsProtected:register({
        properties = self.Hello_v2.properties,
        member = member_v2.IComponent,
      })
      --Limpa o Serviço de Registro
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      socket.sleep(3)
      --Loga novamente
      Before.init(self)
      --Não pode encontrar ofertas
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(0, #offers)
    end,

    testUnregister = function(self)
      local member = ComponentContext(orb, self.Hello_v2.componentId)
      member:addFacet(self.Hello_v2.facets.IHello_v1.name,
                      self.Hello_v2.facets.IHello_v1.interface_name,
                      self.Hello_v2.facets.IHello_v1.class())
      member:addFacet(self.Hello_v2.facets.IHello_v2.name,
                      self.Hello_v2.facets.IHello_v2.interface_name,
                      self.Hello_v2.facets.IHello_v2.class())
      -- Identificar local propositalmente
      local success
      success, self.registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = self.Hello_v2.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)

      Check.assertTrue(self.registryService:unregister(self.registryIdentifier))
      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v1.name})
      Check.assertEquals(0, #offers)
      offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(0, #offers)

      self.registryIdentifier = nil
      --
    end,

    testUnregister_InvalidService = function(self)
      Check.assertFalse(self.registryService:unregister("INVALID-IDENTIFIER"))
    end,

    ---
    --- Testa se um oferta com duas facetas que implementam a mesma interface
    --- é corretamente registrada.
    testRegister_SameFacetInterface = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v2_2.componentId)
      member:addFacet(self.Hello_v2_2.facets.IHello_v2.name,
                      self.Hello_v2_2.facets.IHello_v2.interface_name,
                      self.Hello_v2_2.facets.IHello_v2.class())
      member:addFacet(self.Hello_v2_2.facets.IHello_v2_2.name,
                      self.Hello_v2_2.facets.IHello_v2_2.interface_name,
                      self.Hello_v2_2.facets.IHello_v2_2.class())
      success , self.registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = self.Hello_v2_2.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v2_2.facets.IHello_v2.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2_2.properties))
      --
      local offers = self.registryService:find({self.Hello_v2_2.facets.IHello_v2_2.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2_2.properties))
    end,

    ---
    -- Testa se o registro permite criar dois componentes que só diferem pelo
    -- componentId.
    ---
    testRegister_SameComponent_DiferentComponentId = function(self)
      local success, registryIdentifier
      local newComponentId = self.Hello_v2.componentId
      newComponentId.major_version = 2

      local member = ComponentContext(orb, self.Hello_v2.componentId)
      member:addFacet(self.Hello_v2.facets.IHello_v1.name,
                      self.Hello_v2.facets.IHello_v1.interface_name,
                      self.Hello_v2.facets.IHello_v1.class())
      member:addFacet(self.Hello_v2.facets.IHello_v2.name,
                      self.Hello_v2.facets.IHello_v2.interface_name,
                      self.Hello_v2.facets.IHello_v2.class())
      local member2 = ComponentContext(orb, newComponentId)
      member2:addFacet(self.Hello_v2.facets.IHello_v1.name,
                      self.Hello_v2.facets.IHello_v1.interface_name,
                      self.Hello_v2.facets.IHello_v1.class())
      member2:addFacet(self.Hello_v2.facets.IHello_v2.name,
                      self.Hello_v2.facets.IHello_v2.interface_name,
                      self.Hello_v2.facets.IHello_v2.class())

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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
      --
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    ---
    -- Testa se o serviço de registro permite criar réplicas de serviços com
    -- propriedades iguais.
    ---
    testRegister_Replica = function(self)
      local success
      local member1 = ComponentContext(orb, self.Hello_v1.componentId)
      member1:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      local member2 = ComponentContext(orb, self.Hello_v1.componentId)
      member2:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())

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
      Check.assertTrue(equalsProps(offers[1].properties, offers[2].properties))
      --
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    ---
    -- Testa se é possível registrar o mesmo componente instanciado duas vezes.
    ---
    testRegister_RegisterTwice = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())

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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v1.properties))
    end,

    testRegister_Unauthorized = function(self)
      local member = ComponentContext(orb, self.Hello_v3.componentId)
      member:addFacet(self.Hello_v3.facets.IHello_v1.name,
                      self.Hello_v3.facets.IHello_v1.interface_name,
                      self.Hello_v3.facets.IHello_v1.class())
      member:addFacet(self.Hello_v3.facets.IHello_v2.name,
                      self.Hello_v3.facets.IHello_v2.interface_name,
                      self.Hello_v3.facets.IHello_v2.class())
      member:addFacet(self.Hello_v3.facets.IHello_v3.name,
                      self.Hello_v3.facets.IHello_v3.interface_name,
                      self.Hello_v3.facets.IHello_v3.class())
      local success, err = self.rgsProtected:register({
        member = member.IComponent,
        properties = {},
      })
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/"..Utils.IDL_VERSION..
          "/registry_service/UnathorizedFacets:1.0")
      Check.assertEquals(#err.facets, 1)
    end,

    ---
    -- Testa se as propriedades internas da oferta (componentId e registeredBy)
    -- são corretamente sobrescritas pelo serviço.
    ---
    testRegister_InternalProperties = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
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

    testUpdate = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      success, self.registryIdentifier = self.rgsProtected:register({
          properties = self.Hello_v1.properties,
          member = member.IComponent,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v1.properties))
      --
      Check.assertTrue(self.rgsProtected:update(self.registryIdentifier,
          self.Hello_v2.properties))
      offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertFalse(equalsProps(offers[1].properties, self.Hello_v1.properties))
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testUpdate_Same = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      success, self.registryIdentifier = self.rgsProtected:register({
          properties = self.Hello_v1.properties,
          member = member.IComponent,
      })
      --
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v1.properties))
      --
      Check.assertTrue(self.rgsProtected:update(self.registryIdentifier,
          self.Hello_v1.properties))
      --
      offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v1.properties))
    end,

    testUpdate_InternalProperties = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
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
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      success, self.registryIdentifier = self.rgsProtected:register({
          properties = self.Hello_v1.properties,
          member = member.IComponent,
      })
      success, err = self.rgsProtected:update("INVALID-IDENTIFIER",
          self.Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/"..Utils.IDL_VERSION..
          "/registry_service/ServiceOfferNonExistent:1.0")
    end,

    testUpdate_UnauthorizedFacets = function(self)
      local success, err
      local member = ComponentContext(orb, self.Hello_v3.componentId)
      -- criando o componente sem a faceta hello v3
      member:addFacet(self.Hello_v3.facets.IHello_v1.name,
                      self.Hello_v3.facets.IHello_v1.interface_name,
                      self.Hello_v3.facets.IHello_v1.class())
      member:addFacet(self.Hello_v3.facets.IHello_v2.name,
                      self.Hello_v3.facets.IHello_v2.interface_name,
                      self.Hello_v3.facets.IHello_v2.class())
      success, self.registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = {},
      })
      Check.assertTrue(success)
      -- incluindo a faceta hello v3
      member:addFacet(self.Hello_v3.facets.IHello_v3.name,
                      self.Hello_v3.facets.IHello_v3.interface_name,
                      self.Hello_v3.facets.IHello_v3.class())
      success, err = self.rgsProtected:update(self.registryIdentifier,
          self.Hello_v3.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/"..Utils.IDL_VERSION..
          "/registry_service/UnathorizedFacets:1.0")
    end,
  },

  Test2 = {
    beforeTestCase = function(self)
      beforeTestCase(self)
      -- Registra ofertas para o teste
      local success
      self.member_v1 = ComponentContext(orb, self.Hello_v1.componentId)
      self.member_v1:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      success, self.id_v1 = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = self.member_v1.IComponent,
      })

      --
      self.member_v2 = ComponentContext(orb, self.Hello_v2.componentId)
      self.member_v2:addFacet(self.Hello_v2.facets.IHello_v1.name,
                      self.Hello_v2.facets.IHello_v1.interface_name,
                      self.Hello_v2.facets.IHello_v1.class())
      self.member_v2:addFacet(self.Hello_v2.facets.IHello_v2.name,
                      self.Hello_v2.facets.IHello_v2.interface_name,
                      self.Hello_v2.facets.IHello_v2.class())
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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByName_MoreResults = function(self)
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindByName_List = function(self)
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name,
                                                self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindbyInterfaceName_NotFound = function(self)
      local offers = self.registryService:find({"IDL:service/not/registered/:1.0"})
      Check.assertEquals(0, #offers)
    end,

    testFindbyInterfaceName = function(self)
      offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.interface_name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindbyInterfaceName_MoreResults = function(self)
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.interface_name})
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testFindbyInterfaceName_List = function(self)
      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v1.interface_name,
                                                self.Hello_v2.facets.IHello_v2.interface_name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Equals = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.name}, self.Hello_v1.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v1.properties))
      --
      offers = self.registryService:findByCriteria(
        {self.Hello_v2.facets.IHello_v1.name,
         self.Hello_v2.facets.IHello_v2.name}, self.Hello_v2.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
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
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
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
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v1.properties))
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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Interface_Equals = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name}, self.Hello_v1.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v1.properties))
      --
      offers = self.registryService:findByCriteria(
        {self.Hello_v1.facets.IHello_v1.interface_name,
         self.Hello_v2.facets.IHello_v2.interface_name}, self.Hello_v2.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
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
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
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
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Owner = function(self)
      local offers = self.registryService:findByCriteria(
        {self.Hello_v2.facets.IHello_v2.name},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
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
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
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
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
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
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
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

    testLocalFind = function(self)
      local entrys = self.registryService:localFind({self.Hello_v2.facets.IHello_v2.name}, {})
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFind_NameNotFound = function(self)
      local entrys = self.registryService:localFind({"IServiceNotRegistered"}, {})
      Check.assertEquals(0, #entrys)
    end,

    testLocalFindByName_MoreResults = function(self)
      local entrys = self.registryService:localFind({self.Hello_v1.facets.IHello_v1.name}, {})
      Check.assertEquals(2, #entrys)
      local offers = { entrys[1].aServiceOffer, entrys[2].aServiceOffer }
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testLocalFindByName_List = function(self)
      local entrys = self.registryService:localFind({self.Hello_v1.facets.IHello_v1.name,
                                                self.Hello_v2.facets.IHello_v2.name}, {})
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindbyInterfaceName_NotFound = function(self)
      local entrys = self.registryService:localFind({"IDL:service/not/registered/:1.0"}, {})
      Check.assertEquals(0, #entrys)
    end,

    testLocalFindbyInterfaceName = function(self)
      local entrys = self.registryService:localFind({self.Hello_v2.facets.IHello_v2.interface_name}, {})
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindbyInterfaceName_MoreResults = function(self)
      local entrys = self.registryService:localFind({self.Hello_v1.facets.IHello_v1.interface_name}, {})
      Check.assertEquals(2, #entrys)
      local offers = { entrys[1].aServiceOffer, entrys[2].aServiceOffer }
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testLocalFindbyInterfaceName_List = function(self)
      local entrys = self.registryService:localFind({self.Hello_v2.facets.IHello_v1.interface_name,
                                                self.Hello_v2.facets.IHello_v2.interface_name},
                                                {})
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Facet_Equals = function(self)
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.name}, self.Hello_v1.properties)
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v1.properties))
      --
      entrys = self.registryService:localFind(
        {self.Hello_v2.facets.IHello_v1.name,
         self.Hello_v2.facets.IHello_v2.name}, self.Hello_v2.properties)
      Check.assertEquals(1, #entrys)
      offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Facet_One = function(self)
      local versionValue
      for _, prop in ipairs(self.Hello_v2.properties) do
        if prop.name == "version" then
          versionValue = prop.value
          break
        end
      end
      local entrys = self.registryService:localFind(
        {self.Hello_v2.facets.IHello_v1.name},
        {
          {name = "version",
           value = versionValue}
        }
      )
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Facet_Empty = function(self)
      local entrys = self.registryService:localFind(
        {self.Hello_v2.facets.IHello_v1.name},
        {
          {name = "bugs", value = {}}
        }
      )
      Check.assertEquals(2, #entrys)
      local offers = { entrys[1].aServiceOffer, entrys[2].aServiceOffer }
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testLocalFindByCriteria_Facet_Any = function(self)
      local versionValue
      for _, prop in pairs(self.Hello_v1.properties) do
        if prop.name == "version" then
          versionValue = prop.value
          break
        end
      end
      local entrys = self.registryService:localFind(
        {self.Hello_v2.facets.IHello_v1.name},
        {
          {name = "version", value = versionValue}
        }
      )
      Check.assertEquals(2, #entrys)
      local offers = { entrys[1].aServiceOffer, entrys[2].aServiceOffer }
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testLocalFindByCriteria_Facet_ComponentId = function(self)
      local componentId = self.Hello_v1.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.name},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v1.properties))
    end,

    testLocalFindByCriteria_Facet_ComponentId_MoreComponents = function(self)
      local componentId = self.Hello_v2.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local entrys = self.registryService:localFind(
        {self.Hello_v2.facets.IHello_v1.name},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Interface_Equals = function(self)
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.interface_name}, self.Hello_v1.properties)
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v1.properties))
      --
      entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.interface_name,
         self.Hello_v2.facets.IHello_v2.interface_name}, self.Hello_v2.properties)
      Check.assertEquals(1, #entrys)
      offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Interface_One = function(self)
      local versionValue
      for _, prop in pairs(self.Hello_v2.properties) do
        if prop.name == "version" then
          versionValue = prop.value
          break
        end
      end
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "version", value = versionValue}
        }
      )
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Interface_Empty = function(self)
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "bugs", value = {}}
        }
      )
      Check.assertEquals(2, #entrys)
      local offers = { entrys[1].aServiceOffer, entrys[2].aServiceOffer }
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testLocalFindByCriteria_Interface_Any = function(self)
      local versionValue
      for _, prop in pairs(self.Hello_v1.properties) do
        if prop.name == "version" then
          versionValue = prop.value
          break
        end
      end
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "version", value = versionValue}
        }
      )
      Check.assertEquals(2, #entrys)
      local offers = { entrys[1].aServiceOffer, entrys[2].aServiceOffer }
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testLocalFindByCriteria_Interface_ComponentId = function(self)
      local componentId = self.Hello_v2.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Interface_ComponentId_MoreComponents = function(self)
      local componentId = self.Hello_v2.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Facet_Owner = function(self)
      local entrys = self.registryService:localFind(
        {self.Hello_v2.facets.IHello_v2.name},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Facet_Owner_MoreResults = function(self)
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.name},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(2, #entrys)
      local offers = { entrys[1].aServiceOffer, entrys[2].aServiceOffer }
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testLocalFindByCriteria_Facet_Owner_NotFound = function(self)
      local entrys = self.registryService:localFind(
        {"InvalidFacet"},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(0, #entrys)
    end,

    testLocalFindByCriteria_Interface_Owner = function(self)
      local entrys = self.registryService:localFind(
        {self.Hello_v2.facets.IHello_v2.interface_name},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(1, #entrys)
      local offer = entrys[1].aServiceOffer
      Check.assertTrue(equalsProps(offer.properties, self.Hello_v2.properties))
    end,

    testLocalFindByCriteria_Interface_Owner_MoreResults = function(self)
      local entrys = self.registryService:localFind(
        {self.Hello_v1.facets.IHello_v1.interface_name},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(2, #entrys)
      local offers = { entrys[1].aServiceOffer, entrys[2].aServiceOffer }
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, self.Hello_v1.properties) or
        equalsProps(offers[2].properties, self.Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, self.Hello_v2.properties) or
        equalsProps(offers[2].properties, self.Hello_v2.properties))
      )
    end,

    testLocalFindByCriteria_Interface_Owner_NotFound = function(self)
      local entrys = self.registryService:localFind(
        {"IDL:InvalidFacet:1.0"},
        {
          {name = "registered_by", value = {self.deploymentId}},
        }
      )
      Check.assertEquals(0, #entrys)
    end,
  },

  Test3 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    beforeEachTest = function(self)
      self.credentialManager:setValue(self.credential)
      self.registryIdentifier = nil
    end,

    afterEachTest = function(self)
      self.credentialManager:setValue(self.credential)
      if self.registryIdentifier then
        self.registryService:unregister(self.registryIdentifier)
      end
    end,

    testRegister_NoCredential = function(self)
      self.credentialManager:invalidate()
      --
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      local success, err = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testFind_NoCredential = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      success, self.registryIdentifier = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.rgsProtected:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testUpdate_NoCredential = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      success, self.registryIdentifier = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.rgsProtected:update(self.registryIdentifier,
        self.Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testFindByCriteria_NoCredential = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      success, self.registryIdentifier = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.rgsProtected:findByCriteria(
  {self.Hello_v1.facets.IHello_v1.name}, self.Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testUnregister_NoCredential = function(self)
      local success
      local member = ComponentContext(orb, self.Hello_v1.componentId)
      member:addFacet(self.Hello_v1.facets.IHello_v1.name,
                      self.Hello_v1.facets.IHello_v1.interface_name,
                      self.Hello_v1.facets.IHello_v1.class())
      success, self.registryIdentifier = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.rgsProtected:unregister(
        self.registryIdentifier)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,
  },
}
