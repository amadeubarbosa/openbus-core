--
-- Testes unitários do Serviço de Registro
--
-- $Id$
--
package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
local oil = require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"

local IComponent = require "scs.core.IComponent"

local Check = require "latt.Check"

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local CORE_IDL_DIR = os.getenv("CORE_IDL_DIR")
      if CORE_IDL_DIR == nil then
        io.stderr:write("A variavel CORE_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end

      oil.verbose:level(0)

      local idlfile = CORE_IDL_DIR.."/registry_service.idl"
      oil.loadidlfile(idlfile)
      idlfile = CORE_IDL_DIR.."/access_control_service.idl"
      oil.loadidlfile(idlfile)

      local user = "tester"
      local password = "tester"

      self.accessControlService = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local CONF_DIR = os.getenv("CONF_DIR")
      local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      oil.setclientinterceptor(ClientInterceptor(config, self.credentialManager))

      local success
      success, self.credential = self.accessControlService:loginByPassword(user, password)
      self.credentialManager:setValue(self.credential)
      self.registryService = self.accessControlService:getRegistryService()
local a = 1
    end,

    testRegister = function(self)
      local member = IComponent("Membro Mock", 1)
      member = oil.newobject(member, "IDL:scs/core/IComponent:1.0")
      local success, registryIdentifier = self.registryService:register({type = "type1", description = "bla bla bla", properties = {}, member = member, })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testFind = function(self)
      local member = IComponent("Membro Mock", 1)
      member = oil.newobject(member, "IDL:scs/core/IComponent:1.0")
      local success, registryIdentifier = self.registryService:register({type = "X", description = "bla", properties = {}, member = member, })
      Check.assertTrue(success)
      Check.assertNotEquals("", registryIdentifier)
      local offers = self.registryService:find("X", {})
      Check.assertEquals(1, #offers)
      Check.assertEquals("bla", offers[1].description)
      offers = self.registryService:find("Y", {})
      Check.assertEquals(0, #offers)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testUpdate = function(self)
      local member = IComponent("Membro Mock", 1)
      member = oil.newobject(member, "IDL:scs/core/IComponent:1.0")
      local serviceOffer = {type = "X", description = "bla", properties = {}, member = member, }
      Check.assertFalse(self.registryService:update("", {}))
      local success, registryIdentifier = self.registryService:register(serviceOffer)
      Check.assertTrue(success)
      local offers = self.registryService:find("X", {{name = "p1", value = {"b"}}})
      Check.assertEquals(0, #offers)
      local newProps = {{name = "p1", value = {"c", "a", "b"}}}
      Check.assertTrue(self.registryService:update(registryIdentifier, newProps))
      offers = self.registryService:find("X", {{name = "p1", value = {"b"}}})
      Check.assertEquals(1, #offers)
      Check.assertEquals(offers[1].member:getComponentId().name,
        member:getComponentId().name)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testNoUnregister = function(self)
      local member = IComponent("Membro Mock", 1)
      member = oil.newobject(member, "IDL:scs/core/IComponent:1.0")
      local serviceOffer = {type = "FICA", description = "bla", properties = {}, member = member, }
      local success, registryIdentifier = self.registryService:register(serviceOffer)
      Check.assertTrue(success)
    end,

    testFacets = function(self)
      local member = IComponent("Membro Mock", 1)
      member = oil.newobject(member, "IDL:scs/core/IComponent:1.0")
      local dummyObserver = {
        credentialWasDeleted = function(self, credential) end
      }
      member:addFacet("facet1", "IDL:openbusidl/acs/ICredentialObserver:1.0",
                      dummyObserver)
      member:addFacet("facet2", "IDL:openbusidl/acs/ICredentialObserver:1.0",
                      dummyObserver)
      local serviceOffer = {type = "WithFacets", description = "bla", 
                            properties = {{name = "p1", value = {"b"}}}, 
                            member = member, }
      local success, registryIdentifier = self.registryService:register(serviceOffer)
      Check.assertTrue(success)
      local offers = self.registryService:find("WithFacets", 
                                       {{name = "p1", value = {"b"}}})
      Check.assertEquals(1, #offers)
      offers = self.registryService:find("WithFacets", 
                                       {{name = "p1", value = {"b"}},
                                        {name = "facets", value = {"facet2"}}})
      Check.assertEquals(1, #offers)
      offers = self.registryService:find("WithFacets", 
                                       {{name = "facets", value = {"facet3"}}})
      Check.assertEquals(0, #offers)
      local newProps = {{name = "p1", value = {"b"}},
                        {name = "facets", value = {"facet1"}}}
      Check.assertTrue(self.registryService:update(registryIdentifier, newProps))
      offers = self.registryService:find("WithFacets", 
                                       {{name = "p1", value = {"b"}},
                                        {name = "facets", value = {"facet2"}}})
      Check.assertEquals(0, #offers)
      offers = self.registryService:find("WithFacets", 
                                       {{name = "facets", value = {"facet1"}}})
      Check.assertEquals(1, #offers)
      Check.assertTrue(self.registryService:unregister(registryIdentifier))
    end,

    testNoCredential = function(self)
      self.credentialManager:invalidate()
      Check.assertError(self.registryService.find,self.registryService,"Y",{})
      self.credentialManager:setValue(self.credential)
    end,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,
  }
}
