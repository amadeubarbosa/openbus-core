require "luaunit"

require "scheduler"
require "oil"

require "Member"

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

TestRegistryService = {}

function TestRegistryService:setUp()
  self.credentialLoginIdentifier = accessControlService:loginByPassword(user, password)
  self.registryService = accessControlService:getRegistryService(self.credentialLoginIdentifier.credential)
end

function TestRegistryService:tearDown()
  accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)
  self.credentialLoginIdentifier = nil
end

function TestRegistryService:testRegister1()
  local member = Member:new{name = "Membro Mock"}
  member = oil.newobject(member, "IDL:OpenBus/Member:1.0")
  assertEquals("", self.registryService:register({identifier = "", memberName = "", }, {description = "", type = "", member = member, }))
end

function TestRegistryService:testRegister2()
  local member = Member:new{name = "Membro Mock"}
  member = oil.newobject(member, "IDL:OpenBus/Member:1.0")
  local registryIdentifier = self.registryService:register(self.credentialLoginIdentifier.credential, {description = "", type = "", member = member, })
  assertNotEquals("", registryIdentifier)
  self.registryService:unregister(registryIdentifier)
end

function TestRegistryService:testUnregister()
  local member = Member:new{name = "Membro Mock"}
  member = oil.newobject(member, "IDL:OpenBus/Member:1.0")
  local registryIdentifier = self.registryService:register(self.credentialLoginIdentifier.credential, {description = "", type = "", member = member, })
  assertNotEquals("", registryIdentifier)
  assertTrue(self.registryService:unregister(registryIdentifier))
  assertFalse(self.registryService:unregister(registryIdentifier))
end

function TestRegistryService:testFind()
  local member = Member:new{name = "Membro Mock"}
  member = oil.newobject(member, "IDL:OpenBus/Member:1.0")
  local registryIdentifier = self.registryService:register(self.credentialLoginIdentifier.credential, {description = "", type = "X", member = member, })
  assertNotEquals("", registryIdentifier)
  local members = self.registryService:find({ { name = "type", value= "X", }, })
  assertNotEquals(0, #members)
  members = self.registryService:find({ { name = "type", value= "Y", }, })
  assertEquals(0, #members)
  self.registryService:unregister(registryIdentifier)
end

function TestRegistryService:testRefresh()
  local member = Member:new{name = "Membro Mock"}
  member = oil.newobject(member, "IDL:OpenBus/Member:1.0")
  local serviceOffer = {description = "", type = "X", member = member, }
  assertFalse(self.registryService:refresh("", serviceOffer))
  local registryIdentifier = self.registryService:register(self.credentialLoginIdentifier.credential, serviceOffer)
  serviceOffer.type = "Y"
  assertTrue(self.registryService:refresh(registryIdentifier, serviceOffer))
  local members = self.registryService:find({ { name = "type", value= "Y", }, })
  assertEquals(members[1]:getName(), member:getName())
  self.registryService:unregister(registryIdentifier)
end

function main()
  local accessControlServiceComponent = oil.newproxy("corbaloc::"..host.."/ACS", "IDL:OpenBus/AS/AccessControlServiceComponent:1.0")
  accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/AS/AccessControlService:1.0")
  accessControlService = oil.narrow(accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")

  LuaUnit:run("TestRegistryService")
  os.exit()
end

pcall = function(func, ...)
          return scheduler.pcall(func, arg)
        end

xpcall = function (func, errorHandler)
           local f = function(result, ...)
             if result then 
               return true, unpack(arg)
             else
               return false, errorHandler(arg[1])
             end
           end
           return f(pcall(func))
         end


scheduler.new(oil.run)
scheduler.new(main)
scheduler.run()
