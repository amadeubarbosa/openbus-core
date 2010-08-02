--
-- Testes unitários do Serviço de Sessão
--
-- $Id: testSessionService.lua 104952 2010-04-30 21:43:16Z augusto $
--
local oil = require "oil"
local orb = oil.orb

local oop = require "loop.base"

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local Utils = require "openbus.util.Utils"

local scs = require "scs.core.base"

local Check = require "latt.Check"

-- Dados para login no barramento
local user     = "tester"
local password = "tester"

local facetDescriptions = {
  IComponent = {
    name = "IComponent",
    interface_name = "IDL:scs/core/IComponent:1.0",
    class = scs.Component
  },
  SessionEventSink = {
    name = "SessionEventSink",
    interface_name =
      "IDL:tecgraf/openbus/session_service/v1_05/SessionEventSink:1.0",
    class = oop.class{
      push = function(self, sender, event)
        print("Membro "..sender.." enviou evento "..event.type.." com o valor "..event.value._anyval)
      end,
      disconnect = function(self, sender)
        print("Aviso de desconexão enviado pelo membro "..sender)
      end,
    }
  },
}

local componentId = {
  name = "Member",
  major_version = 1,
  minor_version = 0,
  patch_version = 0,
  platform_spec = ""
}

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
      if IDLPATH_DIR == nil then
        io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
        os.exit(1)
      end

      oil.verbose:level(0)

      orb:loadidlfile(IDLPATH_DIR.."/v1_05/session_service.idl")
      orb:loadidlfile(IDLPATH_DIR.."/v1_05/registry_service.idl")
      orb:loadidlfile(IDLPATH_DIR.."/v1_05/access_control_service.idl")
      orb:loadidlfile(IDLPATH_DIR.."/v1_04/session_service.idl")
      orb:loadidlfile(IDLPATH_DIR.."/v1_04/registry_service.idl")
      orb:loadidlfile(IDLPATH_DIR.."/v1_04/access_control_service.idl")


      local acsComp = orb:newproxy("corbaloc::localhost:2089/openbus_v1_05",
        "synchronous", "IDL:scs/core/IComponent:1.0")
      local facet = acsComp:getFacet(
        "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
      self.accessControlService = orb:narrow(facet,
        "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(
          loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config,
          self.credentialManager))
    end,

    -- Faz login antes de cada teste para obter uma nova credencial e não ter
    -- nenhuma sessão associada.
    beforeEachTest = function(self)
      _, self.credential = self.accessControlService:loginByPassword(user,
        password)
      self.credentialManager:setValue(self.credential)

      local acsIComp = self.accessControlService:_component()
      acsIComp = orb:narrow(acsIComp, "IDL:scs/core/IComponent:1.0")
      local acsIRecept = acsIComp:getFacetByName("IReceptacles")
      acsIRecept = orb:narrow(acsIRecept, "IDL:scs/core/IReceptacles:1.0")
      local conns = acsIRecept:getConnections("RegistryServiceReceptacle")
      local rsIComp = orb:narrow(conns[1].objref, "IDL:scs/core/IComponent:1.0")
      local registryService = rsIComp:getFacetByName("IRegistryService_v" .. Utils.OB_VERSION)
      registryService = orb:narrow(registryService,
         "IDL:tecgraf/openbus/core/v1_05/registry_service/IRegistryService:1.0")

      local serviceOffers = registryService:find({"ISessionService_v" .. Utils.OB_VERSION})
      Check.assertNotEquals(#serviceOffers, 0)
      local sessionServiceComponent = orb:narrow(serviceOffers[1].member,
          "IDL:scs/core/IComponent:1.0")
      self.sessionService = sessionServiceComponent:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISessionService:1.0")
      self.sessionService = orb:narrow(self.sessionService,
        "IDL:tecgraf/openbus/session_service/v1_05/ISessionService:1.0")
    end,

    afterEachTest = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

    testCreateSession = function(self)
      local member = scs.newComponent(facetDescriptions, {}, componentId)
      local success, session, id =
        self.sessionService:createSession(member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(session)
      Check.assertNotNil(id)
      session = session:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session = orb:narrow(session,
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      Check.assertTrue(session:removeMember(id))
    end,

    testCreateSession_AlreadyExists = function(self)
      local member1 = scs.newComponent(facetDescriptions, {}, componentId)
      local member2 = scs.newComponent(facetDescriptions, {}, componentId)

      local success, session1, session2, id1, id2
      success, session1, id1 =
        self.sessionService:createSession(member1.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(session1)
      Check.assertNotNil(id1)
      session1 = session1:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session1 = orb:narrow(session1,
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")

      success, session2, id2 =
        self.sessionService:createSession(member2.IComponent)
      Check.assertFalse(success)

      Check.assertTrue(session1:removeMember(id1))
    end,

    testGetSession = function(self)
      local member = scs.newComponent(facetDescriptions, {}, componentId)
      local success, session1, id =
        self.sessionService:createSession(member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(session1)
      Check.assertNotNil(id)
      session1 = session1:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session1 = orb:narrow(session1,
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")

      local session2 = self.sessionService:getSession()
      Check.assertNotNil(session2)
      session2 = session2:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session2 = orb:narrow(session2,
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      Check.assertEquals(session1:getIdentifier(), session2:getIdentifier())

      Check.assertTrue(session2:removeMember(id))
    end,

    testGetSession_NonExistent = function(self)
      Check.assertNil(self.sessionService:getSession())
    end,

    testAddRemoveMember = function(self)
      local member1 = scs.newComponent(facetDescriptions, {}, componentId)
      local member2 = scs.newComponent(facetDescriptions, {}, componentId)

      local success, session, id1, id2
      success, session, id1 =
        self.sessionService:createSession(member1.IComponent)
      session = session:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session = orb:narrow(session,
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      id2 = session:addMember(member2.IComponent)
      Check.assertTrue(id2 and id2 ~= "")

      local list = session:getMembers()
      Check.assertEquals(#list, 2)

      Check.assertTrue(session:removeMember(id2))
      Check.assertTrue(session:removeMember(id1))

      list = session:getMembers()
      Check.assertEquals(#list, 0)
    end,

    testRemove_InvalidIdentifier = function(self)
      local member = scs.newComponent(facetDescriptions, {}, componentId)
      local success, session, id =
        self.sessionService:createSession(member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(session)
      Check.assertNotNil(id)
      session = session:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session = orb:narrow(session,
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      Check.assertFalse(session:removeMember("INVALID_ID_FOR_SESSION"))
      Check.assertTrue(session:removeMember(id))
    end,

    testRemoveMember_Logout = function(self)
      local member1 = scs.newComponent(facetDescriptions, {}, componentId)
      local member2 = scs.newComponent(facetDescriptions, {}, componentId)

      local success, session, id1 =
        self.sessionService:createSession(member1.IComponent)
      session = session:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session = orb:narrow(session,
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")

      local _, credential = self.accessControlService:loginByPassword(user,
        password)
      self.credentialManager:setValue(credential)
      local id2 = session:addMember(member2.IComponent)
      Check.assertTrue(id2 and id2 ~= "")
      local list = session:getMembers()
      Check.assertEquals(#list, 2)

      self.accessControlService:logout(credential)
      socket.sleep(5)  -- espera o ACS avisar ao SS

      self.credentialManager:setValue(self.credential)
      list = session:getMembers()
      Check.assertEquals(#list, 1)
      Check.assertTrue(session:removeMember(id1))
    end,

    testDestroy_Logout = function(self)
      local member1 = scs.newComponent(facetDescriptions, {}, componentId)
      local member2 = scs.newComponent(facetDescriptions, {}, componentId)

      local _, credential = self.accessControlService:loginByPassword(user,
        password)
      self.credentialManager:setValue(credential)

      local success, session, id1 =
        self.sessionService:createSession(member1.IComponent)
      session = session:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session = orb:narrow(session,
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")

      self.credentialManager:setValue(self.credential)
      local id2 = session:addMember(member2.IComponent)

      self.credentialManager:setValue(credential)
      self.accessControlService:logout(credential)
      socket.sleep(5)  -- espera o ACS avisar ao SS

      self.credentialManager:setValue(self.credential)
      Check.assertTrue(session:_non_existent())
    end,

    testEvents = function(self)
      local member1 = scs.newComponent(facetDescriptions, {}, componentId)
      local member2 = scs.newComponent(facetDescriptions, {}, componentId)
      local member3 = scs.newComponent(facetDescriptions, {}, componentId)

      local success, sessionComponent, id1 =
        self.sessionService:createSession(member1.IComponent)

      local session = sessionComponent:getFacet(
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      session = orb:narrow(session,
        "IDL:tecgraf/openbus/session_service/v1_05/ISession:1.0")
      local sink = sessionComponent:getFacet(
          "IDL:tecgraf/openbus/session_service/v1_05/SessionEventSink:1.0")
      sink = orb:narrow(sink,
          "IDL:tecgraf/openbus/session_service/v1_05/SessionEventSink:1.0")

      local id2 = session:addMember(member2.IComponent)
      local id3 = session:addMember(member3.IComponent)

      -- Envio de eventos
      local my_any_value1 = { _anyval = "valor1",
          _anytype = oil.corba.idl.string }
      local my_any_value2 = { _anyval = "valor2",
          _anytype = oil.corba.idl.string }

      sink:push(id1, {type = "tipo1", value = my_any_value1})
      sink:push(id2, {type = "tipo2", value = my_any_value2})
      sink:disconnect(id3)

      -- Remove o segundo e o terceiro membros do barramento
      session:removeMember(id2)
      session:removeMember(id3)
    end,
  }
}
