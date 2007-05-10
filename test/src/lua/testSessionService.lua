--
-- Testes unit�rios do Servi�o de Sess�o
--
-- $Id$
--
require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialHolder = require "openbus.common.CredentialHolder"

require "openbus.Member"

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

      self.accessControlService = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

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
      local member1 = Member{name = "membro1"}
      member1 = oil.newobject(member1, "IDL:openbusidl/IMember:1.0")
      local success, session, id1 = self.sessionService:createSession(member1)
      Check.assertTrue(success)
      local member2 = Member{name = "membro2"}
      member2 = oil.newobject(member2, "IDL:openbusidl/IMember:1.0")
      local session2 = self.sessionService:getSession()
      Check.assertEquals(session:getIdentifier(), session2:getIdentifier())
      local id2 = session:addMember(member2)
      Check.assertNotEquals(id1, id2)
      session:removeMember(id1)
      session:removeMember(id2)
print("FIM TESTE")
    end,

    afterTestCase = function(self)
print("FIM TUDO")
      self.accessControlService:logout(self.credential)
      self.credentialHolder:invalidate()
    end,
  }
}
