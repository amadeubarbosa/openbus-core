--
-- Suite de Teste da operacao 'unregister' do Serviço de Registro
--
--
local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

local scs = require "scs.core.base"

local Check = require "latt.Check"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
local Before = dofile(OPENBUS_HOME .."/core/test/lua/registry/beforeTestCase.lua")
local beforeTestCase = Before.beforeTestCase
local afterTestCase = dofile(OPENBUS_HOME .."/core/test/lua/registry/afterTestCase.lua")

-------------------------------------------------------------------------------

Suite = {
  Test1 = {
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    testUnregister = function(self)
      local member = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
        self.Hello_v2.componentId)
      -- Identificar local propositalmente
      local success
      sucess, self.registryIdentifier = self.rgsProtected:register({
        member = member.IComponent,
        properties = self.Hello_v2.properties,
      })
      Check.assertTrue(success)
      Check.assertNotNil(self.registryIdentifier)

      Check.assertTrue(self.registryService:unregister(self.registryIdentifier))
      local offers = self.registryService:find({self.Hello_v2.facets.IHello_v1.name})
      Check.assertEquals(0, #offers)
      offers = self.registryService:find({self.Hello_v2.facets.IHello_v2.name})
      Check.assertEquals(0, #offers)

      self.registryIdentifier = nil
      --
    end,

    testUnregister_InvalidService = function(self)
      Check.assertFalse(self.registryService:unregister("INVALID-IDENTIFIER"))
    end,
  },
}

return Suite
