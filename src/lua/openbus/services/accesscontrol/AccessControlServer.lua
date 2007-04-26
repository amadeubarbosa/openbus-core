-----------------------------------------------------------------------------
-- Inicialização do Serviço de Controle de Acesso
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "oil"

require "openbus.services.accesscontrol.AccessControlServiceComponent"

local log = require "openbus.common.Log"

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

-- Obtém a configuração do serviço
assert(loadfile(CONF_DIR.."/AccessControlServerConfiguration.lua"))()

-- Seta os níveis de verbose para o openbus e para o oil
if AccessControlServerConfiguration.logLevel then
  log:level(AccessControlServerConfiguration.logLevel)
end
if AccessControlServerConfiguration.oilVerboseLevel then
  oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
end

-- Carrega a interface do serviço
local idlfile = CORBA_IDL_DIR.."/access_control_service.idl"
oil.loadidlfile (idlfile)
idlfile = CORBA_IDL_DIR.."/registry_service.idl"
oil.loadidlfile (idlfile)

-- Inicializa o ORB, fixando a localização do serviço em porta específica
oil.init{host = AccessControlServerConfiguration.hostName, 
         port = AccessControlServerConfiguration.hostPort}

function main()
  -- Aloca uma thread para o orb
  local success, res  = oil.pcall(oil.newthread,oil.run)
  if not success then
    io.stderr:write("Falha na execução da thread do orb: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente responsável pelo Serviço de Controle de Acesso
  success, res  = 
    oil.pcall(oil.newobject,
    AccessControlServiceComponent("AccessControlService"), 
    "IDL:openbusidl/acs/IAccessControlServiceComponent:1.0", "ACS")
  if not success then
    io.stderr:write("Falha criando do AcessControlServiceComponent: "..
                     tostring(res).."\n")
    os.exit(1)
  end

  local accessControlServiceComponent = res
  success, res = oil.pcall(accessControlServiceComponent.startup, 
                           accessControlServiceComponent)
  if not success then
    io.stderr:write("Falha ao iniciar o serviço de controle de acesso: "..
                    tostring(res).."\n")
    os.exit(1)
  end
  log:init("Serviço de controle de acesso iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
