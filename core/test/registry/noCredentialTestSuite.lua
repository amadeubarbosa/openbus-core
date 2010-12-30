--
-- Suite de Teste da operacao 'find' do Serviço de Registro
--
--
local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local utils = require "core.test.lua.registry.utils"

local scs = require "scs.core.base"

local Check = require "latt.Check"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
local Before = dofile("registry/beforeTestCase.lua")
local beforeTestCase = Before.beforeTestCase
local afterTestCase = dofile("registry/afterTestCase.lua")

-------------------------------------------------------------------------------

Suite = {
  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    beforeEachTest = function(self)
      self.credentialManager:setValue(self.credential)
      self.registryIdentifier = nil
    end,

    afterEachTest = function(self)
      self.credentialManager:setValue(self.credential)
      if self.registryIdentifier then
        self.registryService:unregister(self.registryIdentifier)
      end
    end,

    testRegister_NoCredential = function(self)
      self.credentialManager:invalidate()
      --
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      local success, err = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testFind_NoCredential = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.rgsProtected:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testUpdate_NoCredential = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.rgsProtected:update(self.registryIdentifier,
        self.Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testFindByCriteria_NoCredential = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.rgsProtected:findByCriteria(
  {self.Hello_v1.facets.IHello_v1.name}, self.Hello_v1.properties)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testUnregister_NoCredential = function(self)
      local success
      local member = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, self.registryIdentifier = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member.IComponent,
      })
      --
      self.credentialManager:invalidate()
      --
      local err
      success, err = self.rgsProtected:unregister(
        self.registryIdentifier)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,
  },
}

return Suite
