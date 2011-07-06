-----------------------------------------------------------------------------
-- Inicialização do Serviço de Sessão
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local format = string.format

local oil = require "oil"

local ComponentContext = require "scs.core.ComponentContext"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"
local SessionServiceComponent =
  require "core.services.session.SessionServiceComponent"
local SessionService = require "core.services.session.SessionService"
local SessionServicePrev = require "core.services.session.SessionService_Prev"

local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"
local Audit = require "openbus.util.Audit"
local Utils = require "openbus.util.Utils"

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR não foi definida")
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/SessionServerConfiguration.lua"))()
local ssConfig = SessionServerConfiguration
local iConfig =
  assert(loadfile(DATA_DIR.."/conf/advanced/SSInterceptorsConfiguration.lua"))()

-- Parsing arguments
local usage_msg = [[
  --help                   : show this help
  --verbose                : turn ON the VERBOSE mode (show the system commands)
  --acs-host=<IP number>   : defines the ACS service IP number (or hostname) (default=]]
                .. tostring(SessionServerConfiguration.accessControlServerHostName) .. [[)
  --acs-port=<port number> : defines the ACS service port (default=]]
                .. tostring(SessionServerConfiguration.accessControlServerHostPort) .. [[)
  --port=<port number>     : defines the service port (default=]]
                .. tostring(SessionServerConfiguration.sessionServerHostPort) .. [[)
  --host=<IP number>       : defines the IP number (or hostname) to use (default=]]
                .. tostring(SessionServerConfiguration.sessionServerHostName) .. [[)
 NOTES:
  The prefix '--' is optional in all options.
  So '--help' or '-help' or yet 'help' all are the same option.]]
local arguments = Utils.parse_args(arg,usage_msg,true)

if arguments.verbose == "" or arguments.v == "" then
  ssConfig.logs.service.level = 5
  ssConfig.logs.oil.level = 5
end
if arguments.port then
  ssConfig.sessionServerHostPort = tonumber(arguments.port)
end
if arguments.host then
  ssConfig.sessionServerHostName = arguments.host
end
if arguments["acs-host"] then
  ssConfig.accessControlServerHostName = arguments["acs-host"]
end
if arguments["acs-port"] then
  ssConfig.accessControlServerHostPort = arguments["acs-port"]
end

-- Configurando os logs
Log:level(ssConfig.logs.service.level)
Audit:level(ssConfig.logs.audit.level)
oil.verbose:level(ssConfig.logs.oil.level)

local serviceLogFile
if ssConfig.logs.service.file then
  local errMsg
  serviceLogFile, errMsg = Utils.setVerboseOutputFile(Log,
      ssConfig.logs.service.file)
  if not serviceLogFile then
    Log:error(format(
        "Falha ao abrir o arquivo de log do serviço de sessão: %s",
        tostring(errMsg)))
  end
end

local auditLogFile
if ssConfig.logs.audit.file then
  local errMsg
  auditLogFile, errMsg = Utils.setVerboseOutputFile(Audit,
      ssConfig.logs.audit.file)
  if not auditLogFile then
    Log:error(format(
        "Falha ao abrir o arquivo de auditoria: %s", tostring(errMsg)))
  end
end

local oilLogFile
if ssConfig.logs.oil.file then
  local errMsg
  oilLogFile, errMsg =
      Utils.setVerboseOutputFile(oil.verbose, ssConfig.logs.oil.file)
  if not oilLogFile then
    Log:error(format(
        "Falha ao abrir o arquivo de log do OiL: %s",
        tostring(errMsg)))
  end
end

props = {  host = SessionServerConfiguration.sessionServerHostName,
           port =  tonumber(SessionServerConfiguration.sessionServerHostPort)}

-- Inicializa o barramento
Openbus:init(SessionServerConfiguration.accessControlServerHostName,
  SessionServerConfiguration.accessControlServerHostPort,
  props, iConfig, iConfig, "CACHED")

Openbus:enableFaultTolerance()

local orb = Openbus:getORB()

-- Carrega a IDL do serviço
local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if not IDLPATH_DIR then
 Log:error("A variável IDLPATH_DIR não foi definida")
 return false
end
local idlfile = IDLPATH_DIR .. "/"..Utils.IDL_VERSION.."/session_service.idl"
orb:loadidlfile(idlfile)
idlfile = IDLPATH_DIR .. "/"..Utils.IDL_PREV.."/session_service.idl"
orb:loadidlfile(idlfile)

function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  -- Cria o componente responsável pelo Serviço de Sessão
  local componentId = {}
  componentId.name = "SessionService"
  componentId.major_version = 1
  componentId.minor_version = 0
  componentId.patch_version = 0
  componentId.platform_spec = ""

  local component = ComponentContext(orb, componentId)
  component:updateFacet("IComponent",
                      SessionServiceComponent.SessionServiceComponent())
  component:addFacet("ISessionService_"..Utils.IDL_VERSION,
                      Utils.SESSION_SERVICE_INTERFACE,
                      SessionService.SessionService())
  component:addFacet("ISessionService",
                      Utils.SESSION_SERVICE_INTERFACE_PREV,
                      SessionServicePrev.SessionService())
  -- Nao precisa ter 2 versoes de credential observer pois e' uma comunicacao intra-barramento.
  -- O barramento como um todo sempre estara na mesma versao (mais nova).
  component:addFacet("SessionServiceCredentialObserver",
                      Utils.CREDENTIAL_OBSERVER_INTERFACE,
                      SessionService.Observer())
  component:updateFacet("IReceptacles",
                      AdaptiveReceptacle.AdaptiveReceptacleFacet())
  component:addReceptacle("AccessControlServiceReceptacle", "IDL:scs/core/IComponent:1.0", true)

  component.IComponent.config = SessionServerConfiguration
  local sessionServiceComponent = component.IComponent
  local success, res = oil.pcall(sessionServiceComponent.startup,
      sessionServiceComponent)
  if not success then
    Log:error(format("Ocorreu um erro ao iniciar o serviço de sessão: %s",
      tostring(res)))
    os.exit(1)
  end
  Log:info("O serviço de sessão foi iniciado com sucesso")
  Audit:uptime("O serviço de sessão foi iniciado com sucesso")
end

local status, errMsg = oil.pcall(oil.main,main)
if not status then
  Log:error(format(
      "Ocorreu uma falha na execução do serviço de sessão: %s",
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
