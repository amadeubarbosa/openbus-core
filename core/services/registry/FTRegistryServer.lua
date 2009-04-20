-----------------------------------------------------------------------------
-- Inicialização do Serviço de Registro Tolerante a Falhas
-----------------------------------------------------------------------------
local oil = require "oil"

local Log = require "openbus.common.Log"

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
RegistryServerConfiguration.registryServerHostPort = tonumber(hostPort)

RegistryServerConfiguration.registryServerHost = 
    RegistryServerConfiguration.registryServerHostName..":"..
    RegistryServerConfiguration.registryServerHostPort

print(RegistryServerConfiguration.registryServerHost)
-- Inicializa o ORB, fixando a localização do serviço em uma porta específica
local orb = oil.init { host = RegistryServerConfiguration.registryServerHostName,
                       port = RegistryServerConfiguration.registryServerHostPort,
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

local RegistryService = require "core.services.registry.RegistryService"

print(RegistryServerConfiguration.registryServerHost)


-- Carrega a interface do serviço
local idlfile = IDLPATH_DIR.."/registry_service.idl"
orb:loadidlfile(idlfile)
idlfile = IDLPATH_DIR.."/access_control_service.idl"
orb:loadidlfile(idlfile)

function main()
  -- Aloca uma thread para o orb
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execução do ORB: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente responsável pelo Serviço de Registro
  success, res = oil.pcall(orb.newservant, orb, 
			RegistryService("RegistryService",
			RegistryServerConfiguration), 
			"RS", 
			"IDL:openbusidl/rs/IRegistryService:1.0")
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
