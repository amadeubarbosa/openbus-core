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
local afterTestCase = dofile("accesscontrol/afterTestCase.lua")


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

  },

  Test2 = {
    beforeTestCase = beforeTestCase,

    beforeEachTest = beforeEachTest,

    afterTestCase = afterTestCase,

    afterEachTest = afterEachTest,
    
    testGetEntryCredentialNoPermission = function(self)
      -- testa a chamada do método com um login sem permissão de administrador.
      local success, err = oil.pcall(self.accessControlService.getEntryCredential, self.accessControlService, self.credential)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,

  },

}

return Suite
