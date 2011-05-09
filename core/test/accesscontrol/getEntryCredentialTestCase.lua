--
-- Testes unitários para teste de carga -- Serviço de Controle de Acesso
--
local Check = require "latt.Check"
require "oil"
local orb = oil.orb

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")

local beforeTestCase = dofile("accesscontrol/beforeTestCase.lua")
local beforeEachTest = dofile("accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile("accesscontrol/afterEachTest.lua")

-- Credencial vazia
local emptyCredential = { identifier = "", owner = "", delegate = "" }

---
-- Compara se as credenciais passandas são iguais.
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

Suite = {

  Test1 = {
    beforeTestCase = beforeTestCase,

    beforeEachTest = beforeEachTest,

    afterTestCase = afterTestCase,

    testGetEntryCredential = function(self)
      -- loga com uma conta de administração
      local success, admCredential = self.accessControlService:loginByPassword("tester", "tester")
      Check.assertTrue(success)
      self.credentialManager:setValue(admCredential)
      local entry = self.accessControlService:getEntryCredential(admCredential)
      Check.assertNotNil(entry)
      Check.assertTrue(compareCredentials(entry.aCredential, admCredential))
    end,

    testGetEntryCredentialOfOtherUser = function(self)
      -- loga com uma conta de administração
      local success, admCredential = self.accessControlService:loginByPassword("tester", "tester")
      Check.assertTrue(success)
      self.credentialManager:setValue(admCredential)
      -- recupera o Entry de uma credencial de outro usuário
      local entry = self.accessControlService:getEntryCredential(self.credential)
      Check.assertNotNil(entry)
      Check.assertTrue(compareCredentials(entry.aCredential, self.credential))
      Check.assertFalse(compareCredentials(entry.aCredential, admCredential))
    end,

    testGetEntryCredentialNoPermission = function(self)
      -- testa a chamada do método com um login sem permissão de administrador.
      local success, err = oil.pcall(self.accessControlService.getEntryCredential, self.accessControlService, self.credential)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

    testGetEntryCredentialInvalidCredential = function(self)
      -- loga com uma conta de administração
      local success, admCredential = self.accessControlService:loginByPassword("tester", "tester")
      Check.assertTrue(success)
      self.credentialManager:setValue(admCredential)
      -- passa uma credencial inválida.
      local invalidCredential = {}
      invalidCredential.identifier = "unknown"
      invalidCredential.owner = "unknown"
      invalidCredential.delegate = "false"
      local entry = self.accessControlService:getEntryCredential(invalidCredential)
      Check.assertNotNil(entry)
      Check.assertFalse(compareCredentials(entry.aCredential, invalidCredential))
      Check.assertTrue(compareCredentials(entry.aCredential, emptyCredential))
    end,

  },

}

return Suite
