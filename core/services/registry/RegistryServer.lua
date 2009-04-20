-----------------------------------------------------------------------------
-- Inicializa��o do Servi�o de Registro
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
local oil = require "oil"

-- Inicializa o ORB
local orb = oil.init { flavor = "intercepted;corba;typed;cooperative;base", }
oil.orb = orb

local Log = require "openbus.common.Log"

-- Inicializa��o do n�vel de verbose do openbus.
Log:level(1)

local RegistryService = require "core.services.registry.RegistryService"

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

-- Obt�m a configura��o do servi�o
assert(loadfile(DATA_DIR.."/conf/RegistryServerConfiguration.lua"))()

RegistryServerConfiguration.registryServerHost = 
    RegistryServerConfiguration.registryServerHostName..":"..
    RegistryServerConfiguration.registryServerHostPort

-- Seta os n�veis de verbose para o openbus e para o oil
if RegistryServerConfiguration.logLevel then
  Log:level(RegistryServerConfiguration.logLevel)
end
if RegistryServerConfiguration.oilVerboseLevel then
  oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel)
end

-- Carrega a interface do servi�o
local idlfile = IDLPATH_DIR.."/registry_service.idl"
orb:loadidlfile(idlfile)
idlfile = IDLPATH_DIR.."/access_control_service.idl"
orb:loadidlfile(idlfile)

function main()
  -- Aloca uma thread para o orb
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execu��o do ORB: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente respons�vel pelo Servi�o de Registro
  success, res = oil.pcall(orb.newservant, orb, RegistryService("RegistryService",
      RegistryServerConfiguration), nil, "IDL:openbusidl/rs/IRegistryService:1.0")
  if not success then
    Log:error("Falha criando RegistryService: "..tostring(res).."\n")
    os.exit(1)
  end

  local registryService = res
  success, res = oil.pcall (registryService.startup, registryService)
  if not success then
    Log:error("Falha ao iniciar o servi�o de registro: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Servi�o de registro iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
