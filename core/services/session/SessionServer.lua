-----------------------------------------------------------------------------
-- Inicialização do Serviço de Sessão
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local tonumber = tonumber

local oil = require "oil"
local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"
local Utils = require "openbus.util.Utils"

-- Inicialização do nível de verbose do openbus.
Log:level(1)

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/SessionServerConfiguration.lua"))()
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

if arguments.verbose == "" then
  oil.verbose:level(5)
else
  if SessionServerConfiguration.oilVerboseLevel then
      oil.verbose:level(SessionServerConfiguration.oilVerboseLevel)
  end
end

if arguments.port then
  SessionServerConfiguration.sessionServerHostPort = tonumber(arguments.port)
end

-- Seta os níveis de verbose para o openbus e para o oil
if SessionServerConfiguration.logLevel then
  Log:level(SessionServerConfiguration.logLevel)
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
  log:error("Serviço de Sessão: A variável IDLPATH_DIR não foi definida.")
  return false
end
local version = Utils.OB_VERSION
local prev = Utils.OB_PREV
local idlfile = IDLPATH_DIR .. "/v"..version.."/session_service.idl"
orb:loadidlfile(idlfile)

local scs = require "scs.core.base"
local SessionServiceComponent =
  require "core.services.session.SessionServiceComponent"
local SessionService = require "core.services.session.SessionService"
local SessionService_v1_04 = require "core.services.session.SessionService_v1_04"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

-----------------------------------------------------------------------------
-- Descricoes do Componente Servico de Sessao
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent            = {}
facetDescriptions.IMetaInterface        = {}
facetDescriptions.ISessionService       = {}
facetDescriptions.ISessionService_Prev  = {}
facetDescriptions.ICredentialObserver   = {}
facetDescriptions.IReceptacles          = {}

facetDescriptions.IComponent.name                    = "IComponent"
facetDescriptions.IComponent.interface_name          = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                   = SessionServiceComponent.SessionServiceComponent

facetDescriptions.IMetaInterface.name                = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name      = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class               = scs.MetaInterface

facetDescriptions.ISessionService.name               = "ISessionService_v" .. Utils.OB_VERSION
facetDescriptions.ISessionService.interface_name     = Utils.SESSION_SERVICE_INTERFACE
facetDescriptions.ISessionService.class              = SessionService.SessionService

facetDescriptions.ISessionService_Prev.name           = "ISessionService"
facetDescriptions.ISessionService_Prev.interface_name = Utils.SESSION_SERVICE_INTERFACE_V1_04
facetDescriptions.ISessionService_Prev.class          = SessionService_v1_04.SessionService

-- Nao precisa ter 2 versoes de credential observer pois e' uma comunicacao intra-barramento.
-- O barramento como um todo sempre estara na mesma versao (mais nova).
facetDescriptions.ICredentialObserver.name           = "SessionServiceCredentialObserver"
facetDescriptions.ICredentialObserver.interface_name = Utils.CREDENTIAL_OBSERVER_INTERFACE
facetDescriptions.ICredentialObserver.class          = SessionService.Observer

facetDescriptions.IReceptacles.name           = "IReceptacles"
facetDescriptions.IReceptacles.interface_name = "IDL:scs/core/IReceptacles:1.0"
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
    Log:error("Falha criando componente: "..tostring(res).."\n")
    os.exit(1)
  end
  res.IComponent.config = SessionServerConfiguration
  local sessionServiceComponent = res.IComponent
  success, res = oil.pcall(sessionServiceComponent.startup,
      sessionServiceComponent)
  if not success then
    Log:error("Falha ao iniciar o serviço de sessão: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Serviço de sessão iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
