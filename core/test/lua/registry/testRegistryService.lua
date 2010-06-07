--
-- Testes unitários do Serviço de Registro
--
-- $Id: testRegistryService.lua 104952 2010-04-30 21:43:16Z augusto $
--
local oil = require "oil"
local orb = oil.orb
local oop = require "loop.base"
local print = print

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local Utils = require "openbus.util.Utils"

local scs = require "scs.core.base"

local Check = require "latt.Check"

-------------------------------------------------------------------------------
-- Informações sobre os componentes usados nos testes
--

-- Interfaces

local IDL = {
  "interface IHello_v1 { };",
  "interface IHello_v2 { };",
  "interface IHello_v3 { };", -- não autorizada no RS
}

-- Descrições

local Hello_v1  = {
  -- Descrição dos receptáculos
  receptacles = {},
  -- Descrição das facetas
  facets = {
    IComponent = {
      name = "IComponent",
      interface_name = "IDL:scs/core/IComponent:1.0",
      class = scs.Component
    },
    IMetaInterface = {
      name = "IMetaInterface",
      interface_name = "IDL:scs/core/IMetaInterface:1.0",
      class = scs.MetaInterface
    },
    IHello_v1 = {
      name = "IHello_v1",
      interface_name = "IDL:IHello_v1:1.0",
      class = oop.class({}),
    },
  },
  -- ComponentId
  componentId = {
    name = "Hello_v1",
    major_version = 1,
    minor_version = 0,
    patch_version = 0,
    platform_spec = "",
  },
  -- Propriedades para o registro.
  -- Alguns testes levam em consideração que as propriedades dos dois
  -- componentes são diferentes.
  properties = {
    {name = "type",        value = {"IHello"}},
    {name = "description", value = {"IHello versão 1.0"}},
    {name = "version",     value = {"1.0"}},
    -- Teste de propriedade vazia
    {name = "bugs",        value = {}},
  },
}

local Hello_v2  = {
  -- Descrição dos receptáculos
  receptacles = {},
  -- Descrição das facetas
  facets = {
    IComponent = {
      name = "IComponent",
      interface_name = "IDL:scs/core/IComponent:1.0",
      class = scs.Component
    },
    IMetaInterface = {
      name = "IMetaInterface",
      interface_name = "IDL:scs/core/IMetaInterface:1.0",
      class = scs.MetaInterface
    },
    IHello_v1 = {
      name = "IHello_v1",
      interface_name = "IDL:IHello_v1:1.0",
      class = oop.class({}),
    },
    IHello_v2 = {
      name = "IHello_v2",
      interface_name = "IDL:IHello_v2:1.0",
      class = oop.class({}),
    },
  },
  -- ComponentId
  componentId = {
    name = "Hello_v2",
    major_version = 1,
    minor_version = 0,
    patch_version = 0,
    platform_spec = "",
  },
  -- Propriedades para o registro.
  -- Alguns testes levam em consideração que as propriedades dos dois
  -- componentes são diferentes.
  properties = {
    {name = "type",        value = {"IHello"}},
    {name = "description", value = {"IHello versões 1.0 e 2.0"}},
    -- Teste de múltiplos valores
    {name = "version",     value = {"1.0", "2.0"}},
    -- Teste de propriedade vazia
    {name = "bugs",        value = {}},
  },
}

local Hello_v3  = {
  -- Descrição dos receptáculos
  receptacles = {},
  -- Descrição das facetas
  facets = {
    IComponent = {
      name = "IComponent",
      interface_name = "IDL:scs/core/IComponent:1.0",
      class = scs.Component
    },
    IMetaInterface = {
      name = "IMetaInterface",
      interface_name = "IDL:scs/core/IMetaInterface:1.0",
      class = scs.MetaInterface
    },
    IHello_v1 = {
      name = "IHello_v1",
      interface_name = "IDL:IHello_v1:1.0",
      class = oop.class({}),
    },
    IHello_v2 = {
      name = "IHello_v2",
      interface_name = "IDL:IHello_v2:1.0",
      class = oop.class({}),
    },
    IHello_v3 = {
      name = "IHello_v3",
      interface_name = "IDL:IHello_v3:1.0",
      class = oop.class({}),
    },
  },
  -- ComponentId
  componentId = {
    name = "Hello_v3",
    major_version = 1,
    minor_version = 0,
    patch_version = 0,
    platform_spec = "",
  },
  properties = {
    {
      name = "facets",
      value = {
        -- não exporta IHello_v1
        "IDL:IHello_v2:1.0",  -- autorizada no RS
        "IDL:IHello_v3:1.0",  -- não autorizada no RS
      },
    },
  },
}

-------------------------------------------------------------------------------
local deploymentId = "TesteBarramento"
local testCertFile = deploymentId .. ".crt"
local testKeyFile  = deploymentId .. ".key"
local acsCertFile  = "AccessControlService.crt"

-------------------------------------------------------------------------------
-- Funções auxiliares

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

-- Inicializa as referências para o OpenBus em cada teste
function init(self)
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end

  oil.verbose:level(0)

  orb:loadidlfile(IDLPATH_DIR.."/v1_05/registry_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/v1_05/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/v1_04/registry_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/v1_04/access_control_service.idl")
  for _, idl in ipairs(IDL) do
    orb:loadidl(idl)
  end

  -- Recupera o Serviço de Acesso
  local acsComp = orb:newproxy("corbaloc::localhost:2089/openbus_v1_05",
      "IDL:scs/core/IComponent:1.0")
  local facet = acsComp:getFacet("IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
  self.accessControlService = orb:narrow(facet, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
  -- instala o interceptador de cliente
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  local config = assert(loadfile(
    DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
  self.credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config,
    self.credentialManager))
  -- Login do serviço para a realização do teste
  local challenge = self.accessControlService:getChallenge(deploymentId)
  local privateKey = lce.key.readprivatefrompemfile(testKeyFile)
  challenge = lce.cipher.decrypt(privateKey, challenge)
  cert = lce.x509.readfromderfile(acsCertFile)
  challenge = lce.cipher.encrypt(cert:getpublickey(), challenge)
  local succ
  succ, self.credential, self.lease =
    self.accessControlService:loginByCertificate(deploymentId, challenge)
  self.credentialManager:setValue(self.credential)
  -- Recupera o Serviço de Registro
  local acsIComp = self.accessControlService:_component()
  acsIComp = orb:narrow(acsIComp, "IDL:scs/core/IComponent:1.0")
  local acsIRecept = acsIComp:getFacetByName("IReceptacles")
  acsIRecept = orb:narrow(acsIRecept, "IDL:scs/core/IReceptacles:1.0")
  local conns = acsIRecept:getConnections("RegistryServiceReceptacle")
  local rsIComp = orb:narrow(conns[1].objref, "IDL:scs/core/IComponent:1.0")
  self.registryService = rsIComp:getFacetByName("IRegistryService_v" .. Utils.OB_VERSION)
  self.registryService = orb:narrow(self.registryService,
    "IDL:tecgraf/openbus/core/v1_05/registry_service/IRegistryService:1.0")
end

-------------------------------------------------------------------------------

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      init(self)
      --
      self.fakeProps = {
        {name = "component_id",  value = {"DoNotExists:8.8.8"}},
        {name = "registered_by", value = {"DoNotExists"}},
      }
      self.trueProps = {
        {name = "component_id",
         value = {string.format(
                    "%s:%d.%d.%d",
                    Hello_v1.componentId.name,
                    Hello_v1.componentId.major_version,
                    Hello_v1.componentId.minor_version,
                    Hello_v1.componentId.patch_version)
                 }
        },
        {name = "registered_by", value = {deploymentId}},
      }
    end,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

    beforeEachTest = function(self)
      self.registryIdentifier = nil
    end,

    afterEachTest = function(self)
      if self.registryIdentifier then
        self.registryService:unregister(self.registryIdentifier)
      end
    end,

    testRegister = function(self)
      local member = scs.newComponent(Hello_v2.facets, Hello_v2.receptacles,
        Hello_v2.componentId)
      -- Identificar local propositalmente
      local success, registryIdentifier = self.registryService.__try:register({
        member = member.IComponent,
        properties = Hello_v2.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(registryIdentifier)
      --
      local offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
      --
      offers = self.registryService:find({"IHello_v2"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
      --
      Check.assertFalse(self.registryService:unregister("INVALID-IDENTIFIER"))
      --
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
      offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(0, #offers)
      offers = self.registryService:find({"IHello_v2"})
      Check.assertEquals(0, #offers)
    end,

    testRegister_Property = function(self)
      local success
      local member = scs.newComponent(Hello_v2.facets, Hello_v2.receptacles,
        Hello_v2.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        member = member.IComponent,
        properties = {
          {
            name = "facets",
            value = {
              "IDL:IHello_v1:1.0",
            }
          },
        }
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      local offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(1, #offers)
      --
      offers = self.registryService:find({"IHello_v2"})
      Check.assertEquals(0, #offers)
    end,

    testRegister_NotImplemented = function(self)
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      local success, err = self.registryService.__try:register({
        member = member.IComponent,
        properties = {
          {
            name = "facets",
            value = {
              "IDL:IHello_v1:1.0",
              "IDL:IHello_v2:1.0",  -- IHello_v1 não implementa
            }
          },
        }
      })
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0")
      Check.assertEquals(#err.facets, 1)
    end,

    testRegister_Unauthorized = function(self)
      local member = scs.newComponent(Hello_v3.facets, Hello_v3.receptacles,
        Hello_v3.componentId)
      local success, err = self.registryService.__try:register({
        member = member.IComponent,
        properties = {}, -- não informa as facetas, usa IMetaInterface
      })
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0")
      Check.assertEquals(#err.facets, 1)
    end,

    testRegister_UnauthorizedProperty = function(self)
      local member = scs.newComponent(Hello_v3.facets, Hello_v3.receptacles,
        Hello_v3.componentId)
      local success, err = self.registryService.__try:register({
        member = member.IComponent,
        properties = Hello_v3.properties,
      })
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0")
      Check.assertEquals(#err.facets, 1)
    end,

    testUpdate = function(self)
      local success
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member.IComponent,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)
      --
      local offers = self.registryService:find({"IHello_v1"})
oil.verbose:print(offers)
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v1.properties))
      --
      Check.assertTrue(self.registryService.__try:update(self.registryIdentifier,
        Hello_v2.properties))
      offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testUpdate_Same = function(self)
      local success
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member.IComponent,
      })
      --
      local offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v1.properties))
      --
      Check.assertTrue(self.registryService.__try:update(self.registryIdentifier,
  Hello_v1.properties))
      --
      offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v1.properties))
    end,

    testRegister_InternalProperties = function(self)
      local success
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      -- Tenta sobrescrita de propriedade definidas internamente no RS
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = self.fakeProps,
        member = member.IComponent,
      })
      --
      local offers = self.registryService:findByCriteria(
        {"IHello_v1"}, self.trueProps)
      Check.assertEquals(1, #offers)
    end,

    testUpdate_InternalProperties = function(self)
      local success
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = self.trueProps,
        member = member.IComponent,
      })
      Check.assertTrue(success)
      -- Tenta sobrescrita de propriedade definidas internamente no RS
      Check.assertTrue(self.registryService.__try:update(self.registryIdentifier, self.fakeProps))
      --
      local offers = self.registryService:findByCriteria(
        {"IHello_v1"}, self.trueProps)
      Check.assertEquals(1, #offers)
    end,

    testUpdate_Invalid = function(self)
      -- Coloca conteúdo no registro
      local success, err
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member.IComponent,
      })
      success, err = self.registryService.__try:update("INVALID-IDENTIFIER",
        Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/registry_service/ServiceOfferNonExistent:1.0")
    end,

    testUpdate_Property = function(self)
      local success
      local member = scs.newComponent(Hello_v2.facets, Hello_v2.receptacles,
        Hello_v2.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = Hello_v2.properties,
        member = member.IComponent,
      })
      --
      success = self.registryService.__try:update(self.registryIdentifier, {
        {
          name = "facets",
          value = {
            "IDL:IHello_v1:1.0",
          }
        },
      })
      Check.assertTrue(success)
      --
      local offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(1, #offers)
      --
      offers = self.registryService:find({"IHello_v2"})
oil.verbose:print(offers)
      Check.assertEquals(0, #offers)
      --
      success = self.registryService.__try:update(self.registryIdentifier, {
        {
          name = "facets",
          value = {
            "IDL:IHello_v1:1.0",
            "IDL:IHello_v2:1.0",
          }
        },
      })
      Check.assertTrue(success)
      --
      local offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(1, #offers)
      --
      offers = self.registryService:find({"IHello_v2"})
      Check.assertEquals(1, #offers)
    end,

    testUpdate_NotImplemented = function(self)
      local success, err
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member.IComponent,
      })
      --
      success, err = self.registryService.__try:update(self.registryIdentifier, {
        {
          name = "facets",
          value = {
            "IDL:IHello_v1:1.0",
            "IDL:IHello_v2:1.0",  -- IHello_v1 não implementa
          }
        },
      })
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0")
      Check.assertEquals(#err.facets, 1)
    end,
  },

  Test2 = {
    beforeTestCase = function(self)
      init(self)
      -- Registra ofertas para o teste
      local success
      self.member_v1 = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.id_v1 = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = self.member_v1.IComponent,
      })

      --
      self.member_v2 = scs.newComponent(Hello_v2.facets, Hello_v2.receptacles,
        Hello_v2.componentId)
      success, self.id_v2 = self.registryService.__try:register({
        properties = Hello_v2.properties,
        member = self.member_v2.IComponent,
      })

      Check.assertNotEquals(self.id_v1, self.id_v2)
    end,

    afterTestCase = function(self)
      Check.assertTrue(self.registryService:unregister(self.id_v1))
      Check.assertTrue(self.registryService:unregister(self.id_v2))
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

    testFindByName_NotFound = function(self)
      local offers = self.registryService:find({"IServiceNotRegistered"})
      Check.assertEquals(0, #offers)
    end,

    testFindByName = function(self)
      local offers = self.registryService:find({"IHello_v2"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByName_MoreResults = function(self)
      local offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, Hello_v1.properties) or
        equalsProps(offers[2].properties, Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, Hello_v2.properties) or
        equalsProps(offers[2].properties, Hello_v2.properties))
      )
    end,

    testFindByName_List = function(self)
      local offers = self.registryService:find({"IHello_v1","IHello_v2"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindbyInterfaceName_NotFound = function(self)
      local offers = self.registryService:find({"IDL:service/not/registered/:1.0"})
      Check.assertEquals(0, #offers)
    end,

    testFindbyInterfaceName = function(self)
      offers = self.registryService:find({"IDL:IHello_v2:1.0"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindbyInterfaceName_MoreResults = function(self)
      local offers = self.registryService:find({"IDL:IHello_v1:1.0"})
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, Hello_v1.properties) or
        equalsProps(offers[2].properties, Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, Hello_v2.properties) or
        equalsProps(offers[2].properties, Hello_v2.properties))
      )
    end,

    testFindbyInterfaceName_List = function(self)
      local offers = self.registryService:find({"IDL:IHello_v1:1.0","IDL:IHello_v2:1.0"})
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Equals = function(self)
      local offers = self.registryService:findByCriteria(
        {"IHello_v1"}, Hello_v1.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v1.properties))
      --
      offers = self.registryService:findByCriteria(
        {"IHello_v1", "IHello_v2"}, Hello_v2.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Facet_One = function(self)
      local offers = self.registryService:findByCriteria(
        {"IHello_v1"},
        {
          {name = "version", value = {"1.0", "2.0"}}
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Empty = function(self)
      local offers = self.registryService:findByCriteria(
        {"IHello_v1"},
        {
          {name = "bugs", value = {}}
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, Hello_v1.properties) or
        equalsProps(offers[2].properties, Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, Hello_v2.properties) or
        equalsProps(offers[2].properties, Hello_v2.properties))
      )
    end,

    testFindByCriteria_Facet_Any = function(self)
      local offers = self.registryService:findByCriteria(
        {"IHello_v1"},
        {
          {name = "version", value = {"1.0"}}
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, Hello_v1.properties) or
        equalsProps(offers[2].properties, Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, Hello_v2.properties) or
        equalsProps(offers[2].properties, Hello_v2.properties))
      )
    end,

    testFindByCriteria_Facet_ComponentId = function(self)
      local componentId = Hello_v1.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local offers = self.registryService:findByCriteria(
        {"IHello_v1"},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v1.properties))
    end,

    testFindByCriteria_Facet_ComponentId_MoreComponents = function(self)
      local componentId = Hello_v2.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local offers = self.registryService:findByCriteria(
        {"IHello_v1"},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Interface_Equals = function(self)
      local offers = self.registryService:findByCriteria(
        {"IDL:IHello_v1:1.0"}, Hello_v1.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v1.properties))
      --
      offers = self.registryService:findByCriteria(
        {"IDL:IHello_v1:1.0", "IDL:IHello_v2:1.0"}, Hello_v2.properties)
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Interface_One = function(self)
      local offers = self.registryService:findByCriteria(
        {"IDL:IHello_v1:1.0"},
        {
          {name = "version", value = {"1.0", "2.0"}}
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Interface_Empty = function(self)
      local offers = self.registryService:findByCriteria(
        {"IDL:IHello_v1:1.0"},
        {
          {name = "bugs", value = {}}
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, Hello_v1.properties) or
        equalsProps(offers[2].properties, Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, Hello_v2.properties) or
        equalsProps(offers[2].properties, Hello_v2.properties))
      )
    end,

    testFindByCriteria_Interface_Any = function(self)
      local offers = self.registryService:findByCriteria(
        {"IDL:IHello_v1:1.0"},
        {
          {name = "version", value = {"1.0"}}
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, Hello_v1.properties) or
        equalsProps(offers[2].properties, Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, Hello_v2.properties) or
        equalsProps(offers[2].properties, Hello_v2.properties))
      )
    end,

    testFindByCriteria_Interface_ComponentId = function(self)
      local componentId = Hello_v2.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local offers = self.registryService:findByCriteria(
        {"IDL:IHello_v1:1.0"},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Interface_ComponentId_MoreComponents = function(self)
      local componentId = Hello_v2.componentId
      local compId = componentId.name..":"..componentId.major_version.. "."
        .. componentId.minor_version.."."..componentId.patch_version
      local offers = self.registryService:findByCriteria(
        {"IDL:IHello_v1:1.0"},
        {
          {name = "component_id", value = {compId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Owner = function(self)
      local offers = self.registryService:findByCriteria(
        {"IHello_v2"},
        {
          {name = "registered_by", value = {deploymentId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Facet_Owner_MoreResults = function(self)
      local offers = self.registryService:findByCriteria(
        {"IHello_v1"},
        {
          {name = "registered_by", value = {deploymentId}},
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, Hello_v1.properties) or
        equalsProps(offers[2].properties, Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, Hello_v2.properties) or
        equalsProps(offers[2].properties, Hello_v2.properties))
      )
    end,

    testFindByCriteria_Facet_Owner_NotFound = function(self)
      local offers = self.registryService:findByCriteria(
        {"InvalidFacet"},
        {
          {name = "registered_by", value = {deploymentId}},
        }
      )
      Check.assertEquals(0, #offers)
    end,

    testFindByCriteria_Interface_Owner = function(self)
      local offers = self.registryService:findByCriteria(
        {"IDL:IHello_v2:1.0"},
        {
          {name = "registered_by", value = {deploymentId}},
        }
      )
      Check.assertEquals(1, #offers)
      Check.assertTrue(equalsProps(offers[1].properties, Hello_v2.properties))
    end,

    testFindByCriteria_Interface_Owner_MoreResults = function(self)
      local offers = self.registryService:findByCriteria(
        {"IDL:IHello_v1:1.0"},
        {
          {name = "registered_by", value = {deploymentId}},
        }
      )
      Check.assertEquals(2, #offers)
      -- Expressão válida pois v1.properties ~= v2.properties
      Check.assertTrue(
       (equalsProps(offers[1].properties, Hello_v1.properties) or
        equalsProps(offers[2].properties, Hello_v1.properties))
       and
       (equalsProps(offers[1].properties, Hello_v2.properties) or
        equalsProps(offers[2].properties, Hello_v2.properties))
      )
    end,

    testFindByCriteria_Interface_Owner_NotFound = function(self)
      local offers = self.registryService:findByCriteria(
        {"IDL:InvalidFacet:1.0"},
        {
          {name = "registered_by", value = {deploymentId}},
        }
      )
      Check.assertEquals(0, #offers)
    end,
  },

  Test3 = {
    beforeTestCase = init,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

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
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      local success, err = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member.IComponent,
      })
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testFind_NoCredential = function(self)
      local success
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.registryService.__try:find({"IHello_v1"})
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testUpdate_NoCredential = function(self)
      local success
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.registryService.__try:update(self.registryIdentifier,
        Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testFindByCriteria_NoCredential = function(self)
      local success
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.registryService.__try:findByCriteria(
  {"IHello_v1"}, Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testUnregister_NoCredential = function(self)
      local success
      local member = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, self.registryIdentifier = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.registryService.__try:unregister(
        self.registryIdentifier)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,
  },

  Test4 = {
    beforeTestCase = init,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

    testLogout = function(self)
      local success, member_v1, member_v2, id_v1, id_v2
      member_v1 = scs.newComponent(Hello_v1.facets, Hello_v1.receptacles,
        Hello_v1.componentId)
      success, id_v1 = self.registryService.__try:register({
        properties = Hello_v1.properties,
        member = member_v1.IComponent,
      })
      --
      member_v2 = scs.newComponent(Hello_v2.facets, Hello_v2.receptacles,
        Hello_v2.componentId)
      success, id_v2 = self.registryService.__try:register({
        properties = Hello_v2.properties,
        member = member_v2.IComponent,
      })
      -- Registro deve ser limpo
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      socket.sleep(3)
      -- Faz login novamente
      init(self)
      --
      local offers = self.registryService:find({"IHello_v1"})
      Check.assertEquals(0, #offers)
    end,
  },
}
