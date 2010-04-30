-- $Id$

---
--Inicialização do Serviço de Controle de Acesso
---
local string = string
local oil = require "oil"
oil.verbose:level(3)
local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"
local Utils = require "openbus.util.Utils"

-- Inicialização do nível de verbose do openbus.
Log:level(1)

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  Log:error("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/AccessControlServerConfiguration.lua"))()
local iconfig = assert(loadfile(DATA_DIR ..
  "/conf/advanced/ACSInterceptorsConfiguration.lua"))()

-- Parsing arguments
local usage_msg = [[
	--help                   : show this help
	--verbose                : turn ON the VERBOSE mode (show the system commands)
	--port=<port number>     : defines the service port (default=]] 
								.. tostring(AccessControlServerConfiguration.hostPort) .. [[)
 NOTES:
 	The prefix '--' is optional in all options.
	So '--help' or '-help' or yet 'help' all are the same option.]]
local arguments = Utils.parse_args(arg,usage_msg,true)

if arguments.verbose == "" then
	oil.verbose:level(5)
else
	if AccessControlServerConfiguration.oilVerboseLevel then
  		oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
	end
end

if arguments.port then
	AccessControlServerConfiguration.hostPort = tonumber(arguments.port)
end

-- Define os níveis de verbose para o OpenBus e para o OiL.
if AccessControlServerConfiguration.logLevel then
  Log:level(AccessControlServerConfiguration.logLevel)
end

local props = { host = AccessControlServerConfiguration.hostName,
  port = AccessControlServerConfiguration.hostPort}

-- Inicializa o barramento
Openbus:init(AccessControlServerConfiguration.hostName,
  AccessControlServerConfiguration.hostPort, props, iconfig)
  
Openbus:enableFaultTolerance()

local orb = Openbus:getORB()

local scs = require "scs.core.base"
local AccessControlService = require "core.services.accesscontrol.AccessControlService"
local AccessControlService_v1_04 = require "core.services.accesscontrol.AccessControlService_v1_04"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"
-----------------------------------------------------------------------------
-- AccessControlService Descriptions
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent          	      = {}
facetDescriptions.IMetaInterface      	      = {}
facetDescriptions.IAccessControlService       = {}
facetDescriptions.IAccessControlService_Prev  = {}
facetDescriptions.ILeaseProvider       	      = {}
facetDescriptions.ILeaseProvider_Prev         = {}
facetDescriptions.IFaultTolerantService       = {}
facetDescriptions.IManagement                 = {}
facetDescriptions.IReceptacles                = {}

facetDescriptions.IComponent.name           = "IComponent"
facetDescriptions.IComponent.interface_name = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class          = scs.Component
facetDescriptions.IComponent.key            = Utils.OPENBUS_KEY

facetDescriptions.IMetaInterface.name                 = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name       = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class                = scs.MetaInterface

facetDescriptions.IAccessControlService.name            = "IAccessControlService_v" .. Utils.OB_VERSION
facetDescriptions.IAccessControlService.interface_name  = Utils.ACCESS_CONTROL_SERVICE_INTERFACE
facetDescriptions.IAccessControlService.class           = AccessControlService.ACSFacet
facetDescriptions.IAccessControlService.key             = Utils.ACCESS_CONTROL_SERVICE_KEY

facetDescriptions.IAccessControlService_Prev.name           = "IAccessControlService"
facetDescriptions.IAccessControlService_Prev.interface_name = Utils.ACCESS_CONTROL_SERVICE_INTERFACE_V1_04
facetDescriptions.IAccessControlService_Prev.class          = AccessControlService_v1_04.ACSFacet
facetDescriptions.IAccessControlService_Prev.key            = Utils.ACCESS_CONTROL_SERVICE_KEY_V1_04

facetDescriptions.ILeaseProvider.name                        = "ILeaseProvider_v" .. Utils.OB_VERSION
facetDescriptions.ILeaseProvider.interface_name              = Utils.LEASE_PROVIDER_INTERFACE
facetDescriptions.ILeaseProvider.class                       = AccessControlService.LeaseProviderFacet
facetDescriptions.ILeaseProvider.key                         = Utils.LEASE_PROVIDER_KEY

facetDescriptions.ILeaseProvider_Prev.name                  = "ILeaseProvider"
facetDescriptions.ILeaseProvider_Prev.interface_name        = Utils.LEASE_PROVIDER_INTERFACE_V1_04
facetDescriptions.ILeaseProvider_Prev.class                 = AccessControlService_v1_04.LeaseProviderFacet
facetDescriptions.ILeaseProvider_Prev.key                   = Utils.LEASE_PROVIDER_KEY_V1_04

facetDescriptions.IFaultTolerantService.name                 = "IFaultTolerantService_v" .. Utils.OB_VERSION
facetDescriptions.IFaultTolerantService.interface_name       = Utils.FAULT_TOLERANT_SERVICE_INTERFACE
facetDescriptions.IFaultTolerantService.class                = AccessControlService.FaultToleranceFacet
facetDescriptions.IFaultTolerantService.key                  = Utils.FAULT_TOLERANT_ACS_KEY

facetDescriptions.IManagement.name            = "IManagement_v" .. Utils.OB_VERSION
facetDescriptions.IManagement.interface_name  = Utils.MANAGEMENT_ACS_INTERFACE 
facetDescriptions.IManagement.class           = AccessControlService.ManagementFacet

facetDescriptions.IReceptacles.name           = "IReceptacles"
facetDescriptions.IReceptacles.interface_name = "IDL:scs/core/IReceptacles:1.0"
facetDescriptions.IReceptacles.class          = AdaptiveReceptacle.AdaptiveReceptacleFacet


--Log:faulttolerance(facetDescriptions)

-- Receptacle Descriptions
local receptacleDescs = {}
receptacleDescs.RegistryServiceReceptacle = {}
receptacleDescs.RegistryServiceReceptacle.name           = "RegistryServiceReceptacle"
receptacleDescs.RegistryServiceReceptacle.interface_name =  "IDL:scs/core/IComponent:1.0"
receptacleDescs.RegistryServiceReceptacle.is_multiplex   = true


-- component id
local componentId = {}
componentId.name = "AccessControlService"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  -- Cria o componente responsável pelo Serviço de Controle de Acesso
  acsInst = scs.newComponent(facetDescriptions, receptacleDescs, componentId)

  -- Configurações
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

  -- Inicialização
  success, res = oil.pcall(acsInst.IComponent.startup, acsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o serviço de controle de acesso: "..
        tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Serviço de controle de acesso iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
