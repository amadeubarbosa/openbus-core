--
-- Suite de Testes do Serviço de Registro
--
require "oil"
local orb = oil.orb
local Utils = require "openbus.util.Utils"
local Check = require "latt.Check"

local scs = require "scs.core.base"

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
      local member = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
        self.Hello_v2.componentId)
      -- Identificar local propositalmente
      local success
      sucess, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v2.properties, member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)

      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)

      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(1, #offers)
      --
    end,

    testRegister_NoMetaInterfaceFacet = function(self)
      local member = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
        self.Hello_v2.componentId)
      -- removendo a faceta IMetaInterface
      member._orb:deactivate(member.IMetaInterface)
      member._facetDescs.IMetaInterface = nil
      member.IMetaInterface = nil
      local success, err = self.rgsProtected:register(self.Hello_v2.properties, 
        member.IComponent)
      Check.assertFalse(success)
      -- TODO: Complementar o teste para recupera a exceção correta após o 
      -- témino do item de revisão das exceções das interfaces principais
      local success, err = self.rgsProtected:register({}, member.IComponent)
      Check.assertFalse(success)
      -- TODO: Complementar o teste para recupera a exceção correta após o 
      -- témino do item de revisão das exceções das interfaces principais
      end,

    testFind_AfterLogout = function(self)
      local success, member_v1, member_v2, id_v1, id_v2
      member_v1 = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, id_v1 = self.rgsProtected:register(
        self.Hello_v1.properties, member_v1.IComponent)
      --
      member_v2 = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
        self.Hello_v2.componentId)
      success, id_v2 = self.rgsProtected:register(
        self.Hello_v2.properties, member_v2.IComponent)
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
      local member = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
        self.Hello_v2.componentId)
      -- Identificar local propositalmente
      local success
      sucess, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v2.properties, member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)

      local succ, err = oil.pcall(self.registryService.unregister, 
        self.registryService, self.registryIdentifier)
      Check.assertTrue(succ)
      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v1.name})
      Check.assertEquals(0, #offers)
      offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(0, #offers)

      self.registryIdentifier = nil
      --
    end,

    testUnregister_InvalidService = function(self)
      local succ, err = oil.pcall(self.registryService.unregister, 
        self.registryService, "INVALID-IDENTIFIER")
      Check.assertFalse(succ)
      -- TODO: check excepetion
    end,

    ---
    --- Testa se um oferta com duas facetas que implementam a mesma interface
    --- é corretamente registrada.
    testRegister_SameFacetInterface = function(self)
      local success
      local member = scs.newComponent(self.Hello_v2_2.facets, self.Hello_v2_2.receptacles,
        self.Hello_v2_2.componentId)
      success , self.registryIdentifier = self.rgsProtected:register(
        Hello_v2_2.properties, member.IComponent)
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

      local member = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
          self.Hello_v2.componentId)
      local member2 = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
          newComponentId)

      success , self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v2.properties, member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      success , registryIdentifier = self.rgsProtected:register(
        self.Hello_v2.properties, member2.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(registryIdentifier)
      Check.assertNotEquals(self.registryIdentifier, registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(2, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v2.properties))
      --
      local succ, err = oil.pcall(self.registryService.unregister, 
        self.registryService, registryIdentifier)
      Check.assertTrue(succ)
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

      success, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member1.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      success, registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member2.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(registryIdentifier)
      Check.assertNotEquals(registryIdentifier,self.registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(2, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, offers[2].properties))
      --
      local succ, err = oil.pcall(self.registryService.unregister, 
        self.registryService, registryIdentifier)
      Check.assertTrue(succ)
    end,

    ---
    -- Testa se é possível registrar o mesmo componente instanciado duas vezes.
    ---
    testRegister_RegisterTwice = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)

      success, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      success, registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(registryIdentifier)
      Check.assertEquals(registryIdentifier,self.registryIdentifier)
      --
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, self.Hello_v1.properties))
    end,

    testRegister_Unauthorized = function(self)
      local member = scs.newComponent(self.Hello_v3.facets, self.Hello_v3.receptacles,
        self.Hello_v3.componentId)
      local success, err = self.rgsProtected:register({}, member.IComponent)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/"..Utils.OB_VERSION..
          "/registry_service/UnauthorizedFacets:1.0")
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
      success, self.registryIdentifier = self.rgsProtected:register(
        self.fakeProps, member.IComponent)
      --
      local offers = self.registryService:findByCriteria(
          {self.Hello_v1.facets.IHello_v1.name}, self.trueProps)
      Check.assertEquals(1, #offers)
    end,
    
    testUpdate = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
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
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
          self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
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
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register(
        self.trueProps, member.IComponent)
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
      success, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
      success, err = self.rgsProtected:update("INVALID-IDENTIFIER",
          self.Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/"..Utils.OB_VERSION..
          "/registry_service/ServiceOfferDoesNotExist:1.0")
    end,

    testUpdate_UnauthorizedFacets = function(self)
      local success, err
      local member = scs.newComponent(self.Hello_v3.facets, self.Hello_v3.receptacles,
        self.Hello_v3.componentId)
      -- guardando localmente a faceta hello v3
      local hellov3_desc = member._facetDescs.IHello_v3
      local hellov3 = member.IHello_v3
      -- removendo a faceta hello v3 do componente
      member._facetDescs.IHello_v3 = nil
      member.IHello_v3 = nil
      success, self.registryIdentifier = self.rgsProtected:register({},
        member.IComponent)
      Check.assertTrue(success) 
      -- incluindo a faceta hello v3
      member._facetDescs.IHello_v3 = hellov3_desc
      member.IHello_v3 = hellov3
      success, err = self.rgsProtected:update(self.registryIdentifier,
          self.Hello_v3.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/"..Utils.OB_VERSION..
          "/registry_service/UnauthorizedFacets:1.0")
    end,
  },

  Test2 = {
    beforeTestCase = function(self)
      beforeTestCase(self)
      -- Registra ofertas para o teste
      local success
      self.member_v1 = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.id_v1 = self.rgsProtected:register(
        self.Hello_v1.properties, self.member_v1.IComponent)

      --
      self.member_v2 = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
        self.Hello_v2.componentId)
      success, self.id_v2 = self.rgsProtected:register(
        self.Hello_v2.properties, self.member_v2.IComponent)
      Check.assertNotEquals(self.id_v1, self.id_v2)
    end,

    afterTestCase = function(self)
      local succ, err = oil.pcall(self.registryService.unregister, 
        self.registryService, self.id_v1)
      Check.assertTrue(succ)
      succ, err = oil.pcall(self.registryService.unregister, 
        self.registryService, self.id_v2)
      Check.assertTrue(succ)
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
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      local success, err = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testFind_NoCredential = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
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
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
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
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
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
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register(
        self.Hello_v1.properties, member.IComponent)
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