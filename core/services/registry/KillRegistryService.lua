-- $Id

local ipairs = ipairs
local tonumber = tonumber

local Log = require "openbus.util.Log"
local Openbus = require "openbus.Openbus"
local oil = require "oil"
local Utils = require "openbus.util.Utils"
local Utils = require "openbus.util.Utils"

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
  --port=<port number>     : defines the port of the service to to inject fault (default=]]
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

-- Inicializa o ORB
local orb = oil.init {
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

orb:loadidlfile(IDLPATH_DIR.."/v"..Utils.OB_VERSION.."/fault_tolerance.idl")

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  Log:faulttolerance("Injetando falha no Serviço de Registro inicio...")

  Log:faulttolerance("corbaloc::"..hostAdd.."/"..Utils.FAULT_TOLERANT_RS_KEY)



  Openbus:init(RegistryServerConfiguration.accessControlServerHostName,
               RegistryServerConfiguration.accessControlServerHostPort)
  Openbus:_setInterceptors()
  Openbus:enableFaultTolerance()

  local ftregistryService = Openbus:getORB():newproxy("corbaloc::"..hostAdd.."/"..Utils.FAULT_TOLERANT_RS_KEY,
               Utils.FAULT_TOLERANT_SERVICE_INTERFACE)
  if ftregistryService:_non_existent() then
      Log:error("Servico de registro nao encontrado.")
      os.exit(1)
  end

  -- autentica o monitor, conectando-o ao barramento
  Openbus:connectByCertificate("RGSMonitor",
      DATA_DIR.."/"..RegistryServerConfiguration.monitorPrivateKeyFile,
      DATA_DIR.."/"..RegistryServerConfiguration.accessControlServiceCertificateFile)

  if Openbus:isConnected() then
     ftregistryService:setStatus(false)
     Log:faulttolerance("Injetou falha no Servico de Registro -- fim.")
  else
     Log:faulttolerance("Erro ao se logar no barramento.")
  end

  os.exit(0)

end

print(oil.pcall(oil.main,main))

