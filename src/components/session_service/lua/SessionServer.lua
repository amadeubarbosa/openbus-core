--
-- Inicialização do Serviço de Sessão
--
-- $Id$
--
require "oil"
require "SessionServiceComponent"
local verbose = require "Verbose"

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
local config = assert(loadfile(CONF_DIR.."/SessionServerConfiguration.lua"))()
SessionServerConfiguration.accessControlServerHost = 
  SessionServerConfiguration.accessControlServerHostName..":"..
  SessionServerConfiguration.accessControlServerHostPort

-- Seta os níveis de verbose para o openbus e para o oil
if SessionServerConfiguration.verboseLevel then
  verbose:level(SessionServerConfiguration.verboseLevel)
end
if SessionServerConfiguration.oilVerboseLevel then
  oil.verbose:level(SessionServerConfiguration.oilVerboseLevel)
end

-- Carrega a interface do serviço
local idlfile = CORBA_IDL_DIR.."/session_service.idl"
oil.loadidlfile (idlfile)
idlfile = CORBA_IDL_DIR.."/access_control_service.idl"
oil.loadidlfile (idlfile)
idlfile = CORBA_IDL_DIR.."/registry_service.idl"
oil.loadidlfile (idlfile)

function main()
  -- Aloca uma thread para o orb
  local success, res = oil.pcall(oil.newthread, oil.run)
  if not success then
    io.stderr:write("Falha na execução da thread do orb: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente responsável pelo Serviço de Sessão
  success, res = oil.pcall(oil.newobject, SessionServiceComponent("SessionService"), 
                           "IDL:OpenBus/SS/ISessionServiceComponent:1.0")

  if not success then
    io.stderr:write("Falha criando SessionServiceComponent: "..
                    tostring(res).."\n") 
    os.exit(1)
  end
  local sessionServiceComponent = res

  success, res = oil.pcall(sessionServiceComponent.startup, 
                           sessionServiceComponent)
  if not success then
    io.stderr:write("Falha ao iniciar o serviço de sessão: "..
                    tostring(res).."\n")
    os.exit(1)
  end
  verbose:init("Serviço de sessão iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
