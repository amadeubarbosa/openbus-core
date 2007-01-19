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

oil.verbose.level(3)
oil.loadidlfile(idlfile)

local host = arg[1]
local user = arg[2]
local password = arg[3]

local accessControlServiceComponent = oil.newproxy("corbaloc::"..host.."/ACS", "IDL:OpenBus/AS/AccessControlServiceComponent:1.0")
local accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/AS/AccessControlService:1.0")
accessControlService = oil.narrow(accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")

TestAccessControlService1 = {}

function TestAccessControlService1:testLoginByPassword()
    local credentialLoginIdentifier = accessControlService:loginByPassword(user, password)
    local credentialLoginIdentifier2 = accessControlService:loginByPassword(user, password)
    assertNotEquals(credentialLoginIdentifier.credential.identifier, credentialLoginIdentifier2.credential.identifier)
    assertNotEquals(credentialLoginIdentifier.loginIdentifier, credentialLoginIdentifier2.loginIdentifier)
    accessControlService:logout(credentialLoginIdentifier.loginIdentifier)
    accessControlService:logout(credentialLoginIdentifier2.loginIdentifier)
end

function TestAccessControlService1:testLogout()
    local credentialLoginIdentifier = accessControlService:loginByPassword(user, password)
    assertFalse(accessControlService:logout("abcd"))
    assertTrue(accessControlService:logout(credentialLoginIdentifier.loginIdentifier))
    assertFalse(accessControlService:logout(credentialLoginIdentifier.loginIdentifier))
end

TestAccessControlService2 = {}

function TestAccessControlService2:setUp()
    self.credentialLoginIdentifier = accessControlService:loginByPassword(user, password)
end

function TestAccessControlService2:tearDown()
    accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)
end

function TestAccessControlService2:testIsValid()
    assertTrue(accessControlService:isValid(self.credentialLoginIdentifier.credential))
    assertFalse(accessControlService:isValid({memberName=user, identifier = "123"}))
    accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)
    assertFalse(accessControlService:isValid(self.credentialLoginIdentifier.credential))
end

function TestAccessControlService2:testGetRegistryService()
    assertNil(accessControlService:getRegistryService(self.credentialLoginIdentifier.credential))
end

function TestAccessControlService2:testObservers()
    local credentialObserver = { credential = self.credentialLoginIdentifier.credential}
    function credentialObserver:credentialWasDeleted(credential)
        assertEquals(self.credential, credential)
    end
    credentialObserver = oil.newobject(credentialObserver, "IDL:OpenBus/AS/CredentialObserver:1.0")
    local observerIdentifier = accessControlService:addObserver(credentialObserver, {self.credentialLoginIdentifier.credential.identifier,})
    assertNotEquals("", observerIdentifier)
    accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)
    assertTrue(accessControlService:removeObserver(observerIdentifier))
    assertFalse(accessControlService:removeObserver(observerIdentifier))
end

LuaUnit:run("TestAccessControlService1", "TestAccessControlService2")
