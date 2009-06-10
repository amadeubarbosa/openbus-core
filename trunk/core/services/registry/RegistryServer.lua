-----------------------------------------------------------------------------
-- Inicialização do Serviço de Registro
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local Log = require "openbus.common.Log"
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

RegistryServerConfiguration.accessControlServerHost = 
    RegistryServerConfiguration.accessControlServerHostName..":"..
    RegistryServerConfiguration.accessControlServerHostPort

-- Seta os níveis de verbose para o openbus e para o oil
if RegistryServerConfiguration.logLevel then
  Log:level(RegistryServerConfiguration.logLevel)
end
if RegistryServerConfiguration.oilVerboseLevel then
  oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel)
end



-- Inicializa o ORB
local orb = oil.init { host = RegistryServerConfiguration.registryServerHostName,
                       port = RegistryServerConfiguration.registryServerHostPort,
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }
oil.orb = orb

local scs = require "scs.core.base"


-- Inicialização do nível de verbose do openbus.
Log:level(4)

local RegistryService = require "core.services.registry.RegistryService"
local FaultTolerantService = require "core.services.faulttolerance.FaultTolerantService"


-- Carrega a interface do serviço
local idlfile = IDLPATH_DIR.."/registry_service.idl"
orb:loadidlfile(idlfile)
idlfile = IDLPATH_DIR.."/access_control_service.idl"
orb:loadidlfile(idlfile)
idlfile = IDLPATH_DIR.."/ft_service.idl"
orb:loadidlfile(idlfile)

-----------------------------------------------------------------------------
---- RegistryService Descriptions
-------------------------------------------------------------------------------

---- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent       = {}
facetDescriptions.IMetaInterface   = {}
facetDescriptions.IRegistryService = {}
facetDescriptions.IFaultTolerantService	= {}

facetDescriptions.IComponent.name                  = "IComponent"
facetDescriptions.IComponent.interface_name        = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                 = scs.Component

facetDescriptions.IMetaInterface.name              = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name    = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class             = scs.MetaInterface

facetDescriptions.IRegistryService.name            = "IRegistryService"
facetDescriptions.IRegistryService.interface_name  = "IDL:openbusidl/rs/IRegistryService:1.0"
facetDescriptions.IRegistryService.class           = RegistryService.RSFacet

facetDescriptions.IFaultTolerantService.name                  = "IFaultTolerantService"
facetDescriptions.IFaultTolerantService.interface_name        = "IDL:openbusidl/ft/IFaultTolerantService:1.0"
facetDescriptions.IFaultTolerantService.class                 = FaultTolerantService.FaultToleranceFacet
facetDescriptions.IFaultTolerantService.key                   = "FTRS"

---- Receptacle Descriptions
local receptacleDescriptions = {}

---- component id
local componentId = {}
componentId.name = "RegistryService"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

function main()
  -- Aloca uma thread para o orb
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execução do ORB: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente responsï¿½vel pelo Serviï¿½o de Registro
  rsInst = scs.newComponent(facetDescriptions, receptacleDescriptions, componentId)

  -- Configuracoes
  rsInst.IComponent.startup = RegistryService.startup
  rsInst.IComponent.shutdown = RegistryService.shutdown

  local rs = rsInst.IRegistryService
  rs.config = RegistryServerConfiguration

  success, res = oil.pcall (rsInst.IComponent.startup, rsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o serviço de registro: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Serviço de registro iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
