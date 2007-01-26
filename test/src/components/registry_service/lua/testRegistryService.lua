require "oil"

require "Check"

require "Member"

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
      if CORBA_IDL_DIR == nil then
        io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end
      local idlfile = CORBA_IDL_DIR.."/registry_service.idl"

      oil.verbose.level(1)
      oil.loadidlfile(idlfile)

      local user = "csbase"
      local password = "csbLDAPtest"

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:OpenBus/ACS/AccessControlServiceComponent:1.0")
      self.accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/ACS/AccessControlService:1.0")
      self.accessControlService = oil.narrow(self.accessControlService, "IDL:OpenBus/ACS/AccessControlService:1.0")
      self.credential = self.accessControlService:loginByPassword(user, password)
      self.registryService = self.accessControlService:getRegistryService(self.credential)
    end,

    testRegister1 = function(self)
      local member = Member:new{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:OpenBus/Member:1.0")
      Check.assertEquals("", self.registryService:register({identifier = "", entityName = "", }, {description = "", type = "", member = member, }))
    end,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
    end,
  }
}
--[[
    testRegister2 = function(self)
      local member = Member:new{name = "Membro Mock"}
      member = oil.newobject(member, "IDL:OpenBus/Member:1.0")
      local registryIdentifier = self.registryService:register(self.credential, {description = "", type = "", member = member, })
      Check.assertNotEquals("", registryIdentifier)
      self.registryService:unregister(registryIdentifier)
    end,

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

--]]

--[[
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
--]]
