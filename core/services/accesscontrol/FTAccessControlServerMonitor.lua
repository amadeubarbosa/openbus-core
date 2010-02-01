-- $Id

---
--Inicializa��o do Monitor do Servi�o de Controle de Acesso com Tolerancia a Falhas
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

-- Obt�m a configura��o do servi�o
assert(loadfile(DATA_DIR.."/conf/AccessControlServerConfiguration.lua"))()


-- Define os n�veis de verbose para o OpenBus e para o OiL.
if AccessControlServerConfiguration.logLevel then
  Log:level(AccessControlServerConfiguration.logLevel)
end
if AccessControlServerConfiguration.oilVerboseLevel then
  oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
end
local hostPort = arg[1]
if hostPort == nil then
   Log:error("� necessario passar o numero da porta.\n")
    os.exit(1)
end

AccessControlServerConfiguration.hostPort = tonumber(hostPort)

local hostAdd = AccessControlServerConfiguration.hostName..":"..hostPort


-- Inicializa o ORB, fixando a localiza��o do servi�o em uma porta espec�fica
local orb = oil.init {  flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }
					 
oil.orb = orb
oil.verbose:level(2)

local FTAccessControlServiceMonitor = require "core.services.accesscontrol.FTAccessControlServiceMonitor"
local scs = require "scs.core.base"

orb:loadidlfile(IDLPATH_DIR.."/fault_tolerance.idl")

-----------------------------------------------------------------------------
-- FTAccessControlServiceMonitor Descriptions
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent        		  	 = {}
facetDescriptions.IReceptacles					 = {}
facetDescriptions.IMetaInterface     			 = {}
facetDescriptions.IFTAccessControlServiceMonitor = {}

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

facetDescriptions.IFTAccessControlServiceMonitor.name 			  = "IFTServiceMonitor"
facetDescriptions.IFTAccessControlServiceMonitor.interface_name   = "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFTServiceMonitor:1.0"
facetDescriptions.IFTAccessControlServiceMonitor.class            =  FTAccessControlServiceMonitor.FTACSMonitorFacet
facetDescriptions.IFTAccessControlServiceMonitor.key              = "FTACSMonitor"

-- Receptacle Descriptions
local receptacleDescriptions = {}
receptacleDescriptions.IFaultTolerantService = {}
receptacleDescriptions.IFaultTolerantService.name 			= "IFaultTolerantService"
receptacleDescriptions.IFaultTolerantService.interface_name = "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0"
receptacleDescriptions.IFaultTolerantService.is_multiplex 	= false
receptacleDescriptions.IFaultTolerantService.type   		= "Receptacle"

-- component id
local componentId = {}
componentId.name = "FTAccessControlServiceMonitor"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

---
--Fun��o que ser� executada pelo OiL em modo protegido.
---
function main()

  local ftacsService = orb:newproxy("corbaloc::"..hostAdd.."/FTACS","IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0")
  if ftacsService:_non_existent() then
      Log:error("Faceta FT do Servico de controle de acesso nao encontrado.")
      os.exit(1)
  end
  
  if not ftacsService:isAlive() then
	Log:error("Erro ao rodar isAlive.")
      os.exit(1)
  end

  -- Cria o componente respons�vel pelo Monitor do Servi�o de Controle de Acesso
  local ftacsInst = scs.newComponent(facetDescriptions, receptacleDescriptions, componentId)
  
  
  local ftRec = ftacsInst.IComponent:getFacetByName("IReceptacles")
  
  ftRec = orb:narrow(ftRec)
  local connId = ftRec:connect("IFaultTolerantService",ftacsService)
  if not connId then
	Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTACSMonitor")
    os.exit(1)
  end
 
  -- Configura��es
  ftacsInst.IComponent.startup = FTAccessControlServiceMonitor.startup
    
  local ftacs = ftacsInst.IFTAccessControlServiceMonitor
  ftacs.config = AccessControlServerConfiguration
  ftacs.recConnId = connId

  -- Inicializa��o
  success, res = oil.pcall(ftacsInst.IComponent.startup, ftacsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o monitor do servi�o de controle de acesso: "..
        tostring(res).."\n")
    os.exit(1)
  end  
  
  Log:faulttolerance("Monitor do servico de controle de acesso iniciado com sucesso")

  local success, res = oil.pcall(oil.newthread, ftacs.monitor, ftacs)

  if not success then
    Log:error("Falha na execu��o do Monitor do Servico de Controle de Acesso: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:faulttolerance("Monitor do servico de controle monitorando com sucesso.")


end

print(oil.pcall(oil.main,main))