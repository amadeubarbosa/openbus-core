require "luaunit"

require "oil"

if #arg ~= 3 then
    print("Parametros invalidos !!!")
    print("Use testRegistryServer.lua <access_control_server_host> <user> <password>")
    os.exit(0)
end

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
    io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
    os.exit(1)
end
local idlfile = CORBA_IDL_DIR.."/registry_service.idl"

oil.loadidlfile(idlfile)

local host = arg[1]
local user = arg[2]
local password = arg[3]

local accessControlServiceComponent = oil.newproxy("corbaloc::"..host.."/ACS", "IDL:OpenBus/AS/AccessControlServiceComponent:1.0")
local accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/AS/AccessControlService:1.0")
accessControlService = oil.narrow(accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")

TestRegistryService = {}

LuaUnit:run("TestRegistryService")
