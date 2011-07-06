-- $Id$

---
--Inicialização do Serviço de Controle de Acesso
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

local ComponentContext = require "scs.core.ComponentContext"

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  Log:error("A variável IDLPATH_DIR não foi definida")
  os.exit(1)
end

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A vari[avel OPENBUS_DATADIR não foi definida")
  os.exit(1)
end

local dbfile = DATA_DIR .. "/acs_connections.db"

-- Obtém a configuração do serviço
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
    --host=<IP number>       : defines the IP number (or hostname) to use (default=]]
                                .. tostring(AccessControlServerConfiguration.hostName) .. [[)

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
if arguments.host then
  acsConfig.hostName = arguments.host
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
        "Falha ao abrir o arquivo de log do serviço de controle de acesso: %s",
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
  Log:error("O OpenBus não foi inicializado")
  exitServer({serviceLogFile, auditLogFile, OiLLogFile}, -1)
end

Openbus:enableFaultTolerance()

local orb = Openbus:getORB()

local AccessControlService = require "core.services.accesscontrol.AccessControlService"
local AccessControlServicePrev = require "core.services.accesscontrol.AccessControlService_Prev"

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  -- Cria o componente responsável pelo Serviço de Controle de Acesso
  local componentId = {}
  componentId.name = "AccessControlService"
  componentId.major_version = 1
  componentId.minor_version = 0
  componentId.patch_version = 0
  componentId.platform_spec = ""

  local keys = {}
  keys.IComponent = Utils.OPENBUS_KEY

  acsInst = ComponentContext(Openbus:getORB(), componentId, keys)
  acsInst:addFacet("IAccessControlService_" .. Utils.IDL_VERSION,
                    Utils.ACCESS_CONTROL_SERVICE_INTERFACE,
                    AccessControlService.ACSFacet(),
                    Utils.ACCESS_CONTROL_SERVICE_KEY)
  acsInst:addFacet("IAccessControlService",
                    Utils.ACCESS_CONTROL_SERVICE_INTERFACE_PREV,
                    AccessControlServicePrev.ACSFacet(),
                    Utils.ACCESS_CONTROL_SERVICE_KEY_PREV)
  acsInst:addFacet("ILeaseProvider_" .. Utils.IDL_VERSION,
                    Utils.LEASE_PROVIDER_INTERFACE,
                    AccessControlService.LeaseProviderFacet(),
                    Utils.LEASE_PROVIDER_KEY)
  acsInst:addFacet("ILeaseProvider",
                    Utils.LEASE_PROVIDER_INTERFACE_PREV,
                    AccessControlServicePrev.LeaseProviderFacet(),
                    Utils.LEASE_PROVIDER_KEY_PREV)
  acsInst:addFacet("IFaultTolerantService_" .. Utils.IDL_VERSION,
                    Utils.FAULT_TOLERANT_SERVICE_INTERFACE,
                    AccessControlService.FaultToleranceFacet(),
                    Utils.FAULT_TOLERANT_ACS_KEY)
  acsInst:addFacet("IManagement_" .. Utils.IDL_VERSION,
                    Utils.MANAGEMENT_ACS_INTERFACE,
                    AccessControlService.ManagementFacet(),
                    Utils.MANAGEMENT_ACS_KEY)
  acsInst:updateFacet("IReceptacles",
                    AccessControlService.ACSReceptacleFacet(TableDB(dbfile)))

  acsInst:addReceptacle("RegistryServiceReceptacle", Utils.COMPONENT_INTERFACE, true)

  -- Configurações
  acsInst.IComponent.startup = AccessControlService.startup
  acsInst.IComponent.shutdown = AccessControlService.shutdown

  local acs = acsInst:getFacetByName("IAccessControlService_" .. Utils.IDL_VERSION).facet_ref
  acs.config = AccessControlServerConfiguration
  acs.entries = {}
  acs.observers = {}
  acs.challenges = {}
  acs.loginPasswordValidators = {}

  for v,k in ipairs(AccessControlServerConfiguration.validators) do
    local validator = require(k)
    table.insert(acs.loginPasswordValidators, validator(acs.config))
  end

  -- Inicialização
  success, res = oil.pcall(acsInst.IComponent.startup, acsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o serviço de controle de acesso: "..
        tostring(res).."\n")
    os.exit(1)
  end
  Log:info("O serviço de controle de acesso foi iniciado com sucesso")
  Audit:uptime("O serviço de controle de acesso foi iniciado com sucesso")
end

local status, errMsg = oil.pcall(oil.main,main)
if not status then
  Log:error(format(
      "Ocorreu uma falha na execução do serviço de controle de acesso: %s",
      tostring(errMsg)))
end

exitServer({serviceLogFile, auditLogFile, oilLogFile})
