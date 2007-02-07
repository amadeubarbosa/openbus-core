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

local serverConfiguration = {}
function AccessControlServerConfiguration (accessControlServerConfiguration)
    serverConfiguration.hostName = accessControlServerConfiguration.hostName
    serverConfiguration.hostPort = accessControlServerConfiguration.hostPort
    serverConfiguration.ldapHost = accessControlServerConfiguration.ldapHostName..":"..accessControlServerConfiguration.ldapHostPort
    serverConfiguration.oilVerboseLevel = accessControlServerConfiguration.oilVerboseLevel

    serverConfiguration.oilVerboseLevel = serverConfiguration.oilVerboseLevel or 1
end

local config = loadfile(CONF_DIR.."/AccessControlServerConfiguration.lua")
config()

oil.verbose.level(serverConfiguration.oilVerboseLevel)

local idlfile = CORBA_IDL_DIR.."/access_control_service_oil.idl"

oil.loadidlfile (idlfile)

oil.init{host = serverConfiguration.hostName, port = serverConfiguration.hostPort,}

local accessControlServiceComponent = AccessControlServiceComponent{
    name = "AccessControlService",
    ldapHost = serverConfiguration.ldapHost,
}

accessControlServiceComponent = oil.newobject (accessControlServiceComponent, "IDL:OpenBus/ACS/AccessControlServiceComponent:1.0", "ACS")

accessControlServiceComponent:startup()

oil.run()
