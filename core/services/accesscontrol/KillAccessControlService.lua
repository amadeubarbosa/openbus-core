-- $Id

local ipairs = ipairs
local tonumber = tonumber

local Log = require "openbus.util.Log"
local Openbus = require "openbus.Openbus"
local oil = require "oil"

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


-- Define os níveis de verbose para o OpenBus e para o OiL.
if AccessControlServerConfiguration.logLevel then
  Log:level(AccessControlServerConfiguration.logLevel)
end
if AccessControlServerConfiguration.oilVerboseLevel then
  oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
end

local hostPort = arg[1]
if hostPort == nil then
   Log:error("É necessario passar o numero da porta.\n")
    os.exit(1)
end
AccessControlServerConfiguration.hostPort = tonumber(hostPort)
print(AccessControlServerConfiguration.hostName)
print(AccessControlServerConfiguration.hostPort)

local acsAdd = "corbaloc::"..AccessControlServerConfiguration.hostName..":"..AccessControlServerConfiguration.hostPort

-- Inicializa o ORB
local orb = oil.init {
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

orb:loadidlfile(IDLPATH_DIR.."/fault_tolerance.idl")

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
  Openbus:connectByCertificate("FTAccessControlServiceMonitor",
      DATA_DIR.."/"..config.monitorPrivateKeyFile,
      DATA_DIR.."/"..config.accessControlServiceCertificateFile)

  Openbus.ft:setStatus(false)

  Log:faulttolerance("Injetou falha no ACS -- fim.")

  os.exit(1)

end

print(oil.pcall(oil.main,main))

