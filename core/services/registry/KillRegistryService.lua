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
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/RegistryServerConfiguration.lua"))()

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

orb:loadidlfile(IDLPATH_DIR.."/v1_05/fault_tolerance.idl")

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  Log:faulttolerance("Injetando falha no Serviço de Registro inicio...")

  Log:faulttolerance("corbaloc::"..hostAdd.."/FTRS")



  Openbus:init(RegistryServerConfiguration.accessControlServerHostName,
               RegistryServerConfiguration.accessControlServerHostPort)
  Openbus:_setInterceptors()
  Openbus:enableFaultTolerance()

  local ftregistryService = Openbus:getORB():newproxy("corbaloc::"..hostAdd.."/FTRS",
               "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0")
  if ftregistryService:_non_existent() then
      Log:error("Servico de registro nao encontrado.")
      os.exit(1)
  end

  -- autentica o monitor, conectando-o ao barramento
  Openbus:connectByCertificate("RGSMonitor",
      DATA_DIR.."/"..RegistryServerConfiguration.monitorPrivateKeyFile,
      DATA_DIR.."/"..RegistryServerConfiguration.accessControlServiceCertificateFile)

  ftregistryService:setStatus(false)

  Log:faulttolerance("Injetou falha no Servico de Registro -- fim.")

  os.exit(0)

end

print(oil.pcall(oil.main,main))

