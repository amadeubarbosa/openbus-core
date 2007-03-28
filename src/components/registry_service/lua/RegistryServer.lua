--
-- Inicializa��o do Servi�o de Registro
--
-- $Id$
--
require "oil"
require "RegistryServiceComponent"

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
    io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
    os.exit(1)
end

local CONF_DIR = os.getenv("CONF_DIR")
if CONF_DIR == nil then
    io.stderr:write("A variavel CONF_DIR nao foi definida.\n")
    os.exit(1)
end

-- Obt�m a configura��o do servi�o
local config = assert(loadfile(CONF_DIR.."/RegistryServerConfiguration.lua"))()
oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel or 1)
RegistryServerConfiguration.accessControlServerHost = 
  RegistryServerConfiguration.accessControlServerHostName..":"..
  RegistryServerConfiguration.accessControlServerHostPort

-- Carrega a interface do servi�o
local idlfile = CORBA_IDL_DIR.."/registry_service.idl"
oil.loadidlfile (idlfile)

function main()
  -- Aloca uma thread para o orb
  local success, res = oil.pcall(oil.newthread,oil.run)
  if not success then
    print("Falha na execu��o da thread do orb: ",res)
    os.exit(1)
  end

  -- Cria o componente respons�vel pelo Servi�o de Registro
  local registryServiceComponent = RegistryServiceComponent{
    name = "RegistryService",
    accessControlServerHost = 
      RegistryServerConfiguration.accessControlServerHost,
    accessControlServerKey = 
      RegistryServerConfiguration.accessControlServerKey,
  }

  success, res = oil.pcall(oil.newobject, registryServiceComponent, 
                           "IDL:OpenBus/RS/IRegistryServiceComponent:1.0")
  if not success then
    print("Falha na cria��o do RegistryServiceComponent: ",res)
    os.exit(1)
  end
  registryServiceComponent = res

  success, res = oil.pcall (registryServiceComponent.startup, 
                            registryServiceComponent)
  if not success then
    print("Erro ao iniciar o servi�o de registro: ", res)
    os.exit(1)
  end
end

print(oil.pcall(oil.main,main))
