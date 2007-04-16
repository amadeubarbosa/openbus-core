--
-- Testes unitários do Serviço de Sessão
--
-- $Id$
--
require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialHolder = require "openbus.common.CredentialHolder"

local Check = require "latt.Check"

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
      if CORBA_IDL_DIR == nil then
        io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end
      
      oil.verbose:level(0)

      local idlfile = CORBA_IDL_DIR.."/session_service.idl"
      oil.loadidlfile(idlfile)
      idlfile = CORBA_IDL_DIR.."/registry_service.idl"
      oil.loadidlfile(idlfile)
      idlfile = CORBA_IDL_DIR.."/access_control_service.idl"
      oil.loadidlfile(idlfile)

      local user = "csbase"
      local password = "csbLDAPtest"

      local accessControlServiceComponent = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlServiceComponent:1.0")
      local accessControlServiceInterface = "IDL:openbusidl/acs/IAccessControlService:1.0"
      self.accessControlService = accessControlServiceComponent:getFacet(accessControlServiceInterface)
      self.accessControlService = oil.narrow(self.accessControlService, accessControlServiceInterface)

      -- instala o interceptador de cliente
      local CONF_DIR = os.getenv("CONF_DIR")
      local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
      self.credentialHolder = CredentialHolder()
      oil.setclientinterceptor(ClientInterceptor(config, self.credentialHolder))

      _, self.credential = self.accessControlService:loginByPassword(user, password)
      self.credentialHolder:setValue(self.credential)

      local registryService = self.accessControlService:getRegistryService()
      local registryServiceInterface = "IDL:openbusidl/rs/IRegistryService:1.0"
      registryService = registryService:getFacet(registryServiceInterface)
      registryService = oil.narrow(registryService, registryServiceInterface)

      local serviceOffers = registryService:find("openbusidl/ss/ISessionService", {})
      Check.assertNotEquals(#serviceOffers, 0)
      local sessionServiceComponent = oil.narrow(serviceOffers[1].member, "IDL:openbusidl/ss/ISessionServiceComponent:1.0")
      local sessionServiceInterface = "IDL:openbusidl/ss/ISessionService:1.0"
      self.sessionService = sessionServiceComponent:getFacet(sessionServiceInterface)
      self.sessionService = oil.narrow(self.sessionService, sessionServiceInterface)
    end,

    testCreateSession = function(self)
      local success, session = self.sessionService:createSession()
      Check.assertTrue(success)
      local session2 = self.sessionService:getSession()
      Check.assertEquals(session:getIdentifier(), session2:getIdentifier())
    end,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialHolder:invalidate()
    end,
  }
}
