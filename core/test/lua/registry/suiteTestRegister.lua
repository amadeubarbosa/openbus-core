--
-- Teste unitário do operacao 'register' do Serviço de Registro
--
--
local oil = require "oil"
local orb = oil.orb
local oop = require "loop.base"
local print = print
local string = string

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local Utils = require "openbus.util.Utils"

local scs = require "scs.core.base"

local Check = require "latt.Check"
local ltime = tostring(socket.gettime())
ltime = string.gsub(ltime, "%.", "")
-------------------------------------------------------------------------------
-- Informações sobre os componentes usados nos testes
--

-- Interfaces

local IDL = {
  "interface IHello_v1_"..ltime.." { };",
  "interface IHello_v2_"..ltime.." { };",
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
      name = "IHello_v1_"..ltime,
      interface_name = "IDL:IHello_v1_"..ltime..":1.0",
      class = oop.class({}),
    },
  },
  -- ComponentId
  componentId = {
    name = "Hello_v1_"..ltime,
    major_version = 1,
    minor_version = 0,
    patch_version = 0,
    platform_spec = "",
  },
  -- Propriedades para o registro.
  -- Alguns testes levam em consideração que as propriedades dos dois
  -- componentes são diferentes.
  properties = {
    {name = "type",        value = {"IHello"..ltime}},
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
      name = "IHello_v1_"..ltime,
      interface_name = "IDL:IHello_v1_"..ltime..":1.0",
      class = oop.class({}),
    },
    IHello_v2 = {
      name = "IHello_v2_"..ltime,
      interface_name = "IDL:IHello_v2_"..ltime..":1.0",
      class = oop.class({}),
    },
  },
  -- ComponentId
  componentId = {
    name = "Hello_v2_"..ltime,
    major_version = 1,
    minor_version = 0,
    patch_version = 0,
    platform_spec = "",
  },
  -- Propriedades para o registro.
  -- Alguns testes levam em consideração que as propriedades dos dois
  -- componentes são diferentes.
  properties = {
    {name = "type",        value = {"IHello"..ltime}},
    {name = "description", value = {"IHello versões 1.0 e 2.0"}},
    -- Teste de múltiplos valores
    {name = "version",     value = {"1.0", "2.0"}},
    -- Teste de propriedade vazia
    {name = "bugs",        value = {}},
  },
}


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
  local acsComp = orb:newproxy("corbaloc::localhost:2089/openbus_v1_05",nil,
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
  local challenge = self.accessControlService:getChallenge(self.deploymentId)
  local privateKey = lce.key.readprivatefrompemfile(self.testKeyFile)
  challenge = lce.cipher.decrypt(privateKey, challenge)
  cert = lce.x509.readfromderfile(self.acsCertFile)
  challenge = lce.cipher.encrypt(cert:getpublickey(), challenge)
  local succ
  succ, self.credential, self.lease =
    self.accessControlService:loginByCertificate(self.deploymentId, challenge)
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
  self.rgsProtected = orb:newproxy(self.registryService, "protected")
end


local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
local beforeTestCase = dofile(OPENBUS_HOME .."/core/test/lua/registry/beforeTestCaseFTRGS.lua")
local afterTestCase = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterTestCase.lua")

-------------------------------------------------------------------------------

Suite = {
  Test1 = {
    beforeTestCase = beforeTestCase,

    beforeEachTest = function(self)
      init(self)
      self.registryIdentifier = nil
    end,

    afterTestCase = afterTestCase,

    afterEachTest = function(self)
      if self.registryIdentifier then
        self.registryService:unregister(self.registryIdentifier)
      end

      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

    testRegister = function(self)
      local member = scs.newComponent(Hello_v2.facets, Hello_v2.receptacles,
        Hello_v2.componentId)
      -- Identificar local propositalmente
      local success
      sucess, self.registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = Hello_v2.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)

      local offers = self.registryService:find({"IHello_v2_"..ltime})
      Check.assertEquals(1, #offers)
      --
    end,
  },
}

return Suite
