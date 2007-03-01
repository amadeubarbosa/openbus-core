require "scheduler"
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

local serverConfiguration = {}
function SessionServerConfiguration (sessionServerConfiguration)
  serverConfiguration.accessControlServerHost = sessionServerConfiguration.accessControlServerHostName..":"..sessionServerConfiguration.accessControlServerHostPort
  serverConfiguration.accessControlServerKey = sessionServerConfiguration.accessControlServerKey
  serverConfiguration.oilVerboseLevel = sessionServerConfiguration.oilVerboseLevel

  serverConfiguration.oilVerboseLevel = serverConfiguration.oilVerboseLevel or 1
end

local config = loadfile(CONF_DIR.."/SessionServerConfiguration.lua")
config()

oil.verbose.level(serverConfiguration.oilVerboseLevel)

local idlfile = CORBA_IDL_DIR.."/session_service_oil.idl"

oil.loadidlfile (idlfile)

function main()
  local sessionServiceComponent = SessionServiceComponent{
    name = "SessionService",
    accessControlServerHost = serverConfiguration.accessControlServerHost,
    accessControlServerKey = serverConfiguration.accessControlServerKey,
  }
  sessionServiceComponent = oil.newobject (sessionServiceComponent, "IDL:OpenBus/SS/ISessionServiceComponent:1.0")

  local success, startupFailed = scheduler.pcall(sessionServiceComponent.startup, sessionServiceComponent)
  if not success then
    print("Erro ao iniciar o serviço de sessão.")
    os.exit(1)
  end
end

scheduler.new(oil.run)
scheduler.new(main)
scheduler.run()
