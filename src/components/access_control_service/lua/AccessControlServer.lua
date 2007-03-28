--
-- Inicializa��o do Servi�o de Controle de Acesso
--
-- $Id$
--
require "oil"
require "AccessControlServiceComponent"

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
local config = 
  assert(loadfile(CONF_DIR.."/AccessControlServerConfiguration.lua"))()
oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel or 1)

-- Carrega a interface do servi�o
local idlfile = CORBA_IDL_DIR.."/access_control_service_oil.idl"
oil.loadidlfile (idlfile)

-- Inicializa o ORB, fixando a localiza��o do servi�o em porta espec�fica
oil.init{host = AccessControlServerConfiguration.hostName, 
         port = AccessControlServerConfiguration.hostPort}

function main()
  -- Aloca uma thread para o orb
  local success, res  = oil.pcall(oil.newthread,oil.run)
  if not success then
    print("Falha na execu��o da thread do orb: ", res)
    os.exit(1)
  end

  -- Cria o componente respons�vel pelo Servi�o de Controle de Acesso
  local accessControlServiceComponent = AccessControlServiceComponent{
    name = "AccessControlService",
  }
  success, res  = 
    oil.pcall(oil.newobject ,accessControlServiceComponent, 
              "IDL:OpenBus/ACS/IAccessControlServiceComponent:1.0", "ACS")
  if not success then
    print("Falha na cria��o do AcessControlServiceComponent: ", res)
    os.exit(1)
  end
  accessControlServiceComponent = res

  success, res = oil.pcall(accessControlServiceComponent.startup, 
                           accessControlServiceComponent, 
                           AccessControlServerConfiguration.ldapHostName, 
                           AccessControlServerConfiguration.databaseDirectory)
  if not success then
    print("Falha na inicializa��o do AcessControlServiceComponent: ", res)
    os.exit(1)
  end
end

print(oil.pcall(oil.main,main))
