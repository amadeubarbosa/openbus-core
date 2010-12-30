--
---- Suite de Teste da operacao 'logout' de um cliente com ofertas cadastradas no Serviço de Registro
----
----
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

    testFind_AfterLogout = function(self)
      local success, member_v1, member_v2, id_v1, id_v2
      member_v1 = scs.newComponent(self.Hello_v1.facets, self.Hello_v1.receptacles,
        self.Hello_v1.componentId)
      success, id_v1 = self.rgsProtected:register({
        properties = self.Hello_v1.properties,
        member = member_v1.IComponent,
      })
      --
      member_v2 = scs.newComponent(self.Hello_v2.facets, self.Hello_v2.receptacles,
        self.Hello_v2.componentId)
      success, id_v2 = self.rgsProtected:register({
        properties = self.Hello_v2.properties,
        member = member_v2.IComponent,
      })
      --Limpa o Serviço de Registro
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      socket.sleep(3)
      --Loga novamente
      Before.init(self)
      --Não pode encontrar ofertas
      local offers = self.registryService:find({self.Hello_v1.facets.IHello_v1.name})
      Check.assertEquals(0, #offers)
    end,
 },
}

return Suite


