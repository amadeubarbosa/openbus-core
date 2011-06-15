-- $Id$

---
--Inicializa��o do Servi�o de Controle de Acesso
---
local string = string
local format = string.format
local tostring = tostring
local oil = require "oil"

local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"
local Audit = require "openbus.util.Audit"
local Utils = require "openbus.util.Utils"
local TableDB = require "openbus.util.TableDB"

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  Log:error("A vari�vel IDLPATH_DIR n�o foi definida")
  os.exit(1)
end

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A vari[avel OPENBUS_DATADIR n�o foi definida")
  os.exit(1)
end

local dbfile = DATA_DIR .. "/acs_connections.db"

-- Obt�m a configura��o do servi�o
assert(loadfile(DATA_DIR.."/conf/AccessControlServerConfiguration.lua"))()
local acsConfig = AccessControlServerConfiguration
local iconfig = assert(loadfile(DATA_DIR ..
  "/conf/advanced/ACSInterceptorsConfiguration.lua"))()

-- Parsing arguments
local usage_msg = [[
    --help                   : show this help
    --verbose (v)            : turn ON the VERBOSE mode (show the system commands)
    --port=<port number>     : defines the service port (default=]]
                                .. tostring(AccessControlServerConfiguration.hostPort) .. [[)
 NOTES:
    The prefix '--' is optional in all options.
    So '--help' or '-help' or yet 'help' all are the same option.]]
local arguments = Utils.parse_args(arg,usage_msg,true)

if arguments.verbose == "" or arguments.v == "" then
  acsConfig.logs.service.level = 5
  acsConfig.logs.oil.level = 5
end
if arguments.port then
  acsConfig.hostPort = tonumber(arguments.port)
end

-- Configurando os logs
Log:level(acsConfig.logs.service.level)
Audit:level(acsConfig.logs.audit.level)
oil.verbose:level(acsConfig.logs.oil.level)

local serviceLogFile
if acsConfig.logs.service.file then
  local errMsg
  serviceLogFile, errMsg = Utils.setVerboseOutputFile(Log,
      acsConfig.logs.service.file)
  if not serviceLogFile then
    Log:error(format(
        "Falha ao abrir o arquivo de log do servi�o de controle de acesso: %s",
        tostring(errMsg)))
  end
end

local auditLogFile
if acsConfig.logs.audit.file then
  local errMsg
  auditLogFile, errMsg = Utils.setVerboseOutputFile(Audit,
      acsConfig.logs.audit.file)
  if not auditLogFile then
    Log:error(format(
        "Falha ao abrir o arquivo de auditoria: %s", tostring(errMsg)))
  end
end

local oilLogFile
if acsConfig.logs.oil.file then
  local errMsg
  oilLogFile, errMsg =
      Utils.setVerboseOutputFile(oil.verbose, acsConfig.logs.oil.file)
  if not oilLogFile then
    Log:error(format(
        "Falha ao abrir o arquivo de log do OiL: %s",
        tostring(errMsg)))
  end
end

function exitServer(files, status)
  for _, file in ipairs(files) do
    file:close()
  end
  os.exit(status or 0)
end


local props = { host = AccessControlServerConfiguration.hostName,
  port = AccessControlServerConfiguration.hostPort}

local TestLog = require "openbus.util.TestLog"
local tests = {}
tests[Utils.OPENBUS_KEY] = TestLog()
tests[Utils.ACCESS_CONTROL_SERVICE_KEY] = TestLog()
tests[Utils.ACCESS_CONTROL_SERVICE_KEY_PREV] = TestLog()
tests[Utils.LEASE_PROVIDER_KEY] = TestLog()
tests[Utils.LEASE_PROVIDER_KEY_PREV] = TestLog()
tests[Utils.FAULT_TOLERANT_ACS_KEY] = TestLog()

for key, v in pairs(tests) do
  v:level(1)
  local logfile = assert(io.open(DATA_DIR.."/acs-performance-".. key ..".log", "w"))
  if not logfile then
    Log:error("O arquivo do log de desempenho ["..DATA_DIR.."/acs-performance-".. key ..".log] nao existe.\n")
  else
    v.viewer.output = logfile
  end
end
iconfig.tests = tests

-- Inicializa o barramento
if not (Openbus:init(AccessControlServerConfiguration.hostName,
    AccessControlServerConfiguration.hostPort, props, iconfig)) then
  Log:error("O OpenBus n�o foi inicializado")
  exitServer({serviceLogFile, auditLogFile, OiLLogFile}, -1)
end

Openbus:enableFaultTolerance()

local orb = Openbus:getORB()

local scs = require "scs.core.base"
local AccessControlService = require "core.services.accesscontrol.AccessControlService"
local AccessControlServicePrev = require "core.services.accesscontrol.AccessControlService_Prev"

-----------------------------------------------------------------------------
-- AccessControlService Descriptions
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent                  = {}
facetDescriptions.IComponent_Prev             = {}
facetDescriptions.IAccessControlService       = {}
facetDescriptions.IAccessControlService_Prev  = {}
facetDescriptions.ILeaseProvider              = {}
facetDescriptions.ILeaseProvider_Prev         = {}
facetDescriptions.IFaultTolerantService       = {}
facetDescriptions.IFaultTolerantService_Prev  = {}
facetDescriptions.IManagement                 = {}
facetDescriptions.IReceptacles                = {}

facetDescriptions.IComponent.name           = "IComponent"
facetDescriptions.IComponent.interface_name = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class          = scs.Component
facetDescriptions.IComponent.key            = Utils.OPENBUS_KEY

facetDescriptions.IComponent_Prev.name           = "IComponent_" .. Utils.OB_PREV
facetDescriptions.IComponent_Prev.interface_name = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent_Prev.class          = AccessControlServicePrev.ComponentFacet
facetDescriptions.IComponent_Prev.key            = Utils.OPENBUS_KEY_PREV

facetDescriptions.IAccessControlService.name            = "IAccessControlService_" .. Utils.OB_VERSION
facetDescriptions.IAccessControlService.interface_name  = Utils.ACCESS_CONTROL_SERVICE_INTERFACE
facetDescriptions.IAccessControlService.class           = AccessControlService.ACSFacet
facetDescriptions.IAccessControlService.key             = Utils.ACCESS_CONTROL_SERVICE_KEY

facetDescriptions.IAccessControlService_Prev.name           = "IAccessControlService_" .. Utils.OB_PREV
facetDescriptions.IAccessControlService_Prev.interface_name = Utils.ACCESS_CONTROL_SERVICE_INTERFACE_PREV
facetDescriptions.IAccessControlService_Prev.class          = AccessControlServicePrev.ACSFacet
facetDescriptions.IAccessControlService_Prev.key            = Utils.ACCESS_CONTROL_SERVICE_KEY_PREV

facetDescriptions.ILeaseProvider.name                        = "ILeaseProvider_" .. Utils.OB_VERSION
facetDescriptions.ILeaseProvider.interface_name              = Utils.LEASE_PROVIDER_INTERFACE
facetDescriptions.ILeaseProvider.class                       = AccessControlService.LeaseProviderFacet
facetDescriptions.ILeaseProvider.key                         = Utils.LEASE_PROVIDER_KEY

facetDescriptions.ILeaseProvider_Prev.name                  = "ILeaseProvider_" .. Utils.OB_PREV
facetDescriptions.ILeaseProvider_Prev.interface_name        = Utils.LEASE_PROVIDER_INTERFACE_PREV
facetDescriptions.ILeaseProvider_Prev.class                 = AccessControlServicePrev.LeaseProviderFacet
facetDescriptions.ILeaseProvider_Prev.key                   = Utils.LEASE_PROVIDER_KEY_PREV

facetDescriptions.IFaultTolerantService.name                 = "IFaultTolerantService_" .. Utils.OB_VERSION
facetDescriptions.IFaultTolerantService.interface_name       = Utils.FAULT_TOLERANT_SERVICE_INTERFACE
facetDescriptions.IFaultTolerantService.class                = AccessControlService.FaultToleranceFacet
facetDescriptions.IFaultTolerantService.key                  = Utils.FAULT_TOLERANT_ACS_KEY

facetDescriptions.IFaultTolerantService_Prev.name                 = "IFaultTolerantService_" .. Utils.OB_PREV
facetDescriptions.IFaultTolerantService_Prev.interface_name       = Utils.FAULT_TOLERANT_SERVICE_INTERFACE
facetDescriptions.IFaultTolerantService_Prev.class                = AccessControlServicePrev.FaultToleranceFacet
facetDescriptions.IFaultTolerantService_Prev.key                  = Utils.FAULT_TOLERANT_ACS_KEY_PREV

facetDescriptions.IManagement.name            = "IManagement_" .. Utils.OB_VERSION
facetDescriptions.IManagement.interface_name  = Utils.MANAGEMENT_ACS_INTERFACE
facetDescriptions.IManagement.class           = AccessControlService.ManagementFacet
facetDescriptions.IManagement.key             = Utils.MANAGEMENT_ACS_KEY

local acsReceptFacetRef = 
  orb:newservant(AccessControlService.ACSReceptacleFacet(TableDB(dbfile)),"",Utils.RECEPTACLES_INTERFACE)

facetDescriptions.IReceptacles.name           = "IReceptacles"
facetDescriptions.IReceptacles.interface_name = Utils.RECEPTACLES_INTERFACE
facetDescriptions.IReceptacles.class          = AccessControlService.ACSReceptacleFacet
facetDescriptions.IReceptacles.facet_ref      = acsReceptFacetRef


-- Receptacle Descriptions
local receptacleDescs = {}
receptacleDescs.RegistryServiceReceptacle = {}
receptacleDescs.RegistryServiceReceptacle.name           = "RegistryServiceReceptacle"
receptacleDescs.RegistryServiceReceptacle.interface_name = Utils.COMPONENT_INTERFACE
receptacleDescs.RegistryServiceReceptacle.is_multiplex   = true


-- component id
local componentId = {}
componentId.name = "AccessControlService"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

---
--Fun��o que ser� executada pelo OiL em modo protegido.
---
function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  -- Cria o componente respons�vel pelo Servi�o de Controle de Acesso
  acsInst = scs.newComponent(facetDescriptions, receptacleDescs, componentId)

  -- Configura��es
  acsInst.IComponent.startup = AccessControlService.startup
  acsInst.IComponent.shutdown = AccessControlService.shutdown

  local acs = acsInst.IAccessControlService
  acs.config = AccessControlServerConfiguration
  acs.entries = {}
  acs.observers = {}
  acs.challenges = {}
  acs.loginPasswordValidators = {}

  for v,k in ipairs(AccessControlServerConfiguration.validators) do
    local validator = require(k)
    table.insert(acs.loginPasswordValidators, validator(acs.config))
  end

  -- Inicializa��o
  success, res = oil.pcall(acsInst.IComponent.startup, acsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o servi�o de controle de acesso: "..
        tostring(res).."\n")
    os.exit(1)
  end
  Log:info("O servi�o de controle de acesso foi iniciado com sucesso")
  Audit:uptime("O servi�o de controle de acesso foi iniciado com sucesso")
end

local status, errMsg = oil.pcall(oil.main,main)
if not status then
  Log:error(format(
      "Ocorreu uma falha na execu��o do servi�o de controle de acesso: %s",
      tostring(errMsg)))
end

exitServer({serviceLogFile, auditLogFile, oilLogFile})
