-----------------------------------------------------------------------------
-- Inicialização do Serviço de Sessão
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local format = string.format

local oil = require "oil"

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
  --port=<port number>     : defines the service port (default=]] 
                .. tostring(SessionServerConfiguration.sessionServerHostPort) .. [[)
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

local scs = require "scs.core.base"
local SessionServiceComponent =
  require "core.services.session.SessionServiceComponent"
local SessionService = require "core.services.session.SessionService"
local SessionServicePrev = require "core.services.session.SessionService_Prev"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

-----------------------------------------------------------------------------
-- Descricoes do Componente Servico de Sessao
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent            = {}
facetDescriptions.ISessionService       = {}
facetDescriptions.ISessionService_Prev  = {}
facetDescriptions.ICredentialObserver   = {}
facetDescriptions.IReceptacles          = {}

facetDescriptions.IComponent.name                    = "IComponent"
facetDescriptions.IComponent.interface_name          = Utils.COMPONENT_INTERFACE
facetDescriptions.IComponent.class                   = SessionServiceComponent.SessionServiceComponent

facetDescriptions.ISessionService.name               = "ISessionService_"..Utils.IDL_VERSION
facetDescriptions.ISessionService.interface_name     = Utils.SESSION_SERVICE_INTERFACE
facetDescriptions.ISessionService.class              = SessionService.SessionService

facetDescriptions.ISessionService_Prev.name           = "ISessionService"
facetDescriptions.ISessionService_Prev.interface_name = Utils.SESSION_SERVICE_INTERFACE_PREV
facetDescriptions.ISessionService_Prev.class          = SessionServicePrev.SessionService

-- Nao precisa ter 2 versoes de credential observer pois e' uma comunicacao intra-barramento.
-- O barramento como um todo sempre estara na mesma versao (mais nova).
facetDescriptions.ICredentialObserver.name           = "SessionServiceCredentialObserver"
facetDescriptions.ICredentialObserver.interface_name = Utils.CREDENTIAL_OBSERVER_INTERFACE
facetDescriptions.ICredentialObserver.class          = SessionService.Observer

facetDescriptions.IReceptacles.name           = "IReceptacles"
facetDescriptions.IReceptacles.interface_name = Utils.RECEPTACLES_INTERFACE
facetDescriptions.IReceptacles.class          = AdaptiveReceptacle.AdaptiveReceptacleFacet

-- Receptacle Descriptions
local receptacleDescs = {}
receptacleDescs.AccessControlServiceReceptacle = {}
receptacleDescs.AccessControlServiceReceptacle.name           = "AccessControlServiceReceptacle"
receptacleDescs.AccessControlServiceReceptacle.interface_name =  "IDL:scs/core/IComponent:1.0"
receptacleDescs.AccessControlServiceReceptacle.is_multiplex   = true

-- component id
local componentId = {}
componentId.name = "SessionService"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  -- Cria o componente responsável pelo Serviço de Sessão
  success, res = oil.pcall(scs.newComponent, facetDescriptions, receptacleDescs,
      componentId)
  if not success then
    Log:error(format(
        "Ocorreu um erro ao criar o componente do serviço de sessão: %s",
        tostring(res)))
    os.exit(1)
  end
  res.IComponent.config = SessionServerConfiguration
  local sessionServiceComponent = res.IComponent
  success, res = oil.pcall(sessionServiceComponent.startup,
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
