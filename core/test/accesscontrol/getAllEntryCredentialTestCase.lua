--
-- Testes unit�rios para teste de carga -- Servi�o de Controle de Acesso
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
-- Compara se as credenciais passandas s�o iguais.
--
-- @param credential1 uma credencial
-- @param credential2 outra credencial
--
-- @return True se s�o iguais e false caso contr�rio
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
          -- loga com uma conta de administra��o
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
      -- loga com outra conta de usu�rio sem permiss�o de administra��o
      local success, credential = self.accessControlService:loginByPassword(self.login.user, self.login.password)
      Check.assertTrue(success)
      -- executa a chamada ainda com a conta do administrador
      local entries = self.accessControlService:getAllEntryCredential()
      Check.assertNotNil(entries)
      Check.assertTrue(#entries ~= 0)
      -- busca pelas credenciais do administrador e do usu�rio
      local found = 0
      for _,v in ipairs(entries) do
        if compareCredentials(v.aCredential, self.admCredential) or compareCredentials(v.aCredential, credential) then
          found = found + 1
        end  
      end
      -- deve encontrar as duas credenciais
      Check.assertEquals(found, 2)
      -- desloga o usu�rio
      Check.assertTrue(self.accessControlService:logout(credential))
      -- executa a chamada ainda com a conta do administrador
      entries = self.accessControlService:getAllEntryCredential()
      Check.assertNotNil(entries)
      Check.assertTrue(#entries ~= 0)
      -- busca pelas credenciais do administrador e do usu�rio
      found = 0
      for _,v in ipairs(entries) do
        if compareCredentials(v.aCredential, self.admCredential) or compareCredentials(v.aCredential, credential) then
          found = found + 1
        end  
      end
      -- s� deve encontrar a credencial do administrador
      Check.assertEquals(found, 1)
    end,

  },
  
  Test2 = {
    beforeTestCase = beforeTestCase,

    beforeEachTest = beforeEachTest,

    afterTestCase = afterTestCase,

    afterEachTest = afterEachTest,
    
    testGetAllEntryCredentialNoPermission = function(self)
      -- testa a chamada do m�todo com um login sem permiss�o de administrador.
      local success, err = oil.pcall(self.accessControlService.getAllEntryCredential, self.accessControlService)
      Check.assertFalse(success)
      Check.assertEquals(err[1], "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
    end,
    
  },

}

return Suite
