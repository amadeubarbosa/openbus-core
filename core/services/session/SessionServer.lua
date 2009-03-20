-----------------------------------------------------------------------------
-- Inicialização do Serviço de Sessão
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local oil = require "oil"

local Log = require "openbus.common.Log"

-- Inicialização do nível de verbose do openbus.
Log:level(1)

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

-- Inicializa o ORB, fixando a localização do serviço em uma porta específica
local orb = oil.init { flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

local SessionServiceComponent =
    require "core.services.session.SessionServiceComponent"

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/SessionServerConfiguration.lua"))()

SessionServerConfiguration.accessControlServerHost =
    SessionServerConfiguration.accessControlServerHostName..":"..
    SessionServerConfiguration.accessControlServerHostPort

-- Seta os níveis de verbose para o openbus e para o oil
if SessionServerConfiguration.logLevel then
  Log:level(SessionServerConfiguration.logLevel)
end
if SessionServerConfiguration.oilVerboseLevel then
  oil.verbose:level(SessionServerConfiguration.oilVerboseLevel)
end

-- Carrega a interface do serviço
local idlfile = IDLPATH_DIR.."/session_service.idl"
orb:loadidlfile (idlfile)
idlfile = IDLPATH_DIR.."/access_control_service.idl"
orb:loadidlfile (idlfile)
idlfile = IDLPATH_DIR.."/registry_service.idl"
orb:loadidlfile (idlfile)

function main()
  -- Aloca uma thread para o orb
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execução do ORB: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente responsável pelo Serviço de Sessão
  success, res = oil.pcall(orb.newservant, orb,
      SessionServiceComponent("SessionService", SessionServerConfiguration),
      nil,
      "IDL:scs/core/IComponent:1.0")
  if not success then
    Log:error("Falha criando SessionServiceComponent: "..tostring(res).."\n")
    os.exit(1)
  end
  local sessionServiceComponent = res
  success, res = oil.pcall(sessionServiceComponent.startup,
      sessionServiceComponent)
  if not success then
    Log:error("Falha ao iniciar o serviço de sessão: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Serviço de sessão iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
