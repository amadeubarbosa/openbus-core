--
-- Testes unit�rios do Servi�o de Sess�o
--
-- $Id$
--
local oil = require "oil"
local orb = oil.orb

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

local scs = require "scs.core.base"

local Check = require "latt.Check"


Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
      if IDLPATH_DIR == nil then
        io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
        os.exit(1)
      end

      oil.verbose:level(0)

      local idlfile = IDLPATH_DIR.."/session_service.idl"
      orb:loadidlfile(idlfile)
      idlfile = IDLPATH_DIR.."/registry_service.idl"
      orb:loadidlfile(idlfile)
      idlfile = IDLPATH_DIR.."/access_control_service.idl"
      orb:loadidlfile(idlfile)

      local user = "tester"
      local password = "tester"

      self.accessControlService = orb:newproxy("corbaloc::localhost:2089/ACS", "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))

      _, self.credential = self.accessControlService:loginByPassword(user, password)
      self.credentialManager:setValue(self.credential)

      local acsIComp = self.accessControlService:_component()
      acsIComp = orb:narrow(acsIComp, "IDL:scs/core/IComponent:1.0")
      local acsIRecept = acsIComp:getFacetByName("IReceptacles")
      acsIRecept = orb:narrow(acsIRecept, "IDL:scs/core/IReceptacles:1.0")
      local conns = acsIRecept:getConnections("RegistryServiceReceptacle")
      local rsIComp = orb:narrow(conns[1].objref, "IDL:scs/core/IComponent:1.0")
      local registryService = rsIComp:getFacetByName("IRegistryService")
      registryService = orb:narrow(registryService,
        "IDL:tecgraf/openbus/core/v1_05/registry_service/IRegistryService:1.0")

      local serviceOffers = registryService:find({"ISessionService"})
      Check.assertNotEquals(#serviceOffers, 0)
      local sessionServiceComponent = orb:narrow(serviceOffers[1].member, "IDL:scs/core/IComponent:1.0")
      local sessionServiceInterface = "IDL:tecgraf/openbus/session_service/v1_05/ISessionService:1.0"
      self.sessionService = sessionServiceComponent:getFacet(sessionServiceInterface)
      self.sessionService = orb:narrow(self.sessionService, sessionServiceInterface)
    end,

    testCreateSession = function(self)
      local facetDescriptions = {}
      facetDescriptions.IComponent = {
          name = "IComponent", interface_name = "IDL:scs/core/IComponent:1.0",
          class = scs.Component
      }
      local componentId = {
          major_version = 1, minor_version = 0, patch_version = 0,
          platform_spec = ""
      }
      componentId.name = "membro1"
      local member1 = scs.newComponent(facetDescriptions, {}, componentId)
      local success, session, id1 =
          self.sessionService:createSession(member1.IComponent)
      Check.assertTrue(success)
      session = session:getFacet("IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session = orb:narrow(session, "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      componentId.name = "membro2"
      local member2 = scs.newComponent(facetDescriptions, {}, componentId)
      local session2 = self.sessionService:getSession()
      session2 = session2:getFacet("IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session2 = orb:narrow(session2, "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      Check.assertEquals(session:getIdentifier(), session2:getIdentifier())
      local id2 = session:addMember(member2.IComponent)
      Check.assertNotEquals(id1, id2)
      session:removeMember(id1)
      session:removeMember(id2)
    end,

    afterTestCase = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,
  }
}
