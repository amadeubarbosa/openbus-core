require "oil"

require "RegistryServiceComponent"

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
    serverConfiguration.oilVerboseLevel = registryServerConfiguration.oilVerboseLevel

    serverConfiguration.oilVerboseLevel = serverConfiguration.oilVerboseLevel or 1
end

local config = loadfile(CONF_DIR.."/RegistryServerConfiguration.lua")
config()

oil.verbose.level(serverConfiguration.oilVerboseLevel)

local idlfile = CORBA_IDL_DIR.."/registry_service.idl"
oil.loadidlfile (idlfile)

local registryServiceComponent = RegistryServiceComponent:new{
  name = "RegistryService",
  accessControlServerHost = serverConfiguration.accessControlServerHost,
  accessControlServerKey = serverConfiguration.accessControlServerKey,
}
registryServiceComponent = oil.newobject (registryServiceComponent, "IDL:OpenBus/RS/RegistryServiceComponent:1.0")

local success, startupFailed = pcall (registryServiceComponent.startup, registryServiceComponent)
if not success then
  print("O servico de controle de acesso nao foi encontrado em "..serverConfiguration.accessControlServerHost..".")
  os.exit(1)
end

oil.run()
