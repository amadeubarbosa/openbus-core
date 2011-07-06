-- $Id

---
--Inicialização do Monitor do Serviço de Controle de Acesso com Tolerancia a Falhas
---
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local print = print

local format = string.format

local Log = require "openbus.util.Log"
local Openbus = require "openbus.Openbus"
local Utils = require "openbus.util.Utils"
local oil = require "oil"
local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"

local ComponentContext = require "scs.core.ComponentContext"

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

-- Parsing arguments
local usage_msg = [[
    --help                   : show this help
    --verbose  (v)          : turn ON the VERBOSE mode (show the system commands)
    --port=<port number>     : defines the port of the service to be monitored (default=]]
                                .. tostring(AccessControlServerConfiguration.hostPort) .. [[)
 NOTES:
    The prefix '--' is optional in all options.
    So '--help' or '-help' or yet 'help' all are the same option.]]
local arguments = Utils.parse_args(arg,usage_msg,true)

if arguments.verbose == "" or arguments.v == ""  then
    oil.verbose:level(3)
    Log:level(5)
else
    if AccessControlServerConfiguration.oilVerboseLevel then
        oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
    end
    -- Define os níveis de verbose para o OpenBus e para o OiL.
    if AccessControlServerConfiguration.logLevel then
        Log:level(AccessControlServerConfiguration.logLevel)
    else
        Log:level(1)
    end
end

if arguments.port then
    AccessControlServerConfiguration.hostPort = tonumber(arguments.port)
else
    Log:warn("Será usada porta padrão do ACS")
end

local hostAdd = AccessControlServerConfiguration.hostName..":"..
                AccessControlServerConfiguration.hostPort

local props = { host = AccessControlServerConfiguration.hostName,
  port = AccessControlServerConfiguration.hostPort}

Openbus:init(AccessControlServerConfiguration.hostName,
  AccessControlServerConfiguration.hostPort)

local iConfig = assert(loadfile(DATA_DIR ..
      "/conf/advanced/InterceptorsConfiguration.lua"))()
local miConfig = assert(loadfile(DATA_DIR ..
      "/conf/advanced/MonitorInterceptorsConfiguration.lua"))()

local orb = Openbus:getORB()

local FTAccessControlServiceMonitor = require "core.services.accesscontrol.FTAccessControlServiceMonitor"

orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/fault_tolerance.idl")

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

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

  -- Cria o componente responsável pelo Monitor do Serviço de Controle de Acesso
  local componentId = {}
  componentId.name = "ACSMonitor"
  componentId.major_version = 1
  componentId.minor_version = 0
  componentId.patch_version = 0
  componentId.platform_spec = ""

  local keys = {}
  keys.IComponent = "IC"

  local ftacsInst = ComponentContext(Openbus:getORB(), componentId, keys)
  ftacsInst:addFacet("IFTServiceMonitor",
                      Utils.FT_SERVICE_MONITOR_INTERFACE,
                      FTAccessControlServiceMonitor.FTACSMonitorFacet(),
                      "FTACSMonitor")
  ftacsInst:addReceptacle("IFaultTolerantService",
                          Utils.FAULT_TOLERANT_SERVICE_INTERFACE,
                          false,
                          "Receptacle")

  ftacsInst.IComponent.startup = FTAccessControlServiceMonitor.startup

  local ftacs = ftacsInst.IFTServiceMonitor
  ftacs.config = AccessControlServerConfiguration

  -- Inicialização
  success, res = oil.pcall(ftacsInst.IComponent.startup, ftacsInst.IComponent)
  if not success then
    Log:error(format(
        "Falha ao iniciar o monitor do serviço de controle de acesso: %s",
        tostring(res)))
    os.exit(1)
  end

  local success, res = oil.pcall(oil.newthread, ftacs.monitor, ftacs)

  if not success then
    Log:error(format(
        "Falha na execução do monitor do servico de controle de acesso: %s",
        tostring(res)))
    os.exit(1)
  end
  Log:info("O monitor do serviço de controle de acesso foi iniciado com sucesso")
end

print(oil.pcall(oil.main,main))

