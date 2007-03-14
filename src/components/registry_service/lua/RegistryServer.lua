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

oil.verbose:level(serverConfiguration.oilVerboseLevel)

local idlfile = CORBA_IDL_DIR.."/registry_service.idl"
oil.loadidlfile (idlfile)

function main()
  oil.newthread(oil.run)

  local registryServiceComponent = RegistryServiceComponent{
    name = "RegistryService",
    accessControlServerHost = serverConfiguration.accessControlServerHost,
    accessControlServerKey = serverConfiguration.accessControlServerKey,
  }
  registryServiceComponent = oil.newobject (registryServiceComponent, "IDL:OpenBus/RS/IRegistryServiceComponent:1.0")

  local success, startupFailed = oil.pcall (registryServiceComponent.startup, registryServiceComponent)
  if not success then
    print("Erro ao iniciar o serviço de registro.")
    os.exit(1)
  end
end

oil.main(main)
