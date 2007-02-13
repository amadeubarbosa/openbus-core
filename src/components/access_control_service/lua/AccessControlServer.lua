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

ServerConfiguration = {}
function AccessControlServerConfiguration (accessControlServerConfiguration)
    ServerConfiguration.hostName = accessControlServerConfiguration.hostName
    ServerConfiguration.hostPort = accessControlServerConfiguration.hostPort
    ServerConfiguration.ldapHost = accessControlServerConfiguration.ldapHostName..":"..accessControlServerConfiguration.ldapHostPort
    ServerConfiguration.databaseDirectory = accessControlServerConfiguration.databaseDirectory
    ServerConfiguration.oilVerboseLevel = accessControlServerConfiguration.oilVerboseLevel

    ServerConfiguration.oilVerboseLevel = ServerConfiguration.oilVerboseLevel or 1
end

local config = loadfile(CONF_DIR.."/AccessControlServerConfiguration.lua")
config()

oil.verbose.level(ServerConfiguration.oilVerboseLevel)

local idlfile = CORBA_IDL_DIR.."/access_control_service_oil.idl"

oil.loadidlfile (idlfile)

oil.init{host = ServerConfiguration.hostName, port = ServerConfiguration.hostPort,}

local accessControlServiceComponent = AccessControlServiceComponent{
    name = "AccessControlService",
}

accessControlServiceComponent = oil.newobject (accessControlServiceComponent, "IDL:OpenBus/ACS/IAccessControlServiceComponent:1.0", "ACS")

accessControlServiceComponent:startup()

oil.run()
