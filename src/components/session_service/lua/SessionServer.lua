--
-- Inicializa��o do Servi�o de Sess�o
--
-- $Id$
--
require "oil"
require "SessionServiceComponent"

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
local config = assert(loadfile(CONF_DIR.."/SessionServerConfiguration.lua"))()
oil.verbose:level(SessionServerConfiguration.oilVerboseLevel or 1)
SessionServerConfiguration.accessControlServerHost = 
  SessionServerConfiguration.accessControlServerHostName..":"..
  SessionServerConfiguration.accessControlServerHostPort

-- Carrega a interface do servi�o
local idlfile = CORBA_IDL_DIR.."/session_service_oil.idl"
oil.loadidlfile (idlfile)

function main()
  -- Aloca uma thread para o orb
  local success, res = oil.pcall(oil.newthread, oil.run)
  if not success then
    io.stderr:write("Falha na execu��o da thread do orb: ",res)
    os.exit(1)
  end

  -- Cria o componente respons�vel pelo Servi�o de Sess�o
  local sessionServiceComponent = SessionServiceComponent{
    name = "SessionService",
    accessControlServerHost = 
      SessionServerConfiguration.accessControlServerHost,
    accessControlServerKey = 
      SessionServerConfiguration.accessControlServerKey,
  }

  success, res = oil.pcall(oil.newobject, sessionServiceComponent, 
                           "IDL:OpenBus/SS/ISessionServiceComponent:1.0")

  if not success then
    io.stderr:write("Falha na cria��o do SessionServiceComponent: ",res)
    os.exit(1)
  end
  sessionServiceComponent = res

  success, res = oil.pcall(sessionServiceComponent.startup, 
                           sessionServiceComponent)
  if not success then
    io.stderr:write("Erro ao iniciar o servi�o de sess�o: ",res)
    os.exit(1)
  end
end

print(oil.pcall(oil.main,main))
