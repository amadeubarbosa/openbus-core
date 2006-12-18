require "oil"

require "SessionServiceComponent"

oil.verbose.level(3)

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
    io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
    os.exit(1)
end

local idlfile = CORBA_IDL_DIR.."/session_service.idl"

oil.loadidlfile (idlfile)

local sessionService = SessionServiceComponent:new()

sessionService = oil.newobject (sessionService, "IDL:SCS/SS/SessionServiceComponent:1.0")

sessionService:startup()

oil.run()
