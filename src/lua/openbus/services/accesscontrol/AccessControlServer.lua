-----------------------------------------------------------------------------
-- Inicializa��o do Servi�o de Controle de Acesso
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
require "oil"

require "openbus.services.accesscontrol.AccessControlService"

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
assert(loadfile(CONF_DIR.."/AccessControlServerConfiguration.lua"))()

-- Seta os n�veis de verbose para o openbus e para o oil
if AccessControlServerConfiguration.logLevel then
  log:level(AccessControlServerConfiguration.logLevel)
end
if AccessControlServerConfiguration.oilVerboseLevel then
  oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
end

-- Carrega a interface do servi�o
local idlfile = CORBA_IDL_DIR.."/access_control_service.idl"
oil.loadidlfile (idlfile)
idlfile = CORBA_IDL_DIR.."/registry_service.idl"
oil.loadidlfile (idlfile)

-- Inicializa o ORB, fixando a localiza��o do servi�o em porta espec�fica
oil.init{host = AccessControlServerConfiguration.hostName, 
         port = AccessControlServerConfiguration.hostPort}

function main()
  -- Aloca uma thread para o orb
  local success, res  = oil.pcall(oil.newthread,oil.run)
  if not success then
    log:error("Falha na execu��o da thread do orb: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente respons�vel pelo Servi�o de Controle de Acesso
  success, res  = 
    oil.pcall(oil.newservant,
    AccessControlService("AccessControlService"), 
    "IDL:openbusidl/acs/IAccessControlService:1.0", "ACS")
  if not success then
    log:error("Falha criando o AcessControlService: "..tostring(res).."\n")
    os.exit(1)
  end

  local accessControlService = res
  success, res = oil.pcall(accessControlService.startup, accessControlService)
  if not success then
    log:error("Falha ao iniciar o servi�o de controle de acesso: "..
               tostring(res).."\n")
    os.exit(1)
  end
  log:init("Servi�o de controle de acesso iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
