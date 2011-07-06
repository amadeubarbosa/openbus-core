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
local ComponentContext = require "scs.core.ComponentContext"
local Openbus = require "openbus.Openbus"
local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local FTRegistryServiceMonitor = require "core.services.registry.FTRegistryServiceMonitor"

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
  oil.verbose:level(3)
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

local iConfig = assert(loadfile(DATA_DIR ..
      "/conf/advanced/InterceptorsConfiguration.lua"))()
local miConfig = assert(loadfile(DATA_DIR ..
      "/conf/advanced/MonitorInterceptorsConfiguration.lua"))()

local orb = Openbus:getORB()

orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/fault_tolerance.idl")

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  Openbus:__fetchACS()
  --(Maira) Esse require está aqui porque acessa a classe Openbus que é usada como "singleton"
  --O problema é que se o require é feito antes de a classe Openbus tiver sido iniciada, o compilador reclama o seu uso
  --Isso explica porque os requires do ClientInterceptor e ServerInterceptor estão dentro de Openbus:init
  --TODO: Achar uma solução melhor para esse problema
  local SameProcessServerInterceptor = require "openbus.interceptors.SameProcessServerInterceptor"
  local serverInterceptor = SameProcessServerInterceptor:__init(iConfig, Openbus.acs,
                                                         Openbus.credentialValidationPolicy,
                                                         miConfig, Openbus.credentialManager)
  Openbus:_setServerInterceptor(serverInterceptor)
  local clientInterceptor = ClientInterceptor(iConfig, Openbus.credentialManager)
  Openbus:_setClientInterceptor( clientInterceptor )

  -- Cria o componente responsável pelo Monitor do Serviço de Registro
  local componentId = {}
  componentId.name = "RGSMonitor"
  componentId.major_version = 1
  componentId.minor_version = 0
  componentId.patch_version = 0
  componentId.platform_spec = ""

  local keys = {}
  keys.IComponent = "IC"

  local ftrsInst = ComponentContext(orb, componentId, keys)
  ftrsInst:addFacet("IFTServiceMonitor_" .. Utils.IDL_VERSION,
                    Utils.FT_SERVICE_MONITOR_INTERFACE,
                    FTRegistryServiceMonitor.FTRSMonitorFacet(),
                    FT_RS_MONITOR_KEY)
  ftrsInst:addReceptacle("IFaultTolerantService", Utils.FAULT_TOLERANT_SERVICE_INTERFACE, false)

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
  Log:info("O monitor do serviço de registro foi iniciado com sucesso.")
end

print(oil.pcall(oil.main,main))
