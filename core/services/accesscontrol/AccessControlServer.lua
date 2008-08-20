-- $Id$

---
--Inicialização do Serviço de Controle de Acesso
---

local Log = require "openbus.common.Log"

local oil = require "oil"

local CORE_IDL_DIR = os.getenv("CORE_IDL_DIR")
if CORE_IDL_DIR == nil then
  Log:error("A variavel CORE_IDL_DIR nao foi definida.\n")
  os.exit(1)
end

local CONF_DIR = os.getenv("CONF_DIR")
if CONF_DIR == nil then
  Log:error("A variavel CONF_DIR nao foi definida.\n")
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(CONF_DIR.."/AccessControlServerConfiguration.lua"))()

-- Define os níveis de verbose para o OpenBus e para o OiL.
if AccessControlServerConfiguration.logLevel then
  Log:level(AccessControlServerConfiguration.logLevel)
end
if AccessControlServerConfiguration.oilVerboseLevel then
  oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
end

-- Inicializa o ORB, fixando a localização do serviço em uma porta específica
local orb = oil.init { host = AccessControlServerConfiguration.hostName,
                       port = AccessControlServerConfiguration.hostPort,
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

local AccessControlService = require "core.services.accesscontrol.AccessControlService"

orb:loadidlfile(CORE_IDL_DIR.."/access_control_service.idl")

---
--Função que será executada pelo OiL em modo protegido.
---
function main()
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execução do ORB: "..tostring(res).."\n")
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
    Log:error("Falha ao iniciar o serviço de controle de acesso: "..
        tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Serviço de controle de acesso iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
