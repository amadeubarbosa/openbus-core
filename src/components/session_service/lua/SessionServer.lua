require "oil"

require "SessionServiceComponent"

oil.verbose.level(3)

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
end

local config = loadfile(CONF_DIR.."/SessionServerConfiguration.lua")
config()

local idlfile = CORBA_IDL_DIR.."/session_service.idl"

oil.loadidlfile (idlfile)

local sessionService = SessionServiceComponent:new{
    accessControlServerHost = serverConfiguration.accessControlServerHost,
    accessControlServerKey = serverConfiguration.accessControlServerKey,
}

sessionService = oil.newobject (sessionService, "IDL:OpenBus/SS/SessionServiceComponent:1.0")

sessionService:startup()

oil.run()
