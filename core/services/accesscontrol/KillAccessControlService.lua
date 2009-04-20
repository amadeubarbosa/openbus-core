-- $Id

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
print(AccessControlServerConfiguration.hostName)
print(AccessControlServerConfiguration.hostPort)

local acsAdd = "corbaloc::"..AccessControlServerConfiguration.hostName..":"..AccessControlServerConfiguration.hostPort.."/ACS"

-- Inicializa o ORB
local orb = oil.init {
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

local AccessControlService = require "core.services.accesscontrol.AccessControlService"


orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")
print(IDLPATH_DIR.."/access_control_service.idl")

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execucão do ORB: "..tostring(res).."\n")
    os.exit(1)
  end

  Log:faulttolerance("Injetando falha no ACS inicio...")

  Log:faulttolerance(acsAdd)

  local acs = orb:newproxy(acsAdd,"IDL:openbusidl/acs/IAccessControlService:1.0")
  if acs:_non_existent() then
      Log:error("Servico de controle de acesso nao encontrado.")
      os.exit(1)
  end

  acs:setStatus(false)

  Log:faulttolerance("Injetando falha no ACS fim.")

  os.exit(1)

end

print(oil.pcall(oil.main,main))

