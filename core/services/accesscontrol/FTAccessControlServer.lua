-- $Id

---
--Inicialização do Serviço de Controle de Acesso com Tolerancia a Falhas
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
--print(AccessControlServerConfiguration.hostPort)

-- Inicializa o ORB, fixando a localização do serviço em uma porta específica
local orb = oil.init { host = AccessControlServerConfiguration.hostName,
                       port = AccessControlServerConfiguration.hostPort,
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")

local AccessControlService = require "core.services.accesscontrol.AccessControlService"


---
--Função que será executada pelo OiL em modo protegido.
---
function main()

  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execucão do ORB: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente responsável pelo Serviço de Controle de Acesso
  success, res  = oil.pcall(orb.newservant, orb,
      AccessControlService("AccessControlService",
      AccessControlServerConfiguration),
      "ACS",
      "IDL:openbusidl/acs/IAccessControlService:1.0")
  if not success then
    Log:error("Falha criando o AcessControlService: "..tostring(res).."\n")
    os.exit(1)
  end


  local accessControlService = res
  success, res = oil.pcall(accessControlService.startup, accessControlService)
  if not success then
    Log:error("Falha ao iniciar o servico de controle de acesso: "..
        tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Servico de controle de acesso iniciado com sucesso")

end

print(oil.pcall(oil.main,main))
