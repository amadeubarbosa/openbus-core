-- $Id

local ipairs = ipairs
local tonumber = tonumber

local format = string.format

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
if arguments.port then
    AccessControlServerConfiguration.hostPort = tonumber(arguments.port)
else
    Log:warn("Será usada porta padrão do ACS")
end

local acsAdd = "corbaloc::"..AccessControlServerConfiguration.hostName..":"
                ..AccessControlServerConfiguration.hostPort

local props = { host = AccessControlServerConfiguration.hostName,
  port = AccessControlServerConfiguration.hostPort}

-- Inicializa o barramento
Openbus:init(AccessControlServerConfiguration.hostName,
  AccessControlServerConfiguration.hostPort)

local orb = Openbus:getORB()
orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_VERSION.."/fault_tolerance.idl")

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  Log:info(format(
      "Injetando falha no Serviço de Controle de Acesso localizado em %s",
      acsAdd))

  -- autentica o monitor, conectando-o ao barramento
  Openbus:connectByCertificate("ACSMonitor",
      DATA_DIR.."/"..AccessControlServerConfiguration.monitorPrivateKeyFile,
      DATA_DIR.."/"..AccessControlServerConfiguration.accessControlServiceCertificateFile)

  if Openbus:isConnected() then
     Openbus.ft:setStatus(false)
     Log:info(format(
      "A falha foi injetada no Serviço de Controle de Acesso localizado em %s",
      acsAdd))
  else
     Log:error(
         "Ocorreu um erro ao fazer a conexão com o serviço de controle de acesso")
  end

  Openbus:destroy()
  os.exit(1)

end

print(oil.pcall(oil.main,main))

