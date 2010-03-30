-----------------------------------------------------------------------------
-- Inicializa��o do Servi�o de Registro
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
local tonumber = tonumber

local oil = require "oil"
local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"
local Utils = require "openbus.util.Utils"

-- Inicializa��o do n�vel de verbose do openbus.
Log:level(1)

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obt�m a configura��o do servi�o
assert(loadfile(DATA_DIR.."/conf/RegistryServerConfiguration.lua"))()
local iConfig =
  assert(loadfile(DATA_DIR.."/conf/advanced/RSInterceptorsConfiguration.lua"))()
  
-- Parsing arguments
local usage_msg = [[
  --help                   : show this help
  --verbose                : turn ON the VERBOSE mode (show the system commands)
  --port=<port number>     : defines the service port (padr�o ]] 
                .. tostring(RegistryServerConfiguration.registryServerHostPort) .. [[)
 NOTES:
  The prefix '--' is optional in all options.
  So '--help' or '-help' or yet 'help' all are the same option.]]
local arguments = Utils.parse_args(arg,usage_msg,true)

if arguments.verbose == "" then
  oil.verbose:level(5)
else
  if RegistryServerConfiguration.oilVerboseLevel then
      oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel)
  end
end

if arguments.port then
  RegistryServerConfiguration.registryServerHostPort = tonumber(arguments.port)
end
  
-- Define os n�veis de verbose para o openbus e para o oil
if RegistryServerConfiguration.logLevel then
  Log:level(RegistryServerConfiguration.logLevel)
end


props = {  host = RegistryServerConfiguration.registryServerHostName,
           port =  tonumber(RegistryServerConfiguration.registryServerHostPort)}
           
-- Inicializa o barramento
Openbus:init(RegistryServerConfiguration.accessControlServerHostName,
  RegistryServerConfiguration.accessControlServerHostPort,
  props, iConfig, iConfig)
  
Openbus:enableFaultTolerance()

local orb = Openbus:getORB()

local scs = require "scs.core.base"
local RegistryService = require "core.services.registry.RegistryService"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

-----------------------------------------------------------------------------
---- RegistryService Descriptions
-------------------------------------------------------------------------------

---- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent       = {}
facetDescriptions.IMetaInterface   = {}
facetDescriptions.IRegistryService = {}
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

facetDescriptions.IRegistryService.name            = "IRegistryService"
facetDescriptions.IRegistryService.interface_name  = "IDL:tecgraf/openbus/core/v1_05/registry_service/IRegistryService:1.0"
facetDescriptions.IRegistryService.class           = RegistryService.RSFacet
facetDescriptions.IRegistryService.key             = Utils.REGISTRY_SERVICE_KEY

facetDescriptions.IFaultTolerantService.name                  = "IFaultTolerantService"
facetDescriptions.IFaultTolerantService.interface_name        = "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0"
facetDescriptions.IFaultTolerantService.class                 = RegistryService.FaultToleranceFacet
facetDescriptions.IFaultTolerantService.key                   = Utils.FAULT_TOLERANT_RS_KEY

facetDescriptions.IManagement.name           = "IManagement"
facetDescriptions.IManagement.interface_name = "IDL:tecgraf/openbus/core/v1_05/registry_service/IManagement:1.0"
facetDescriptions.IManagement.class          = RegistryService.ManagementFacet
facetDescriptions.IManagement.key            = "MGM"

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

  -- Cria o componente respons�vel pelo Servi�o de Registro
  rsInst = scs.newComponent(facetDescriptions, receptacleDescs, componentId)

  -- Configuracoes
  rsInst.IComponent.startup = RegistryService.startup
  rsInst.IComponent.shutdown = RegistryService.shutdown

  local rs = rsInst.IRegistryService
  rs.config = RegistryServerConfiguration

  success, res = oil.pcall (rsInst.IComponent.startup, rsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o servi�o de registro: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Servi�o de registro iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
