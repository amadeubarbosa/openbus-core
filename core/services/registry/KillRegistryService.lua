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
assert(loadfile(DATA_DIR.."/conf/RegistryServerConfiguration.lua"))()


local hostPort = arg[1]
if hostPort == nil then
   Log:error("É necessario passar o numero da porta.\n")
    os.exit(1)
end
RegistryServerConfiguration.accessControlServerHostPort = tonumber(hostPort)

RegistryServerConfiguration.accessControlServerHost = 
    RegistryServerConfiguration.accessControlServerHostName..":"..
    RegistryServerConfiguration.accessControlServerHostPort


-- Inicializa o ORB
local orb = oil.init {
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

local RegistryService = require "core.services.registry.RegistryService"


orb:loadidlfile(IDLPATH_DIR.."/registry_service.idl")

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execucão do ORB: "..tostring(res).."\n")
    os.exit(1)
  end

  Log:faulttolerance("Injetando falha no Serviço de Registro inicio...")

  Log:faulttolerance("corbaloc::"..RegistryServerConfiguration.accessControlServerHost.."/RS")

  local registry = orb:newproxy("corbaloc::"..RegistryServerConfiguration.accessControlServerHost.."/RS",
                             "IDL:openbusidl/rs/IRegistryService:1.0")
  if registry:_non_existent() then
      Log:error("Servico de registro nao encontrado.")
      os.exit(1)
  end

  registry:setStatus(false)

  Log:faulttolerance("Injetando falha no Servico de Registro fim.")

  os.exit(1)

end

print(oil.pcall(oil.main,main))

