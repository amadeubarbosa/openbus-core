-----------------------------------------------------------------------------
-- Inicialização do Serviço de Registro
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local oil = require "oil"

-- Inicializa o ORB
local orb = oil.init { flavor = "intercepted;corba;typed;cooperative;base", }
oil.orb = orb

local Log = require "openbus.common.Log"

local RegistryService = require "core.services.registry.RegistryService"

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
assert(loadfile(CONF_DIR.."/RegistryServerConfiguration.lua"))()

RegistryServerConfiguration.accessControlServerHost = 
    RegistryServerConfiguration.accessControlServerHostName..":"..
    RegistryServerConfiguration.accessControlServerHostPort

-- Seta os níveis de verbose para o openbus e para o oil
if RegistryServerConfiguration.logLevel then
  Log:level(RegistryServerConfiguration.logLevel)
end
if RegistryServerConfiguration.oilVerboseLevel then
  oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel)
end

-- Carrega a interface do serviço
local idlfile = CORE_IDL_DIR.."/registry_service.idl"
orb:loadidlfile(idlfile)
idlfile = CORE_IDL_DIR.."/access_control_service.idl"
orb:loadidlfile(idlfile)

function main()
  -- Aloca uma thread para o orb
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execução do ORB: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente responsável pelo Serviço de Registro
  success, res = oil.pcall(orb.newservant, orb, RegistryService("RegistryService",
      RegistryServerConfiguration), nil, "IDL:openbusidl/rs/IRegistryService:1.0")
  if not success then
    Log:error("Falha criando RegistryService: "..tostring(res).."\n")
    os.exit(1)
  end

  local registryService = res
  success, res = oil.pcall (registryService.startup, registryService)
  if not success then
    Log:error("Falha ao iniciar o serviço de registro: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Serviço de registro iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
