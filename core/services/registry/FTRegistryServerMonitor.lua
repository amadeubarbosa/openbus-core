-- $Id

---
--Inicialização do Monitor do Serviço de registro com Tolerancia a Falhas
---
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local print = print

local Utils = require "openbus.util.Utils"
local Log = require "openbus.util.Log"
local oil = require "oil"
local Openbus = require "openbus.Openbus"

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
assert(loadfile(DATA_DIR.."/conf/RegistryServerConfiguration.lua"))()

-- Parsing arguments
local usage_msg = [[
  --help                   : show this help
    --verbose (v)          : turn ON the VERBOSE mode (show the system commands)
  --port=<port number>     : defines the port of the service to be monitored (default=]]
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
  else
    Log:level(3)
  end
end

if arguments.port then
  RegistryServerConfiguration.registryServerHostPort = tonumber(arguments.port)
else
  Log:warn("Será usada porta padrão do Serviço de Registro")
end

local hostAdd = RegistryServerConfiguration.registryServerHostName..":"
                ..RegistryServerConfiguration.registryServerHostPort

local props = {  host = RegistryServerConfiguration.registryServerHostName,
           port =  tonumber(RegistryServerConfiguration.registryServerHostPort)}

-- Inicializa o barramento
Openbus:init(RegistryServerConfiguration.accessControlServerHostName,
  RegistryServerConfiguration.accessControlServerHostPort)

Openbus:enableFaultTolerance()

local orb = Openbus:getORB()

local FTRegistryServiceMonitor = require "core.services.registry.FTRegistryServiceMonitor"
local scs = require "scs.core.base"

orb:loadidlfile(IDLPATH_DIR.."/v"..Utils.OB_VERSION.."/fault_tolerance.idl")

-----------------------------------------------------------------------------
-- FTRegistryServiceMonitor Descriptions
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent                     = {}
facetDescriptions.IReceptacles                   = {}
facetDescriptions.IMetaInterface                 = {}
facetDescriptions.IFTServiceMonitor              = {}

facetDescriptions.IComponent.name                     = "IComponent"
facetDescriptions.IComponent.interface_name           = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                    = scs.Component
facetDescriptions.IComponent.key                      = "IC"

facetDescriptions.IReceptacles.name                   = "IReceptacles"
facetDescriptions.IReceptacles.interface_name         = "IDL:scs/core/IReceptacles:1.0"
facetDescriptions.IReceptacles.class                  = scs.Receptacles

facetDescriptions.IMetaInterface.name                 = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name       = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class                = scs.MetaInterface

facetDescriptions.IFTServiceMonitor.name              = "IFTServiceMonitor_v" .. Utils.OB_VERSION
facetDescriptions.IFTServiceMonitor.interface_name    = Utils.FT_SERVICE_MONITOR_INTERFACE
facetDescriptions.IFTServiceMonitor.class             = FTRegistryServiceMonitor.FTRSMonitorFacet
facetDescriptions.IFTServiceMonitor.key               = FT_RS_MONITOR_KEY

-- Receptacle Descriptions
local receptacleDescriptions = {}
receptacleDescriptions.IFaultTolerantService = {}
receptacleDescriptions.IFaultTolerantService.name           = "IFaultTolerantService"
receptacleDescriptions.IFaultTolerantService.interface_name = Utils.FAULT_TOLERANT_SERVICE_INTERFACE
receptacleDescriptions.IFaultTolerantService.is_multiplex   = false
receptacleDescriptions.IFaultTolerantService.type           = "Receptacle"

-- component id
local componentId = {}
componentId.name = "RGSMonitor"
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

  -- Cria o componente responsável pelo Monitor do Serviço de Registro
  local ftrsInst = scs.newComponent(facetDescriptions, receptacleDescriptions, componentId)

  -- Configurações
  ftrsInst.IComponent.startup = FTRegistryServiceMonitor.startup

  local ftrs = ftrsInst.IFTServiceMonitor
  ftrs.config = RegistryServerConfiguration

  -- Inicialização
  success, res = oil.pcall(ftrsInst.IComponent.startup, ftrsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o monitor do serviço de registro: "..
        tostring(res).."\n")
    os.exit(1)
  end

  local success, res = oil.pcall(oil.newthread, ftrs.monitor, ftrs)
  if not success then
    Log:error("Falha na execução do Monitor do Servico de registro: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:faulttolerance("Monitor do servico de registro monitorando com sucesso.")

end

print(oil.pcall(oil.main,main))
