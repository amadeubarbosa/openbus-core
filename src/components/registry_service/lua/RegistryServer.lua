require "oil"

require "RegistryServiceComponent"

oil.verbose.level(3)

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
    io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
    os.exit(1)
end

local idlfile = CORBA_IDL_DIR.."/registry_service.idl"

oil.loadidlfile (idlfile)

local registryService = RegistryServiceComponent:new()

registryService = oil.newobject (registryService, "IDL:OpenBus/RS/RegistryServiceComponent:1.0")

registryService:startup()

oil.run()
