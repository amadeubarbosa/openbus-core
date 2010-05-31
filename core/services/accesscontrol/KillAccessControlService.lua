-- $Id

local ipairs = ipairs
local tonumber = tonumber

local Log = require "openbus.util.Log"
local Openbus = require "openbus.Openbus"
local oil = require "oil"
local Utils = require "openbus.util.Utils"

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")

if IDLPATH_DIR == nil then
  Log:error("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end


local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(0)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/AccessControlServerConfiguration.lua"))()

-- Parsing arguments
local usage_msg = [[
    --help                   : show this help
    --verbose (v)            : turn ON the VERBOSE mode (show the system commands)
    --port=<port number>     : defines the port of the service to inject fault (default=]]
                                .. tostring(AccessControlServerConfiguration.hostPort) .. [[)
 NOTES:
    The prefix '--' is optional in all options.
    So '--help' or '-help' or yet 'help' all are the same option.]]
local arguments = Utils.parse_args(arg,usage_msg,true)

if arguments.verbose == "" or arguments.v == "" then
    oil.verbose:level(5)
    Log:level(3)
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
print(arguments.port)
if arguments.port then
    AccessControlServerConfiguration.hostPort = tonumber(arguments.port)
else
    Log:warn("Será usada porta padrão do ACS")
end

local acsAdd = "corbaloc::"..AccessControlServerConfiguration.hostName..":"
                ..AccessControlServerConfiguration.hostPort

-- Inicializa o ORB
local orb = oil.init {
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

orb:loadidlfile(IDLPATH_DIR.."/v1_05/fault_tolerance.idl")

---
--FunÃ§Ã£o que serÃ¡ executada pelo OiL em modo protegido.
---
function main()
  Log:faulttolerance("Injetando falha no ACS inicio...")

  Log:faulttolerance(acsAdd)

  local config = AccessControlServerConfiguration
  Openbus:init(config.hostName, config.hostPort)
  Openbus.isFaultToleranceEnable = false
  Openbus:_setInterceptors()
  -- autentica o monitor, conectando-o ao barramento
  Openbus:connectByCertificate("ACSMonitor",
      DATA_DIR.."/"..config.monitorPrivateKeyFile,
      DATA_DIR.."/"..config.accessControlServiceCertificateFile)

  if Openbus:isConnected() then
     Openbus.ft:setStatus(false)
     Log:faulttolerance("Injetou falha no ACS -- fim.")
  else
     Log:faulttolerance("Erro ao se logar no barramento.")
  end

  os.exit(1)

end

print(oil.pcall(oil.main,main))

