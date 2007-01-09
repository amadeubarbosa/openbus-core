require "luaunit"

require "oil"

if #arg ~= 3 then
    print("Parametros invalidos !!!")
    print("Use testAccessControlServer.lua <access_control_server_host> <user> <password>")
    os.exit(0)
end

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
    io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
    os.exit(1)
end
local idlfile = CORBA_IDL_DIR.."/access_control_service_oil.idl"

oil.loadidlfile(idlfile)

local host = arg[1]
local user = arg[2]
local password = arg[3]

local accessControlServiceComponent = oil.newproxy("corbaloc::"..host.."/ACS", "IDL:OpenBus/AS/AccessControlServiceComponent:1.0")

local accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/AS/AccessControlService:1.0")
accessControlService = oil.narrow(accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")
assertNotNil(accessControlService)

accessControlService = accessControlServiceComponent:getFacetByName("accessControlService")
accessControlService = oil.narrow(accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")

local credentialLoginIdentifier = accessControlService:loginByPassword(user, password)

assertTrue(accessControlService:isValid(credentialLoginIdentifier.credential))
assertFalse(accessControlService:isValid({entityName=user, identifier = "123"}))
assertFalse(accessControlService:logout("abcd"))

local registryService = accessControlService:getRegistryService(credentialLoginIdentifier.credential)
assertNil(registryService)

assertTrue(accessControlService:logout(credentialLoginIdentifier.loginIdentifier))

assertFalse(accessControlService:isValid(credentialLoginIdentifier.credential))
assertFalse(accessControlService:logout(credentialLoginIdentifier.loginIdentifier))

registryService = accessControlService:getRegistryService(credentialLoginIdentifier.credential)
assertNil(registryService)

credentialLoginIdentifier = accessControlService:loginByPassword(user, password)
assertTrue(accessControlService:isValid(credentialLoginIdentifier.credential))


local credentialLoginIdentifier2 = accessControlService:loginByPassword(user, password)

assertTrue(accessControlService:logout(credentialLoginIdentifier.loginIdentifier))
assertTrue(accessControlService:isValid(credentialLoginIdentifier.credential))
assertTrue(accessControlService:logout(credentialLoginIdentifier2.loginIdentifier))
assertFalse(accessControlService:isValid(credentialLoginIdentifier.credential))
