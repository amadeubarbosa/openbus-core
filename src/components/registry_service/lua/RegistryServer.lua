require "oil"

require "RegistryServiceComponent"

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
function RegistryServerConfiguration (registryServerConfiguration)
    serverConfiguration.accessControlServerHost = registryServerConfiguration.accessControlServerHostName..":"..registryServerConfiguration.accessControlServerHostPort
    serverConfiguration.accessControlServerKey = registryServerConfiguration.accessControlServerKey
end

local config = loadfile(CONF_DIR.."/RegistryServerConfiguration.lua")
config()

local idlfile = CORBA_IDL_DIR.."/registry_service.idl"
oil.loadidlfile (idlfile)

local registryServiceComponent = RegistryServiceComponent:new{
    accessControlServerHost = serverConfiguration.accessControlServerHost,
    accessControlServerKey = serverConfiguration.accessControlServerKey,
}

registryServiceComponent = oil.newobject (registryServiceComponent, "IDL:OpenBus/RS/RegistryServiceComponent:1.0")

registryServiceComponent:startup()

oil.run()
