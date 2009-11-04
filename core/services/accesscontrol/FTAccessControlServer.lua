---
--Inicialização do Serviço de Controle de Acesso Tolerante a Falhas
--
--   $Id: FTAccessControlServer.lua 
---


local oil = require "oil"
local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"
local LDAPLoginPasswordValidator =
    require "core.services.accesscontrol.LDAPLoginPasswordValidator"
local TestLoginPasswordValidator =
    require "core.services.accesscontrol.TestLoginPasswordValidator"

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

-- Define os níveis de verbose para o OpenBus e para o OiL.
if AccessControlServerConfiguration.logLevel then
  Log:level(AccessControlServerConfiguration.logLevel)
end
if AccessControlServerConfiguration.oilVerboseLevel then
  oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
end

local hostPort = arg[1]
if hostPort == nil then
   Log:error("É necessario passar o numero da porta.\n")
    os.exit(1)
end
AccessControlServerConfiguration.hostPort = tonumber(hostPort)

local props = { host = AccessControlServerConfiguration.hostName,
  port = AccessControlServerConfiguration.hostPort}

-- Inicializa o barramento
Openbus:resetAndInitialize( AccessControlServerConfiguration.hostName,
  AccessControlServerConfiguration.hostPort, props, iconfig)

Openbus:enableFaultTolerance()
  
local orb = Openbus:getORB()

local scs = require "scs.core.base"
local AccessControlService = require "core.services.accesscontrol.AccessControlService"
local FaultTolerantService = require "core.services.faulttolerance.FaultTolerantService"



-----------------------------------------------------------------------------
-- AccessControlService Descriptions
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent          	= {}
facetDescriptions.IMetaInterface      	= {}
facetDescriptions.IAccessControlService = {}
facetDescriptions.ILeaseProvider       	= {}
facetDescriptions.IFaultTolerantService	= {}
facetDescriptions.IManagement           = {}

facetDescriptions.IComponent.name                     = "IComponent"
facetDescriptions.IComponent.interface_name           = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                    = scs.Component
facetDescriptions.IComponent.key                      = "IC"

facetDescriptions.IMetaInterface.name                 = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name       = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class                = scs.MetaInterface

facetDescriptions.IAccessControlService.name            = "IAccessControlService"
facetDescriptions.IAccessControlService.interface_name  = "IDL:openbusidl/acs/IAccessControlService:1.0"
facetDescriptions.IAccessControlService.class           = AccessControlService.ACSFacet
facetDescriptions.IAccessControlService.key             = "ACS"

facetDescriptions.ILeaseProvider.name                  = "ILeaseProvider"
facetDescriptions.ILeaseProvider.interface_name        = "IDL:openbusidl/acs/ILeaseProvider:1.0"
facetDescriptions.ILeaseProvider.class                 = AccessControlService.LeaseProviderFacet
facetDescriptions.ILeaseProvider.key                   = "LP"

facetDescriptions.IFaultTolerantService.name                  = "IFaultTolerantService"
facetDescriptions.IFaultTolerantService.interface_name        = "IDL:openbusidl/ft/IFaultTolerantService:1.0"
facetDescriptions.IFaultTolerantService.class                 = FaultTolerantService.FaultToleranceFacet
facetDescriptions.IFaultTolerantService.key                   = "FTACS"

facetDescriptions.IManagement.name           = "IManagement"
facetDescriptions.IManagement.interface_name = "IDL:openbusidl/acs/IManagement:1.0"
facetDescriptions.IManagement.class          = AccessControlService.ManagementFacet
facetDescriptions.IManagement.key            = "MGM"

--Log:faulttolerance(facetDescriptions)

-- Receptacle Descriptions
local receptacleDescs = {}
receptacleDescs.RegistryServiceReceptacle = {}
receptacleDescs.RegistryServiceReceptacle.name           = "RegistryServiceReceptacle"
receptacleDescs.RegistryServiceReceptacle.interface_name =  "IDL:openbusidl/rs/IRegistryService:1.0"
receptacleDescs.RegistryServiceReceptacle.is_multiplex   = false

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

  local acs = acsInst.IAccessControlService
  acs.config = AccessControlServerConfiguration
  acs.entries = {}
  acs.observers = {}
  acs.challenges = {}
  acs.loginPasswordValidators = {LDAPLoginPasswordValidator(acs.config.ldapHosts, acs.config.ldapSuffixes),
    TestLoginPasswordValidator(),
  }

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
