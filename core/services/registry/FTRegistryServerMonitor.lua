-- $Id

---
--Inicialização do Monitor do Serviço de registro com Tolerancia a Falhas
---
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring

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
RegistryServerConfiguration.accessControlServerHostPort = tonumber(hostPort)

RegistryServerConfiguration.accessControlServerHost = 
    RegistryServerConfiguration.accessControlServerHostName..":"..hostPort
    
local hostAdd = RegistryServerConfiguration.accessControlServerHost


-- Inicializa o ORB
local orb = oil.init { 
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }
oil.orb = orb

local RegistryService = require "core.services.registry.RegistryService"


local FTRegistryServiceMonitor = require "core.services.registry.FTRegistryServiceMonitor"


orb:loadidlfile(IDLPATH_DIR.."/registry_service.idl")

orb:loadidlfile(IDLPATH_DIR.."/ft_registry_service_monitor.idl")

---
--Função que será executada pelo OiL em modo protegido.
---
function main()

  local registryService = orb:newproxy("corbaloc::"..hostAdd.."/RS",
                             "IDL:openbusidl/rs/IRegistryService:1.0")
  if registryService:_non_existent() then
      Log:error("Servico de registro nao encontrado.")
      os.exit(1)
  end

  local registryServiceMonitor = FTRegistryServiceMonitor("FTRegistryServiceMonitor",
							   RegistryServerConfiguration, 
							   registryService)
  registryServiceMonitor:startup()

  Log:init("Monitor do servico de registro iniciado com sucesso")
  local success, res = oil.pcall(oil.newthread, 
				registryServiceMonitor.monitor, 
				registryServiceMonitor)
  if not success then
    Log:error("Falha na execucão do Monitor do Servico de registro: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:faulttolerance("Monitor do servico de registro monitorando com sucesso.")

  --Usado para testar se o monitor levanta um novo serviço quando em estado de falha
  --registryService.faultDescription._isAlive = false
  

end

print(oil.pcall(oil.main,main))
