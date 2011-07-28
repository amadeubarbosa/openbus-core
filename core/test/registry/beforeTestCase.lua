local oop = require "loop.base"
local print = print
local tostring = tostring

require "oil"
local orb = oil.orb

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local Utils = require "openbus.util.Utils"

local ltime = tostring(socket.gettime())
ltime = string.gsub(ltime, "%.", "")
-------------------------------------------------------------------------------
-- Informações sobre os componentes usados nos testes
--

-- Interfaces

local IDL = {
  "interface IHello_v1_"..ltime.." { };",
  "interface IHello_v2_"..ltime.." { };",
  "interface IHello_v3_"..ltime.." { };",
}

-- Descrições

local Hello_v1  = {
  -- Descrição dos receptáculos
  receptacles = {},
  -- Descrição das facetas
  facets = {
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

local Hello_v2_2  = {
  -- Descrição dos receptáculos
  receptacles = {},
  -- Descrição das facetas
  facets = {
    IHello_v2 = {
      name = "IHello_v2_"..ltime,
      interface_name = "IDL:IHello_v2_"..ltime..":1.0",
      class = oop.class({}),
    },
    IHello_v2_2 = {
      name = "IHello_v2_2_"..ltime,
      interface_name = "IDL:IHello_v2_"..ltime..":1.0",
      class = oop.class({}),
    },
  },
  -- ComponentId
  componentId = {
    name = "Hello_v2_2_"..ltime,
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
    {name = "description", value = {"IHello com duas facetas IHello v2.0"}},
  },
}

local Hello_v3  = {
  -- Descrição dos receptáculos
  receptacles = {},
  -- Descrição das facetas
  facets = {
    IHello_v1 = {
      name = "IHello_v1_"..ltime,
      interface_name = "IDL:IHello_v1_"..ltime..":1.0",
      class = oop.class({}),
    },
    IHello_v2 = {
      name = "IHello_v2",
      interface_name = "IDL:IHello_v2_"..ltime..":1.0",
      class = oop.class({}),
    },
    IHello_v3 = { -- Não autorizada no RS
      name = "IHello_v3",
      interface_name = "IDL:IHello_v3_"..ltime..":1.0",
      class = oop.class({}),
    },
  },
  -- ComponentId
  componentId = {
    name = "Hello_v3_"..ltime,
    major_version = 1,
    minor_version = 0,
    patch_version = 0,
    platform_spec = "",
  },
  properties = {
    {name = "type",        value = {"IHello"}},
    {name = "description", value = {"IHello versões 1.0, 2.0 e 3.0"}},
    -- Teste de múltiplos valores
    {name = "version",     value = {"1.0", "2.0", "3.0"}},
    -- Teste de propriedade vazia
    {name = "bugs",        value = {}},
  },
}

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
if OPENBUS_HOME == nil then
  io.stderr:write("A variavel OPENBUS_HOME nao foi definida.\n")
  os.exit(1)
end
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  io.stderr:write("A variavel DATA_DIR nao foi definida.\n")
  os.exit(1)
end
local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end

function loadidls()
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/registry_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_PREV.."/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_PREV.."/registry_service.idl")

  for _, idl in ipairs(IDL) do
    orb:loadidl(idl)
  end
end

local Before = oop.class()

-- Inicializa as referências para o OpenBus em cada teste
function Before:init()
  self.Hello_v1 = Hello_v1
  self.Hello_v2 = Hello_v2
  self.Hello_v2_2 = Hello_v2_2
  self.Hello_v3 = Hello_v3

  --Propriedades usadas nos testes Register_InternalProperties e
  -- Update_InternalProperties
  self.fakeProps = {
        {name = "component_id",  value = {"DoNotExists:8.8.8"}},
        {name = "registered_by", value = {"DoNotExists"}},
      }
  self.trueProps = {
        {name = "component_id",
         value = {string.format(
                    "%s:%d.%d.%d",
                    self.Hello_v1.componentId.name,
                    self.Hello_v1.componentId.major_version,
                    self.Hello_v1.componentId.minor_version,
                    self.Hello_v1.componentId.patch_version)
                 }
        },
        {name = "registered_by", value = {self.deploymentId}},
      }

  assert(loadfile(OPENBUS_HOME.."/data/conf/AccessControlServerConfiguration.lua"))()
  -- Recupera o Serviço de Acesso
  local acsComp = orb:newproxy("corbaloc::"..
      AccessControlServerConfiguration.hostName..":"..
      AccessControlServerConfiguration.hostPort.."/"..Utils.OPENBUS_KEY, nil,
      Utils.COMPONENT_INTERFACE)
  local facet = acsComp:getFacet(Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
  self.accessControlService = orb:narrow(facet,
      Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
  -- instala o interceptador de cliente
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  local config = assert(loadfile(
    DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
  self.credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config,
    self.credentialManager))
  -- Login do serviço para a realização do teste
  local challenge = self.accessControlService:getChallenge(self.deploymentId)
  local privateKey = assert(lce.key.readprivatefrompemfile(self.testKeyFile),
      string.format("Arquivo '%s' não encontrado.",self.testKeyFile))
  challenge = lce.cipher.decrypt(privateKey, challenge)
  cert = assert(lce.x509.readfromderfile(self.acsCertFile),
                string.format("Arquivo '%s' não encontrado.",self.acsCertFile))
  challenge = lce.cipher.encrypt(cert:getpublickey(), challenge)
  local succ
  succ, self.credential, self.lease =
    self.accessControlService:loginByCertificate(self.deploymentId, challenge)
  self.credentialManager:setValue(self.credential)

  -- Recupera o Serviço de Registro
  local acsIComp = self.accessControlService:_component()
  acsIComp = orb:narrow(acsIComp, Utils.COMPONENT_INTERFACE)
  local acsIRecept = acsIComp:getFacetByName("IReceptacles")
  acsIRecept = orb:narrow(acsIRecept, "IDL:scs/core/IReceptacles:1.0")
  local conns = acsIRecept:getConnections("RegistryServiceReceptacle")
  local rsIComp = orb:narrow(conns[1].objref, "IDL:scs/core/IComponent:1.0")
  self.registryService = rsIComp:getFacetByName("IRegistryService_"..
      Utils.IDL_VERSION)
  self.registryService = orb:narrow(self.registryService,
      Utils.REGISTRY_SERVICE_INTERFACE)
  self.rgsProtected = orb:newproxy(self.registryService, "protected")
  self.registryIdentifier = nil
end

function Before:beforeTestCase()

  loadidls()

  -- Obtém a configuração do serviço
  assert(loadfile(OPENBUS_HOME.."/data/conf/AccessControlServerConfiguration.lua"))()
  self.acsHostName = AccessControlServerConfiguration.hostName
  self.acsHostPort = AccessControlServerConfiguration.hostPort

  self.systemId     = "TesteBarramento".. ltime
  self.deploymentId = self.systemId
  self.testKeyFile  = self.systemId .. ".key"
  self.acsCertFile  = DATA_DIR.."/certificates/AccessControlService.crt"
  local testACSCertFile = assert(io.open(self.acsCertFile,"r"),
                  string.format("Arquivo '%s' não encontrado.",self.acsCertFile))
  testACSCertFile:close()

  os.execute(OPENBUS_HOME.."/specs/shell/openssl-generate.ksh -n " .. self.systemId .. " -c "..OPENBUS_HOME.."/openssl/openssl.cnf <TesteBarramentoCertificado_input.txt  2> genkey-err.txt >genkeyT.txt ")

  os.execute(OPENBUS_HOME.."/bin/run_management.sh --acs-host=" .. self.acsHostName ..
                                                      " --acs-port=" .. self.acsHostPort  ..
                                                      " --login=tester" ..
                                                      " --password=tester" ..
                                                      " --add-system="..self.systemId ..
                                                      " --description=Teste_do_OpenBus" ..
                                                      " 2>> management-err.txt >>management.txt ")

  os.execute(OPENBUS_HOME.."/bin/run_management.sh --acs-host=" .. self.acsHostName ..
                                                      " --acs-port=" .. self.acsHostPort..
                                                      " --login=tester" ..
                                                      " --password=tester" ..
                                                      " --add-deployment="..self.deploymentId ..
                                                      " --system="..self.systemId ..
                                                      " --description=Teste_do_Barramento" ..
                                                      " --certificate="..self.systemId..".crt"..
                                                      " 2>> management-err.txt >>management.txt ")

  os.execute(OPENBUS_HOME.."/bin/run_management.sh --acs-host=" .. self.acsHostName ..
                                                      " --acs-port=" .. self.acsHostPort ..
                                                      " --login=tester" ..
                                                      " --password=tester" ..
                                                      " --set-authorization="..self.systemId ..
                                                      " --grant='IDL:IHello_v1_"..ltime..":1.0'  --no-strict"..
                                                      " 2>> management-err.txt >>management.txt ")

  os.execute(OPENBUS_HOME.."/bin/run_management.sh --acs-host=" .. self.acsHostName ..
                                                      " --acs-port=" .. self.acsHostPort ..
                                                      " --login=tester" ..
                                                      " --password=tester" ..
                                                      " --set-authorization="..self.systemId ..
                                                      " --grant='IDL:IHello_v2_"..ltime..":1.0'  --no-strict"..
                                                      " 2>> management-err.txt >>management.txt ")


  Before.init(self)

end

return Before
