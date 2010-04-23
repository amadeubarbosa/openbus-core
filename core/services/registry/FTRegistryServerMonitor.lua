-- $Id

---
--Inicializa��o do Monitor do Servi�o de registro com Tolerancia a Falhas
---
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local print = print

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

-- Obt�m a configura��o do servi�o
assert(loadfile(DATA_DIR.."/conf/RegistryServerConfiguration.lua"))()

-- Seta os n�veis de verbose para o openbus e para o oil
if RegistryServerConfiguration.logLevel then
  Log:level(RegistryServerConfiguration.logLevel)
end
if RegistryServerConfiguration.oilVerboseLevel then
  oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel)
end

local hostPort = arg[1]
if hostPort == nil then
   Log:error("� necessario passar o n�mero da porta.\n")
    os.exit(1)
end
RegistryServerConfiguration.registryServerHostPort = tonumber(hostPort)

local hostAdd = RegistryServerConfiguration.registryServerHostName..":"..hostPort


-- Inicializa o ORB
local orb = oil.init {
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }
oil.orb = orb

local FTRegistryServiceMonitor = require "core.services.registry.FTRegistryServiceMonitor"
local scs = require "scs.core.base"

orb:loadidlfile(IDLPATH_DIR.."/v1_05/fault_tolerance.idl")

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

facetDescriptions.IFTServiceMonitor.name              = "IFTServiceMonitor"
facetDescriptions.IFTServiceMonitor.interface_name    = "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFTServiceMonitor:1.0"
facetDescriptions.IFTServiceMonitor.class             = FTRegistryServiceMonitor.FTRSMonitorFacet
facetDescriptions.IFTServiceMonitor.key               = "FTRSMonitor"

-- Receptacle Descriptions
local receptacleDescriptions = {}
receptacleDescriptions.IFaultTolerantService = {}
receptacleDescriptions.IFaultTolerantService.name           = "IFaultTolerantService"
receptacleDescriptions.IFaultTolerantService.interface_name = "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0"
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
--Fun��o que ser� executada pelo OiL em modo protegido.
---
function main()

  -- Cria o componente respons�vel pelo Monitor do Servi�o de Registro
  local ftrsInst = scs.newComponent(facetDescriptions, receptacleDescriptions, componentId)

  -- Configura��es
  ftrsInst.IComponent.startup = FTRegistryServiceMonitor.startup

  local ftrs = ftrsInst.IFTServiceMonitor
  ftrs.config = RegistryServerConfiguration

  -- Inicializa��o
  success, res = oil.pcall(ftrsInst.IComponent.startup, ftrsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o monitor do servi�o de registro: "..
        tostring(res).."\n")
    os.exit(1)
  end

  local success, res = oil.pcall(oil.newthread, ftrs.monitor, ftrs)
  if not success then
    Log:error("Falha na execu��o do Monitor do Servico de registro: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:faulttolerance("Monitor do servico de registro monitorando com sucesso.")

end

print(oil.pcall(oil.main,main))
