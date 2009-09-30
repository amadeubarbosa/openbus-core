-- $Id

---
--Inicialização do Monitor do Serviço de registro com Tolerancia a Falhas
---
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local print = print

local Log = require "openbus.util.Log"
local oil = require "oil"

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


-- Seta os níveis de verbose para o openbus e para o oil
if RegistryServerConfiguration.logLevel then
  Log:level(RegistryServerConfiguration.logLevel)
end
if RegistryServerConfiguration.oilVerboseLevel then
  oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel)
end

local hostPort = arg[1]
if hostPort == nil then
   Log:error("É necessario passar o numero da porta.\n")
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

orb:loadidlfile(IDLPATH_DIR.."/ft_service_monitor.idl")

-----------------------------------------------------------------------------
-- FTRegistryServiceMonitor Descriptions
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent        		  	 = {}
facetDescriptions.IReceptacles   				 = {}
facetDescriptions.IMetaInterface     			 = {}
facetDescriptions.IFTRegistryServiceMonitor 	 = {}

facetDescriptions.IComponent.name                     = "IComponent"
facetDescriptions.IComponent.interface_name           = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                    = scs.Component
facetDescriptions.IComponent.key                      = "IC"

facetDescriptions.IReceptacles.name      			  = "IReceptacles"
facetDescriptions.IReceptacles.interface_name   	  = "IDL:scs/core/IReceptacles:1.0"
facetDescriptions.IReceptacles.class           		  = scs.Receptacles

facetDescriptions.IMetaInterface.name                 = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name       = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class                = scs.MetaInterface

facetDescriptions.IFTRegistryServiceMonitor.name 			= "IFTServiceMonitor"
facetDescriptions.IFTRegistryServiceMonitor.interface_name  = "IDL:openbusidl/ft/IFTServiceMonitor:1.0"
facetDescriptions.IFTRegistryServiceMonitor.class           = FTRegistryServiceMonitor.FTRSMonitorFacet
facetDescriptions.IFTRegistryServiceMonitor.key             = "FTRSMonitor"

-- Receptacle Descriptions
local receptacleDescriptions = {}
receptacleDescriptions.IFaultTolerantService = {}
receptacleDescriptions.IFaultTolerantService.name 			= "IFaultTolerantService"
receptacleDescriptions.IFaultTolerantService.interface_name = "IDL:openbusidl/ft/IFaultTolerantService:1.0"
receptacleDescriptions.IFaultTolerantService.is_multiplex 	= false
receptacleDescriptions.IFaultTolerantService.type   		= "Receptacle"

-- component id
local componentId = {}
componentId.name = "FTRegistryServiceMonitor"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""


---
--Função que será executada pelo OiL em modo protegido.
---
function main()

  local ftregistryService = orb:newproxy("corbaloc::"..hostAdd.."/FTRS","IDL:openbusidl/ft/IFaultTolerantService:1.0")
  if ftregistryService:_non_existent() then
      Log:error("Servico de registro nao encontrado.")
      os.exit(1)
  end
  
  if not ftregistryService:isAlive() then
	Log:error("Erro ao rodar isAlive.")
      os.exit(1)
  end

  -- Cria o componente responsável pelo Monitor do Serviço de Registro
  local ftrsInst = scs.newComponent(facetDescriptions, receptacleDescriptions, componentId)
  
  
  local ftRec = ftrsInst.IComponent:getFacetByName("IReceptacles")
  
  ftRec = orb:narrow(ftRec)
  local recConnId = ftRec:connect("IFaultTolerantService",ftregistryService)
  print("ConnectionId:")
  print(recConnId)
  if not recConnId then
	Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTRSMonitor")
    os.exit(1)
  end

  -- Configurações
  ftrsInst.IComponent.startup = FTRegistryServiceMonitor.startup
  
  local ftrs = ftrsInst.IFTRegistryServiceMonitor
  ftrs.config = RegistryServerConfiguration
  ftrs.recConnId = recConnId
  
  -- Inicialização
  success, res = oil.pcall(ftrsInst.IComponent.startup, ftrsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o monitor do serviço de registro: "..
        tostring(res).."\n")
    os.exit(1)
  end

  Log:init("Monitor do servico de registro iniciado com sucesso")
  local success, res = oil.pcall(oil.newthread,	ftrs.monitor, ftrs)
  if not success then
    Log:error("Falha na execucão do Monitor do Servico de registro: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:faulttolerance("Monitor do servico de registro monitorando com sucesso.")


end

print(oil.pcall(oil.main,main))
