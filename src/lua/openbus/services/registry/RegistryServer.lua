-----------------------------------------------------------------------------
-- Inicializa��o do Servi�o de Registro
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
require "oil"

require "openbus.services.registry.RegistryService"

local log = require "openbus.common.Log"

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
    log:error("A variavel CORBA_IDL_DIR nao foi definida.\n")
    os.exit(1)
end

local CONF_DIR = os.getenv("CONF_DIR")
if CONF_DIR == nil then
    log:error("A variavel CONF_DIR nao foi definida.\n")
    os.exit(1)
end

-- Obt�m a configura��o do servi�o
assert(loadfile(CONF_DIR.."/RegistryServerConfiguration.lua"))()

RegistryServerConfiguration.accessControlServerHost = 
  RegistryServerConfiguration.accessControlServerHostName..":"..
  RegistryServerConfiguration.accessControlServerHostPort

-- Seta os n�veis de verbose para o openbus e para o oil
if RegistryServerConfiguration.logLevel then
  log:level(RegistryServerConfiguration.logLevel)
end
if RegistryServerConfiguration.oilVerboseLevel then
  oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel)
end

-- Carrega a interface do servi�o
local idlfile = CORBA_IDL_DIR.."/registry_service.idl"
oil.loadidlfile (idlfile)
idlfile = CORBA_IDL_DIR.."/access_control_service.idl"
oil.loadidlfile (idlfile)

function main()
  -- Aloca uma thread para o orb
  local success, res = oil.pcall(oil.newthread,oil.run)
  if not success then
    log:error("Falha na execu��o da thread do orb: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente respons�vel pelo Servi�o de Registro
  success, res = oil.pcall(oil.newobject,
    RegistryService("RegistryService"), 
    "IDL:openbusidl/rs/IRegistryService:1.0")
  if not success then
    log:error("Falha criando RegistryService: "..tostring(res).."\n")
    os.exit(1)
  end

  local registryService = res
  success, res = oil.pcall (registryService.startup, registryService)
  if not success then
    log:error("Falha ao iniciar o servi�o de registro: "..tostring(res).."\n")
    os.exit(1)
  end
  log:init("Servi�o de registro iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
