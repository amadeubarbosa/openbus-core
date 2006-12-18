require "oil"

require "AccessControlService"

oil.verbose.level(3)

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
    io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
    os.exit(1)
end

local idlfile = CORBA_IDL_DIR.."/access_control_service.idl"

oil.loadidlfile (idlfile)

local accessControlService = AccessControlService:new()

accessControlService = oil.newobject (accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")

accessControlService:startup()

print(accessControlService:_ior())

oil.run()
