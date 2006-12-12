require "oil"
require "AccessControlService"

oil.verbose.level(3)

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
    io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
    os.exit(1)
end

local idlfile = CORBA_IDL_DIR.."/access_control_service.idl"
print("IXI")
oil.loadidlfile(CORBA_IDL_DIR.."/scs.idl")
print("IXII")
oil.loadidlfile(CORBA_IDL_DIR.."/life_cycle.idl")
print("IXIII")
--oil.loadidlfile(CORBA_IDL_DIR.."/registry_service.idl")

print("IX")
oil.loadidlfile (idlfile)

print("IIX")
local accessControlService = AccessControlService:new()
print("IIIX")

print("X")
accessControlService = oil.newobject (accessControlService, "IDL:SCS/AS/AccessControlService:1.0")
print("XX")

accessControlService:startup()
print("XXX")

print(accessControlService:_ior())

oil.run()
