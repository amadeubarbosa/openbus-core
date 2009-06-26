--
-- Testes unitários do Serviço de Sessão
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

      self.accessControlService = orb:newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))

      _, self.credential = self.accessControlService:loginByPassword(user, password)
      self.credentialManager:setValue(self.credential)

      local registryService = self.accessControlService:getRegistryService()

      local serviceOffers = registryService:find({"ISessionService"})
      Check.assertNotEquals(#serviceOffers, 0)
      local sessionServiceComponent = orb:narrow(serviceOffers[1].member, "IDL:scs/core/IComponent:1.0")
      local sessionServiceInterface = "IDL:openbusidl/ss/ISessionService:1.0"
      self.sessionService = sessionServiceComponent:getFacet(sessionServiceInterface)
      self.sessionService = orb:narrow(self.sessionService, sessionServiceInterface)
    end,

    testCreateSession = function(self)
      local facetDescriptions = {}
      facetDescriptions.IComponent = {name = "IComponent", interface_name = "IDL:scs/core/IComponent:1.0",
                                       class = scs.Component}
      local componentId = {major_version = 1, minor_version = 0, patch_version = 0, platform_spec = ""}
      componentId.name = "membro1"
      local member1 = scs.newComponent(facetDescriptions, {}, componentId)
      local success, session, id1 = self.sessionService:createSession(member1.IComponent)
      Check.assertTrue(success)
      componentId.name = "membro2"
      local member2 = scs.newComponent(facetDescriptions, {}, componentId)
      local session2 = self.sessionService:getSession()
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
