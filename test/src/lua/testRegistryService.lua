require "oil"

--oil.verbose.level(3)

local idlfile = "../../src/corba_idl/as.idl"

oil.loadidlfile(idlfile)

local ior = arg[1]

local accessControlService = oil.newproxy(ior, "OpenBus:SCS/AS/AccessControlService:1.0")
