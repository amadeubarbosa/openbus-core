--
-- Testes unit�rios do Servi�o de Controle de Acesso
-- $Id$
--
require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialHolder = require "openbus.common.CredentialHolder"

local Check = require "latt.Check"

Suite = {
  --
  -- este teste n�o precisa inserir credencial no contexto das requisi��es
  -- 
  Test1 = {
    beforeTestCase = function(self)
      local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
      if CORBA_IDL_DIR == nil then
        io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end
      local idlfile = CORBA_IDL_DIR.."/access_control_service.idl"

      oil.verbose:level(0)
      oil.loadidlfile(idlfile)

      self.user = "csbase"
      self.password = "csbLDAPtest"

      self.accessControlService = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local CONF_DIR = os.getenv("CONF_DIR")
      local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
      self.credentialHolder = CredentialHolder()
      oil.setclientinterceptor(ClientInterceptor(config, self.credentialHolder))
    end,

    testLoginByPassword = function(self)
      local success, credential = self.accessControlService:loginByPassword(self.user, self.password)
      Check.assertTrue(success)

      local success, credential2 = self.accessControlService:loginByPassword(self.user, self.password)
      Check.assertTrue(success)
      Check.assertNotEquals(credential.identifier, credential2.identifier)

      self.credentialHolder:setValue(credential) 
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialHolder:setValue(credential2) 
      Check.assertTrue(self.accessControlService:logout(credential2))
      self.credentialHolder:invalidate()
    end,

    testLoginByPassword2 = function(self)
      local success, credential = self.accessControlService:loginByPassword("INVALID", "INVALID")
      Check.assertFalse(success)
      Check.assertEquals("", credential.identifier)
    end,

    testLogout = function(self)
      local _, credential = self.accessControlService:loginByPassword(self.user, self.password)
      self.credentialHolder:setValue(credential) 
      Check.assertFalse(self.accessControlService:logout({identifier = "", entityName = "abcd", }))
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialHolder:invalidate(credential) 
      Check.assertError(self.accessControlService.logout,self.accessControlService,credential)
    end,
  },

  Test2 = {
    beforeTestCase = function(self)
      local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
      if CORBA_IDL_DIR == nil then
        io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
        os.exit(1)
      end
      local idlfile = CORBA_IDL_DIR.."/access_control_service.idl"

      oil.verbose:level(0)
      oil.loadidlfile(idlfile)

      self.user = "csbase"
      self.password = "csbLDAPtest"

      self.accessControlService = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local CONF_DIR = os.getenv("CONF_DIR")
      local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
      self.credentialHolder = CredentialHolder()
      oil.setclientinterceptor(ClientInterceptor(config, self.credentialHolder))
    end,

    beforeEachTest = function(self)
      _, self.credential = self.accessControlService:loginByPassword(self.user, self.password)
    self.credentialHolder:setValue(self.credential)
    end,

    afterEachTest = function(self)
      if (self.credentialHolder:hasValue()) then
        self.accessControlService:logout(self.credential)
        self.credentialHolder:invalidate()
      end
    end,

    testGetRegistryService = function(self)
      Check.assertNil(self.accessControlService:getRegistryService())
    end,

    testSetRegistryService = function(self)
      Check.assertFalse(self.accessControlService:setRegistryService(self.accessControlService))
    end,

    testIsValid = function(self)
      Check.assertTrue(self.accessControlService:isValid(self.credential))
      Check.assertFalse(self.accessControlService:isValid({entityName=self.user, identifier = "123"}))
      self.accessControlService:logout(self.credential)

      -- neste caso o proprio interceptador do servi�o rejeita o request
      Check.assertError(self.accessControlService.isValid,self.accessControlService,self.credential)
      self.credentialHolder:invalidate()
    end,

    testObservers = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential, credential)
      end
      credentialObserver = oil.newobject(credentialObserver, "IDL:openbusidl/acs/ICredentialObserver:1.0")
      local observerIdentifier = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      Check.assertNotEquals("", observerIdentifier)
      Check.assertTrue(self.accessControlService:removeObserver(observerIdentifier))
      Check.assertFalse(self.accessControlService:removeObserver(observerIdentifier))
    end,
  },
}
