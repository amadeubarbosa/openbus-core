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
local idlfile = CORBA_IDL_DIR.."/session_service_oil.idl"

oil.loadidlfile(idlfile)

local host = arg[1]
local user = arg[2]
local password = arg[3]

local accessControlServiceComponent = oil.newproxy("corbaloc::"..host.."/ACS", "IDL:OpenBus/AS/AccessControlServiceComponent:1.0")
local accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/AS/AccessControlService:1.0")
accessControlService = oil.narrow(accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")

local credentialLoginIdentifier = accessControlService:loginByPassword(user, password)
local registryService = accessControlService:getRegistryService(credentialLoginIdentifier.credential)
assertNotNil(registryService)
local sessionServiceComponent = registryService:find({}, "OpenBus/SS/SessionService")
assertNotNil(sessionServiceComponent)

local sessionService = sessionServiceComponent:getFacet("IDL:OpenBus/SS/SessionService:1.0")
assertNotNil(sessionService)

sessionService = oil.narrow(sessionService, "IDL:OpenBus/SS/SessionService:1.0")
assertNotNil(sessionService)

local session = sessionService:createSession(credentialLoginIdentifier.credential)
assertNotEquals("", session.identifier)

local session2 = sessionService:getSession(credentialLoginIdentifier.credential)
assertNotEquals("", session2.identifier)

assertEquals(session.identifier, session2.identifier)

assertTrue(sessionService:removeSession(credentialLoginIdentifier.credential))
local session3 = sessionService:getSession(credentialLoginIdentifier.credential)
assertEquals("", session3.identifier)
assertFalse(sessionService:removeSession(credentialLoginIdentifier.credential))

assertTrue(accessControlService:logout(credentialLoginIdentifier.loginIdentifier))
