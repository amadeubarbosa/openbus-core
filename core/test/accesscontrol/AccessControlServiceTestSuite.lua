--
-- Suite de Testes do Serviço de Controle de Acesso
--
require "oil"
local orb = oil.orb
local Utils = require "openbus.util.Utils"
local Check = require "latt.Check"

local beforeTestCase = dofile("accesscontrol/beforeTestCase.lua")
local beforeEachTest = dofile("accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile("accesscontrol/afterEachTest.lua")
local afterTestCase = dofile("accesscontrol/afterTestCase.lua")

--------------------------------------------------------------------------------
-- Funções auxiliares dos testes
--------------------------------------------------------------------------------

---
-- Compara se as credenciais passadas são iguais.
--
-- @param credential1 uma credencial
-- @param credential2 outra credencial
--
-- @return True se são iguais e false caso contrário
---
local function compareCredentials(credential1, credential2)
  for k,_ in pairs (credential1) do
    if credential1[k] ~= credential2[k] then
      return false
    end
  end 
  return true
end

--------------------------------------------------------------------------------

Suite = {

  Test1 = { -- testes apenas com beforeTestCase e afterTestCase
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    testLoginByPassword = function(self)
      local success, credential = self.accessControlService:loginByPassword(self.login.user, self.login.password)
      Check.assertTrue(success)

      local success, credential2 = self.accessControlService:loginByPassword(self.login.user, self.login.password)
      Check.assertTrue(success)
      Check.assertNotEquals(credential.identifier, credential2.identifier)

      self.credentialManager:setValue(credential)
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialManager:setValue(credential2)
      Check.assertTrue(self.accessControlService:logout(credential2))
      self.credentialManager:invalidate()
    end,

    testInvalidLoginByPassword = function(self)
      local success, credential = 
        self.accessControlService:loginByPassword("INVALID", "INVALID")
      Check.assertFalse(success)
      Check.assertEquals("", credential.identifier)
    end,

    testLogout = function(self)
      local _, credential =
          self.accessControlService:loginByPassword(self.login.user, 
            self.login.password)
      self.credentialManager:setValue(credential)
      Check.assertFalse(self.accessControlService:logout({identifier = "", owner = "abcd", delegate = "", }))
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialManager:invalidate(credential)
      Check.assertError(self.accessControlService.logout,self.accessControlService,credential)
    end,
    
    testLoginByCertificate = function(self)
      local challenge =
      self.accessControlService:getChallenge(self.deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local privateKey = lce.key.readprivatefrompemfile(self.testKeyFile)
      Check.assertNotNil(privateKey)
      local succ, err
      succ, challenge, err = oil.pcall(lce.cipher.decrypt, privateKey, challenge)
      Check.assertNotNil(challenge)
      local certificate = lce.x509.readfromderfile(self.acsCertFile)
      Check.assertNotNil(certificate)
      local answer = lce.cipher.encrypt(certificate:getpublickey(), challenge)
      Check.assertNotNil(answer)
      local succ, credential, lease = self.accessControlService:loginByCertificate(self.deploymentId, answer)
      Check.assertTrue(succ)
      self.credentialManager:setValue(credential)
      self.accessControlService:logout(credential)
      self.credentialManager:invalidate()
    end,

    testLogoutAfterLoginByCertificate = function(self)
      local challenge = self.accessControlService:getChallenge(self.deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local privateKey = lce.key.readprivatefrompemfile(self.testKeyFile)
      Check.assertNotNil(privateKey)
      challenge = lce.cipher.decrypt(privateKey, challenge)
      Check.assertNotNil(challenge)
      local certificate = lce.x509.readfromderfile(self.acsCertFile)
      Check.assertNotNil(certificate)
      local answer = lce.cipher.encrypt(certificate:getpublickey(), challenge)
      Check.assertNotNil(answer)
      local succ, credential, lease =
          self.accessControlService:loginByCertificate(self.deploymentId,
          answer)
      Check.assertTrue(succ)
      self.credentialManager:setValue(credential)
      Check.assertFalse(self.accessControlService:logout({
        identifier = "InvalidIdentifier",
        owner = "InvalidName",
        delegate = "",
      }))
      Check.assertTrue(self.accessControlService:logout(credential))
      self.credentialManager:invalidate(credential)
      Check.assertError(self.accessControlService.logout, self.accessControlService, credential)
    end,

    testLoginByCertificate_WrongAnswer = function(self)
      local challenge =
          self.accessControlService:getChallenge(self.deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local privateKey = lce.key.readprivatefrompemfile(self.testKeyFile)
      Check.assertNotNil(privateKey)
      challenge = lce.cipher.decrypt(privateKey, challenge)
      Check.assertNotNil(challenge)
      local certificate = lce.x509.readfromderfile(self.acsCertFile)
      Check.assertNotNil(certificate)
      local answer = lce.cipher.encrypt(certificate:getpublickey(), challenge.."->Wrong")
      Check.assertNotNil(answer)
      local succ =
          self.accessControlService:loginByCertificate(self.deploymentId,
          answer)
      Check.assertFalse(succ)
    end,

    testLoginByCertificate_NoEncryption = function(self)
      local challenge = self.accessControlService:getChallenge(self.deploymentId)
      Check.assertTrue(challenge and #challenge > 0)
      local succ =
          self.accessControlService:loginByCertificate(self.deploymentId,
          "InvalidAnswer")
      Check.assertFalse(succ)
    end,

  },

  Test2 = { -- testes com beforeTestCase, beforeEachTest, afterEachTest e afterTestCase
    beforeTestCase = beforeTestCase,

    afterTestCase = afterTestCase,

    beforeEachTest = beforeEachTest,

    afterEachTest = afterEachTest,

    testIsValid = function(self)
      Check.assertTrue(self.accessControlService:isValid(self.credential))
      Check.assertFalse(self.accessControlService:isValid({identifier = "123", owner = self.login.user, delegate = "",}))
      self.accessControlService:logout(self.credential)
      -- neste caso o proprio interceptador do serviço rejeita o request
      Check.assertFalse(self.accessControlService:isValid(self.credential))
      self.credentialManager:invalidate()
    end,

    testIsValidPasswordDelegate = function(self)
      Check.assertTrue(self.accessControlService:isValid(self.credential))
      local delegatedCredential = {
        identifier = self.credential.identifier,
        owner = self.credential.identifier,
        delegate = "DELEGATE",
      }
      Check.assertFalse(self.accessControlService:isValid(delegatedCredential))
    end,

    testAreValid = function(self)
      local credentials = {self.credential, {identifier = "INVALID_IDENTIFIER", owner = self.login.user, delegate = "",},}
      local results = self.accessControlService:areValid(credentials)
      Check.assertTrue(results[1])
      Check.assertFalse(results[2])
      credentials = {{identifier = "INVALID_IDENTIFIER", owner = self.login.user, delegate = "",}, self.credential}
      results = self.accessControlService:areValid(credentials)
      Check.assertFalse(results[1])
      Check.assertTrue(results[2])

      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
    end,

    testInvalidGetChallenge = function(self)
      local challenge = self.accessControlService:getChallenge("InvalidNameForChallenge")
      Check.assertTrue(not challenge or #challenge == 0)
      challenge = self.accessControlService:getChallenge("")
      Check.assertTrue(not challenge or #challenge == 0)
    end,

    testObservers = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential, credential)
      end
      credentialObserver = orb:newservant(credentialObserver, nil,
          Utils.CREDENTIAL_OBSERVER_INTERFACE)
      local observerIdentifier = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      Check.assertNotEquals("", observerIdentifier)
      Check.assertTrue(self.accessControlService:removeObserver(observerIdentifier))
      Check.assertFalse(self.accessControlService:removeObserver(observerIdentifier))
    end,

    testObserversLogout = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential.identifier, credential.identifier)
      end
      credentialObserver = orb:newservant(credentialObserver, nil,
          Utils.CREDENTIAL_OBSERVER_INTERFACE)
      local observersId = {}
      for i=1,3 do
        observersId[i] = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      end
      local oldCredential = self.credential
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      _, self.credential =
          self.accessControlService:loginByPassword(self.login.user, self.login.password)
      self.credentialManager:setValue(self.credential)
      for i=1,3 do
        Check.assertFalse(self.accessControlService:removeCredentialFromObserver(
            observersId[i], oldCredential.identifier))
      end
    end,

    testAddCredentialToOberserver = function(self)
      -- criando observador
      local credentialObserver = { credentials = {} }
      function credentialObserver:credentialWasDeleted(credential)
        local found = false
        -- verifica se a credencial esta na lista de credenciais observadas
        for id, cred in pairs(self.credentials) do
          if id == credential.identifier then
            found = compareCredentials(cred, credential)
          end
        end
        Check.assertTrue(found)
      end
      credentialObserver = orb:newservant(credentialObserver, nil,
          Utils.CREDENTIAL_OBSERVER_INTERFACE)
      -- adicionando a credencial do usuário 1 no observador
      credentialObserver.credentials[self.credential.identifier] = self.credential
      local observerId = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      -- realizando novo login
      local _, user2Credential = self.accessControlService:loginByPassword(
        self.login.user, self.login.password)
      -- adicionando a credencial do usuario 2 no observador
      credentialObserver.credentials[user2Credential.identifier] = user2Credential
      Check.assertTrue(self.accessControlService:addCredentialToObserver(
        observerId, user2Credential.identifier))
      -- removendo o usuário 2
      self.accessControlService:logout(user2Credential)
      Check.assertFalse(self.accessControlService:removeCredentialFromObserver(
        observerId, user2Credential.identifier))
      -- removendo o primeiro usuário
      local user1Credential = self.credential
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      -- logando um usuario 3
      _, self.credential =
          self.accessControlService:loginByPassword(self.login.user, self.login.password)
      self.credentialManager:setValue(self.credential)
      Check.assertFalse(self.accessControlService:removeCredentialFromObserver(
        observerId, user1Credential.identifier))
    end,

    testAddInvalidCredentialToObeserver = function (self)
      -- criando observador
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential.identifier, credential.identifier)
      end
      credentialObserver = orb:newservant(credentialObserver, nil,
          Utils.CREDENTIAL_OBSERVER_INTERFACE)
      local observerId = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      -- credencial inválida.
      local invalidCredential = {}
      invalidCredential.identifier = "unknown"
      invalidCredential.owner = "unknown"
      invalidCredential.delegate = "false"
      -- adiciona uma credencial inválida
      Check.assertFalse(self.accessControlService:addCredentialToObserver(
        observerId, invalidCredential.identifier))
    end,

    testRemoveCredentialFromObserver = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential.identifier, credential.identifier)
      end
      credentialObserver = orb:newservant(credentialObserver, nil,
          Utils.CREDENTIAL_OBSERVER_INTERFACE)
      local observersId = {}
      for i=1,3 do
        observersId[i] = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      end
      local oldCredential = self.credential
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      _, self.credential =
          self.accessControlService:loginByPassword(self.login.user, self.login.password)
      self.credentialManager:setValue(self.credential)
      for i=1,3 do
        Check.assertFalse(self.accessControlService:removeCredentialFromObserver(observersId[i], oldCredential.identifier))
      end
    end,

    testRemoveObserver = function(self)
      local credentialObserver = { credential = self.credential }
      function credentialObserver:credentialWasDeleted(credential)
        Check.assertEquals(self.credential.identifier, credential.identifier)
      end
      credentialObserver = orb:newservant(credentialObserver, nil,
          Utils.CREDENTIAL_OBSERVER_INTERFACE)
      local observerId = self.accessControlService:addObserver(credentialObserver, {self.credential.identifier,})
      self.accessControlService:logout(self.credential)
      self.credentialManager:invalidate()
      _, self.credential = self.accessControlService:loginByPassword(self.login.user, self.login.password)
      self.credentialManager:setValue(self.credential)
      Check.assertFalse(self.accessControlService:removeObserver(observerId))
    end,

    testGetEntryCredentialNoPermission = function(self)
      -- testa a chamada do método com um login sem permissão de administrador.
      local success, err = oil.pcall(self.accessControlService.getEntryCredential, self.accessControlService, self.credential)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testGetAllEntryCredentialNoPermission = function(self)
      -- testa a chamada do método com um login sem permissão de administrador.
      local success, err = oil.pcall(self.accessControlService.getAllEntryCredential, self.accessControlService)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

  },

  Test3 = { -- testes com before e after each personalizados.
    beforeTestCase = beforeTestCase,

    beforeEachTest = function(self)
      -- loga com uma conta de administração
      _, self.admCredential =
          self.accessControlService:loginByPassword("tester", "tester")
      self.credentialManager:setValue(self.admCredential)
    end,

    afterTestCase = afterTestCase,

    afterEachTest = function(self)
      -- desloga o administrador
      if (self.credentialManager:hasValue()) then
        self.accessControlService:logout(self.admCredential)
        self.credentialManager:invalidate()
      end
    end,

    testGetEntryCredential = function(self)
      local entry = self.accessControlService:getEntryCredential(self.admCredential)
      Check.assertNotNil(entry)
      Check.assertTrue(compareCredentials(entry.aCredential, self.admCredential))
    end,

    testGetEntryCredentialOfOtherUser = function(self)
      -- loga com outra conta sem permissão de administração
      local success, credential = self.accessControlService:loginByPassword(self.login.user, self.login.password)
      Check.assertTrue(success)
      -- recupera o Entry de uma credencial de outro usuário
      local entry = self.accessControlService:getEntryCredential(credential)
      Check.assertNotNil(entry)
      Check.assertTrue(compareCredentials(entry.aCredential, credential))
      Check.assertFalse(compareCredentials(entry.aCredential, self.admCredential))
      self.accessControlService:logout(credential)
    end,

    testGetEntryCredentialInvalidCredential = function(self)
      -- passa uma credencial inválida.
      local invalidCredential = {}
      invalidCredential.identifier = "unknown"
      invalidCredential.owner = "unknown"
      invalidCredential.delegate = "false"
      -- Credencial vazia
      local emptyCredential = { identifier = "", owner = "", delegate = "" }
      local entry = self.accessControlService:getEntryCredential(invalidCredential)
      Check.assertNotNil(entry)
      Check.assertFalse(compareCredentials(entry.aCredential, invalidCredential))
      Check.assertTrue(compareCredentials(entry.aCredential, emptyCredential))
    end,

    testGetAllEntryCredential = function(self)
      local entries = self.accessControlService:getAllEntryCredential()
      Check.assertNotNil(entries)
      Check.assertTrue(#entries ~= 0)
      -- busca pela credencial do administrador
      local found = 0
      for _,v in ipairs(entries) do
        if compareCredentials(v.aCredential, self.admCredential) then
          found = found + 1
        end  
      end
      Check.assertEquals(found, 1)
    end,

    testGetAllEntryCredentialLogginOtherUser = function(self)
      -- loga com outra conta de usuário sem permissão de administração
      local success, credential = self.accessControlService:loginByPassword(self.login.user, self.login.password)
      Check.assertTrue(success)
      -- executa a chamada ainda com a conta do administrador
      local entries = self.accessControlService:getAllEntryCredential()
      Check.assertNotNil(entries)
      Check.assertTrue(#entries ~= 0)
      -- busca pelas credenciais do administrador e do usuário
      local found = 0
      for _,v in ipairs(entries) do
        if compareCredentials(v.aCredential, self.admCredential) or
           compareCredentials(v.aCredential, credential) then
          found = found + 1
        end  
      end
      -- deve encontrar as duas credenciais
      Check.assertEquals(found, 2)
      -- desloga o usuário
      Check.assertTrue(self.accessControlService:logout(credential))
      -- executa a chamada ainda com a conta do administrador
      entries = self.accessControlService:getAllEntryCredential()
      Check.assertNotNil(entries)
      Check.assertTrue(#entries ~= 0)
      -- busca pelas credenciais do administrador e do usuário
      found = 0
      for _,v in ipairs(entries) do
        if compareCredentials(v.aCredential, self.admCredential) or
           compareCredentials(v.aCredential, credential) then
          found = found + 1
        end  
      end
      -- só deve encontrar a credencial do administrador
      Check.assertEquals(found, 1)
    end,

  }
}
