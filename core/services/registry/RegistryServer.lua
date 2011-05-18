-----------------------------------------------------------------------------
-- Inicialização do Serviço de Registro
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local tonumber = tonumber
local tostring = tostring

local string = string
local format = string.format

local oil = require "oil"
local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"
local Audit = require "openbus.util.Audit"
local Utils = require "openbus.util.Utils"

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/RegistryServerConfiguration.lua"))()
local rsConfig = RegistryServerConfiguration
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
  rsConfig.logs.service.level = 5
  rsConfig.logs.oil.level = 5
end
if arguments.port then
  rsConfig.registryServerHostPort = tonumber(arguments.port)
end

-- Configurando os logs
Log:level(rsConfig.logs.service.level)
Audit:level(rsConfig.logs.audit.level)
oil.verbose:level(rsConfig.logs.oil.level)

local serviceLogFile
if rsConfig.logs.service.file then
  local errMsg
  serviceLogFile, errMsg = Utils.setVerboseOutputFile(Log,
      rsConfig.logs.service.file)
  if not serviceLogFile then
    Log:error(format(
        "Falha ao abrir o arquivo de log do serviço de controle de acesso: %s",
        tostring(errMsg)))
  end
end

local auditLogFile
if rsConfig.logs.audit.file then
  local errMsg
  auditLogFile, errMsg = Utils.setVerboseOutputFile(Audit,
      rsConfig.logs.audit.file)
  if not auditLogFile then
    Log:error(format(
        "Falha ao abrir o arquivo de auditoria: %s", tostring(errMsg)))
  end
end

local oilLogFile
if rsConfig.logs.oil.file then
  local errMsg
  oilLogFile, errMsg =
      Utils.setVerboseOutputFile(oil.verbose, rsConfig.logs.oil.file)
  if not oilLogFile then
    Log:error(format(
        "Falha ao abrir o arquivo de log do OiL: %s",
        tostring(errMsg)))
  end
end

local props = {  host = RegistryServerConfiguration.registryServerHostName,
           port =  tonumber(RegistryServerConfiguration.registryServerHostPort)}

local TestLog = require "openbus.util.TestLog"
local tests = {}
tests[Utils.REGISTRY_SERVICE_KEY] = TestLog()
tests[Utils.REGISTRY_SERVICE_KEY_PREV] = TestLog()
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
local RegistryServicePrev = require "core.services.registry.RegistryService_Prev"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

-----------------------------------------------------------------------------
---- RegistryService Descriptions
-------------------------------------------------------------------------------

---- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent                 = {}
facetDescriptions.IRegistryService           = {}
facetDescriptions.IRegistryService_Prev      = {}
facetDescriptions.IManagement                = {}
facetDescriptions.IManagement_Prev           = {}
facetDescriptions.IFaultTolerantService      = {}
facetDescriptions.IFaultTolerantService_Prev = {}
facetDescriptions.IReceptacles               = {}

facetDescriptions.IComponent.name                  = "IComponent"
facetDescriptions.IComponent.interface_name        = Utils.COMPONENT_INTERFACE
facetDescriptions.IComponent.class                 = scs.Component
facetDescriptions.IComponent.key                   = "IC"

facetDescriptions.IRegistryService.name            = "IRegistryService_" .. Utils.OB_VERSION
facetDescriptions.IRegistryService.interface_name  = Utils.REGISTRY_SERVICE_INTERFACE
facetDescriptions.IRegistryService.class           = RegistryService.RSFacet
facetDescriptions.IRegistryService.key             = Utils.REGISTRY_SERVICE_KEY

facetDescriptions.IRegistryService_Prev.name            = "IRegistryService_" .. Utils.OB_PREV
facetDescriptions.IRegistryService_Prev.interface_name  = Utils.REGISTRY_SERVICE_INTERFACE_PREV
facetDescriptions.IRegistryService_Prev.class           = RegistryServicePrev.RSFacet
facetDescriptions.IRegistryService_Prev.key             = Utils.REGISTRY_SERVICE_KEY_PREV

facetDescriptions.IFaultTolerantService.name            = "IFaultTolerantService_" .. Utils.OB_VERSION
facetDescriptions.IFaultTolerantService.interface_name  = Utils.FAULT_TOLERANT_SERVICE_INTERFACE
facetDescriptions.IFaultTolerantService.class           = RegistryService.FaultToleranceFacet
facetDescriptions.IFaultTolerantService.key             = Utils.FAULT_TOLERANT_RS_KEY

facetDescriptions.IFaultTolerantService_Prev.name            = "IFaultTolerantService_" .. Utils.OB_PREV
facetDescriptions.IFaultTolerantService_Prev.interface_name  = Utils.FAULT_TOLERANT_SERVICE_INTERFACE_PREV
facetDescriptions.IFaultTolerantService_Prev.class           = RegistryServicePrev.FaultToleranceFacet
facetDescriptions.IFaultTolerantService_Prev.key             = Utils.FAULT_TOLERANT_RS_KEY_PREV

facetDescriptions.IManagement.name            = "IManagement_" .. Utils.OB_VERSION
facetDescriptions.IManagement.interface_name  = Utils.MANAGEMENT_RS_INTERFACE
facetDescriptions.IManagement.class           = RegistryService.ManagementFacet
facetDescriptions.IManagement.key             = Utils.MANAGEMENT_RS_KEY

facetDescriptions.IManagement_Prev.name            = "IManagement_" .. Utils.OB_PREV
facetDescriptions.IManagement_Prev.interface_name  = Utils.MANAGEMENT_RS_INTERFACE_PREV
facetDescriptions.IManagement_Prev.class           = RegistryServicePrev.ManagementFacet
facetDescriptions.IManagement_Prev.key             = Utils.MANAGEMENT_RS_KEY_PREV

facetDescriptions.IReceptacles.name           = "IReceptacles"
facetDescriptions.IReceptacles.interface_name = Utils.RECEPTACLES_INTERFACE
facetDescriptions.IReceptacles.class          = RegistryService.RGSReceptacleFacet

-- Receptacle Descriptions
local receptacleDescs = {}
receptacleDescs.AccessControlServiceReceptacle = {}
receptacleDescs.AccessControlServiceReceptacle.name           = "AccessControlServiceReceptacle"
receptacleDescs.AccessControlServiceReceptacle.interface_name = Utils.COMPONENT_INTERFACE
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
    Log:error(string.format("Falha ao iniciar o serviço de registro: %s\n",
        tostring(res)))
    os.exit(1)
  end

  Log:info("O serviço de registro foi iniciado com sucesso")
  Audit:uptime("O serviço de registro foi iniciado com sucesso")
end

local status, errMsg = oil.pcall(oil.main,main)
if not status then
  Log:error(format(
      "Ocorreu uma falha na execução do serviço de registro: %s",
      tostring(errMsg)))
end

if serviceLogFile then
  serviceLogFile:close()
end
if auditLogFile then
  auditLogFile:close()
end
if oilLogFile then
  oilLogFile:close()
end
