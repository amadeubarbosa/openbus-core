-----------------------------------------------------------------------------
-- Inicialização do Serviço de Registro
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local tonumber = tonumber

local oil = require "oil"
local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"
local Utils = require "openbus.util.Utils"
local Viewer = require "loop.debug.Viewer"

-- Inicialização do nível de verbose do openbus.
Log:level(1)

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/RegistryServerConfiguration.lua"))()
local iConfig =
  assert(loadfile(DATA_DIR.."/conf/advanced/RSInterceptorsConfiguration.lua"))()

-- Parsing arguments
local usage_msg = [[
  --help                   : show this help
  --verbose  (v)           : turn ON the VERBOSE mode (show the system commands)
  --port=<port number>     : defines the service port (default=]]
                .. tostring(RegistryServerConfiguration.registryServerHostPort) .. [[)
 NOTES:
  The prefix '--' is optional in all options.
  So '--help' or '-help' or yet 'help' all are the same option.]]
local arguments = Utils.parse_args(arg,usage_msg,true)

if arguments.verbose == "" or arguments.v == "" then
  oil.verbose:level(5)
  Log:level(5)
else
  if RegistryServerConfiguration.oilVerboseLevel then
      oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel)
  end
  -- Define os níveis de verbose para o openbus e para o oil
  if RegistryServerConfiguration.logLevel then
    Log:level(RegistryServerConfiguration.logLevel)
  end
end

if arguments.port then
  RegistryServerConfiguration.registryServerHostPort = tonumber(arguments.port)
end

props = {  host = RegistryServerConfiguration.registryServerHostName,
           port =  tonumber(RegistryServerConfiguration.registryServerHostPort)}

local TestLog = require "openbus.util.TestLog"
local tests = {}
tests[Utils.REGISTRY_SERVICE_KEY] = TestLog()
tests[Utils.REGISTRY_SERVICE_KEY_V1_04] = TestLog()
tests[Utils.FAULT_TOLERANT_RS_KEY] = TestLog()
local logfile
for key, v in pairs(tests) do
  v:level(1)
  logfile = assert(io.open(DATA_DIR.."/rgs-performance-".. key ..".log", "w"))
  if not logfile then
    Log:error("O arquivo do log de desempenho ["..DATA_DIR.."/rgs-performance-".. key ..".log] nao existe.\n")
  else
    v.viewer.output = logfile
  end
end
iConfig.tests = tests

-- Inicializa o barramento
Openbus:init(RegistryServerConfiguration.accessControlServerHostName,
  RegistryServerConfiguration.accessControlServerHostPort,
  props, iConfig, iConfig, "CACHED")

Openbus:enableFaultTolerance()

local orb = Openbus:getORB()

local scs = require "scs.core.base"
local RegistryService = require "core.services.registry.RegistryService"
local RegistryService_v1_04 = require "core.services.registry.RegistryService_v1_04"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

-----------------------------------------------------------------------------
---- RegistryService Descriptions
-------------------------------------------------------------------------------

---- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent       = {}
facetDescriptions.IMetaInterface   = {}
facetDescriptions.IRegistryService = {}
facetDescriptions.IRegistryService_Prev = {}
facetDescriptions.IManagement      = {}
facetDescriptions.IFaultTolerantService = {}
facetDescriptions.IReceptacles          = {}

facetDescriptions.IComponent.name                  = "IComponent"
facetDescriptions.IComponent.interface_name        = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                 = scs.Component
facetDescriptions.IComponent.key                   = "IC"

facetDescriptions.IMetaInterface.name              = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name    = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class             = scs.MetaInterface

facetDescriptions.IRegistryService.name            = "IRegistryService_v" .. Utils.OB_VERSION
facetDescriptions.IRegistryService.interface_name  = Utils.REGISTRY_SERVICE_INTERFACE
facetDescriptions.IRegistryService.class           = RegistryService.RSFacet
facetDescriptions.IRegistryService.key             = Utils.REGISTRY_SERVICE_KEY

facetDescriptions.IRegistryService_Prev.name            = "IRegistryService"
facetDescriptions.IRegistryService_Prev.interface_name  = Utils.REGISTRY_SERVICE_INTERFACE_V1_04
facetDescriptions.IRegistryService_Prev.class           = RegistryService_v1_04.RSFacet
facetDescriptions.IRegistryService_Prev.key             = Utils.REGISTRY_SERVICE_KEY_V1_04

facetDescriptions.IFaultTolerantService.name            = "IFaultTolerantService_v" .. Utils.OB_VERSION
facetDescriptions.IFaultTolerantService.interface_name  = Utils.FAULT_TOLERANT_SERVICE_INTERFACE
facetDescriptions.IFaultTolerantService.class           = RegistryService.FaultToleranceFacet
facetDescriptions.IFaultTolerantService.key             = Utils.FAULT_TOLERANT_RS_KEY

facetDescriptions.IManagement.name            = "IManagement_v" .. Utils.OB_VERSION
facetDescriptions.IManagement.interface_name  = Utils.MANAGEMENT_RS_INTERFACE
facetDescriptions.IManagement.class           = RegistryService.ManagementFacet
facetDescriptions.IManagement.key             = Utils.MANAGEMENT_KEY

facetDescriptions.IReceptacles.name           = "IReceptacles"
facetDescriptions.IReceptacles.interface_name = "IDL:scs/core/IReceptacles:1.0"
facetDescriptions.IReceptacles.class          = AdaptiveReceptacle.AdaptiveReceptacleFacet

-- Receptacle Descriptions
local receptacleDescs = {}
receptacleDescs.AccessControlServiceReceptacle = {}
receptacleDescs.AccessControlServiceReceptacle.name           = "AccessControlServiceReceptacle"
receptacleDescs.AccessControlServiceReceptacle.interface_name =  "IDL:scs/core/IComponent:1.0"
receptacleDescs.AccessControlServiceReceptacle.is_multiplex   = true


---- component id
local componentId = {}
componentId.name = "RegistryService"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  -- Cria o componente responsável pelo Serviço de Registro
  rsInst = scs.newComponent(facetDescriptions, receptacleDescs, componentId)

  -- Configuracoes
  rsInst.IComponent.startup = RegistryService.startup
  rsInst.IComponent.shutdown = RegistryService.shutdown

  local rs = rsInst.IRegistryService
  rs.config = RegistryServerConfiguration

  success, res = oil.pcall (rsInst.IComponent.startup, rsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o serviço de registro: "..tostring(res[1]).."\n")
    os.exit(1)
  end

  Log:init("Serviço de registro iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
