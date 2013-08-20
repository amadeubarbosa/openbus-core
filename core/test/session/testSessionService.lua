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

local ComponentContext = require "scs.core.ComponentContext"

local Check = require "latt.Check"

-- Dados para login no barramento
local user     = "tester"
local password = "tester"

local SessionEventSink = {
  name = "SessionEventSink",
  interface_name = Utils.SESSION_ES_INTERFACE,
  class = oop.class{
    push = function(self, sender, event)
      print("Membro "..sender.." enviou evento "..event.type..
          " com o valor "..event.value._anyval)
    end,
    disconnect = function(self, sender)
      print("Aviso de desconexão enviado pelo membro "..sender)
    end,
  }
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

      orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/access_control_service.idl")
      orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/registry_service.idl")
      orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/session_service.idl")
      assert(orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/session_service_extended.idl"))
      orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_PREV.."/access_control_service.idl")

      local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
      assert(loadfile(
          OPENBUS_HOME.."/data/conf/AccessControlServerConfiguration.lua"))()
      local acsComp = orb:newproxy("corbaloc::"..
          AccessControlServerConfiguration.hostName..":"..
          AccessControlServerConfiguration.hostPort.."/"..Utils.OPENBUS_KEY,
          "synchronous", Utils.COMPONENT_INTERFACE)
      local facet = acsComp:getFacet(Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
      self.accessControlService = orb:narrow(facet,
          Utils.ACCESS_CONTROL_SERVICE_INTERFACE)

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
      acsIComp = orb:narrow(acsIComp, Utils.COMPONENT_INTERFACE)
      local acsIRecept = acsIComp:getFacetByName("IReceptacles")
      acsIRecept = orb:narrow(acsIRecept, "IDL:scs/core/IReceptacles:1.0")
      local conns = acsIRecept:getConnections("RegistryServiceReceptacle")
      local rsIComp = orb:narrow(conns[1].objref, Utils.COMPONENT_INTERFACE)
      local registryService = rsIComp:getFacetByName("IRegistryService_"..
          Utils.IDL_VERSION)
      registryService = orb:narrow(registryService,
          Utils.REGISTRY_SERVICE_INTERFACE)

      local serviceOffers = registryService:find(
          {Utils.SESSION_SERVICE_FACET_NAME})
      Check.assertNotEquals(#serviceOffers, 0)
      local sessionServiceComponent = orb:narrow(serviceOffers[1].member,
          Utils.COMPONENT_INTERFACE)
      self.sessionService = sessionServiceComponent:getFacet(
          Utils.SESSION_SERVICE_INTERFACE)
      self.sessionService = orb:narrow(self.sessionService,
          Utils.SESSION_SERVICE_INTERFACE)

      local SESSION_SERVICE_EXTENDED_INTERFACE = "IDL:tecgraf/openbus/session_service/"..
                                        Utils.IDL_VERSION.."/ISessionServiceExtended:1.0"
      self.sessionServiceExtended = sessionServiceComponent:getFacet(
          SESSION_SERVICE_EXTENDED_INTERFACE)
      self.sessionServiceExtended = orb:narrow(self.sessionServiceExtended,
          SESSION_SERVICE_EXTENDED_INTERFACE)
      Check.assertNotNil(self.sessionServiceExtended)
    end,

    afterEachTest = function(self)
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

    testCreateSession = function(self)
      local member = ComponentContext(orb, componentId)
      member:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())
      local success, session, id =
        self.sessionService:createSession(member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(session)
      Check.assertNotNil(id)
      session = session:getFacet(Utils.SESSION_INTERFACE)
      session = orb:narrow(session, Utils.SESSION_INTERFACE)
      Check.assertTrue(session:removeMember(id))
    end,

    testCreateSession_AlreadyExists = function(self)
      local member1 = ComponentContext(orb, componentId)
      member1:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())
      local member2 = ComponentContext(orb, componentId)
      member2:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())

      local success, session1, session2, id1, id2
      success, session1, id1 =
        self.sessionService:createSession(member1.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(session1)
      Check.assertNotNil(id1)
      session1 = session1:getFacet(Utils.SESSION_INTERFACE)
      session1 = orb:narrow(session1, Utils.SESSION_INTERFACE)

      success, session2, id2 =
        self.sessionService:createSession(member2.IComponent)
      Check.assertFalse(success)

      Check.assertTrue(session1:removeMember(id1))
    end,

    testGetSession = function(self)
      local member = ComponentContext(orb, componentId)
      member:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())
      local success, session1, id =
        self.sessionService:createSession(member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(session1)
      Check.assertNotNil(id)
      session1 = session1:getFacet(Utils.SESSION_INTERFACE)
      session1 = orb:narrow(session1, Utils.SESSION_INTERFACE)

      local session2 = self.sessionService:getSession()
      Check.assertNotNil(session2)
      session2 = session2:getFacet(Utils.SESSION_INTERFACE)
      session2 = orb:narrow(session2, Utils.SESSION_INTERFACE)
      Check.assertEquals(session1:getIdentifier(), session2:getIdentifier())

      local session3 = self.sessionServiceExtended:getSessionByCredentialId(self.credential.identifier)
      Check.assertNotNil(session3)
      session3 = session3:getFacet(Utils.SESSION_INTERFACE)
      session3 = orb:narrow(session3, Utils.SESSION_INTERFACE)
      Check.assertEquals(session1:getIdentifier(), session3:getIdentifier())
      Check.assertEquals(session2:getIdentifier(), session3:getIdentifier())

      Check.assertNil(self.sessionServiceExtended:getSessionByCredentialId("invalidid"))

      Check.assertTrue(session2:removeMember(id))
    end,

    testGetSession_NonExistent = function(self)
      Check.assertNil(self.sessionService:getSession())
    end,

    testAddRemoveMember = function(self)
      local member1 = ComponentContext(orb, componentId)
      member1:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())
      local member2 = ComponentContext(orb, componentId)
      member2:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())

      local success, session, id1, id2
      success, session, id1 =
        self.sessionService:createSession(member1.IComponent)
      session = session:getFacet(Utils.SESSION_INTERFACE)
      session = orb:narrow(session, Utils.SESSION_INTERFACE)
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
      local member = ComponentContext(orb, componentId)
      member:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())
      local success, session, id =
        self.sessionService:createSession(member.IComponent)
      Check.assertTrue(success)
      Check.assertNotNil(session)
      Check.assertNotNil(id)
      session = session:getFacet(Utils.SESSION_INTERFACE)
      session = orb:narrow(session, Utils.SESSION_INTERFACE)
      Check.assertFalse(session:removeMember("INVALID_ID_FOR_SESSION"))
      Check.assertTrue(session:removeMember(id))
    end,

    testRemoveMember_Logout = function(self)
      local member1 = ComponentContext(orb, componentId)
      member1:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())
      local member2 = ComponentContext(orb, componentId)
      member2:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())

      local success, session, id1 =
        self.sessionService:createSession(member1.IComponent)
      session = session:getFacet(Utils.SESSION_INTERFACE)
      session = orb:narrow(session, Utils.SESSION_INTERFACE)

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
      local member1 = ComponentContext(orb, componentId)
      member1:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())
      local member2 = ComponentContext(orb, componentId)
      member2:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())

      local _, credential = self.accessControlService:loginByPassword(user,
        password)
      self.credentialManager:setValue(credential)

      local success, session, id1 =
        self.sessionService:createSession(member1.IComponent)
      session = session:getFacet(Utils.SESSION_INTERFACE)
      session = orb:narrow(session, Utils.SESSION_INTERFACE)

      self.credentialManager:setValue(self.credential)
      local id2 = session:addMember(member2.IComponent)

      self.credentialManager:setValue(credential)
      self.accessControlService:logout(credential)
      socket.sleep(5)  -- espera o ACS avisar ao SS

      self.credentialManager:setValue(self.credential)
      Check.assertTrue(session:_non_existent())
    end,

    testEvents = function(self)
      local member1 = ComponentContext(orb, componentId)
      member1:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())
      local member2 = ComponentContext(orb, componentId)
      member2:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())
      local member3 = ComponentContext(orb, componentId)
      member3:addFacet(SessionEventSink.name, SessionEventSink.interface_name, SessionEventSink.class())

      local success, sessionComponent, id1 =
        self.sessionService:createSession(member1.IComponent)

      local session = sessionComponent:getFacet(Utils.SESSION_INTERFACE)
      session = orb:narrow(session, Utils.SESSION_INTERFACE)
      local sink = sessionComponent:getFacet(Utils.SESSION_ES_INTERFACE)
      sink = orb:narrow(sink, Utils.SESSION_ES_INTERFACE)

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
