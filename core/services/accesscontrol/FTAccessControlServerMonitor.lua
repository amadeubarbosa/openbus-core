-- $Id

---
--Inicialização do Monitor do Serviço de Controle de Acesso com Tolerancia a Falhas
---
local ipairs = ipairs
local tonumber = tonumber

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

local addr = "corbaloc::"..AccessControlServerConfiguration.hostName..":"..AccessControlServerConfiguration.hostPort.."/ACS"


-- Inicializa o ORB, fixando a localização do serviço em uma porta específica
local orb = oil.init {  flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

local AccessControlService = require "core.services.accesscontrol.AccessControlService"

local FTAccessControlServiceMonitor = require "core.services.accesscontrol.FTAccessControlServiceMonitor"


orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")

orb:loadidlfile(IDLPATH_DIR.."/ft_access_control_service_monitor.idl")


---
--Função que será executada pelo OiL em modo protegido.
---
function main()

  local accessControlService = orb:newproxy(addr,"IDL:openbusidl/acs/IAccessControlService:1.0")
  if accessControlService:_non_existent() then
      Log:error("Servico de controle de acesso nao encontrado.")
      os.exit(1)
  end

  local ftacs = FTAccessControlServiceMonitor("FTAccessControlServiceMonitor", 
						AccessControlServerConfiguration, 
						accessControlService)
  ftacs:startup()
  Log:init("Monitor do servico de controle de acesso iniciado com sucesso")

  local success, res = oil.pcall(oil.newthread, ftacs.monitor, ftacs)

  if not success then
    Log:error("Falha na execucão do Monitor do Servico de Controle de Acesso: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:faulttolerance("Monitor do servico de controle monitorando com sucesso.")

  --Usado para testar se o monitor levanta um novo serviço quando em estado de falha
  --accessControlService.faultDescription._isAlive = false
  

end

print(oil.pcall(oil.main,main))
