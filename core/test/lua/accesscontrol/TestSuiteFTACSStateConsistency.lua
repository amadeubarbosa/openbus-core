--
-- Testes unitários para mecanismo de consistência do estado do Serviço de Controle de Acesso
--
--[[
  Esses testes assumem que existem *pelo menos* duas (2) réplicas do ACS e *somente* uma do RGS.
--]]
local table = table
require "oil"
local orb = oil.orb
local Check = require "latt.Check"
local Utils = require "openbus.util.Utils"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")

function loadidls(self)
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  local idlfile = IDLPATH_DIR.."/v1_05/access_control_service.idl"
  orb:loadidlfile(idlfile)
  idlfile = IDLPATH_DIR.."/v1_04/access_control_service.idl"
  orb:loadidlfile(idlfile)
end

local beforeTestCaseFTACS = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/beforeTestCaseFTACS.lua")
local afterTestCase = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterTestCase.lua")
local beforeEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/beforeEachTest.lua")
local afterEachTest = dofile(OPENBUS_HOME .."/core/test/lua/accesscontrol/afterEachTest.lua")

Suite = {

  Test1 = {
    beforeTestCase = beforeTestCaseFTACS,

    testCredentialSincronization =  function(self)

       if # self.ftconfig.hosts.ACS > 1 then

          acsFacet = {}
          for i, host in pairs(self.ftconfig.hosts.ACS) do
              local ret, stop, acs = oil.pcall(Utils.fetchService,
                                                       orb,
                                                       self.ftconfig.hosts.ACS[i],
                                                       Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
              Check.assertTrue(stop)
              table.insert(acsFacet,acs)
          end
          --loga na primeira réplica
          local success, credential = acsFacet[1]:loginByPassword(self.login.user, self.login.password)
          Check.assertTrue(success)
          self.credentialManager:setValue(credential)
          oil.sleep(1)
          --verifica se a credencial é válida nas outras réplicas
          for i, host in pairs(self.ftconfig.hosts.ACS) do
             if i > 1 then
                local isValid = acsFacet[i]:isValid(credential)
                Check.assertTrue(isValid)
             end
          end
          Check.assertTrue(acsFacet[1]:logout(credential))
          oil.sleep(1)
          --verifica se a credencial é inválida nas outras réplicas
          for i, host in pairs(self.ftconfig.hosts.ACS) do
             if i > 1 then
                local isValid = acsFacet[i]:isValid(credential)
                Check.assertFalse(isValid)
             end

          end

          self.credentialManager:invalidate()
       end
    end,

    testRegistryServiceConnectionSincronization =  function(self)

       if # self.ftconfig.hosts.ACS > 1 then

          acsFacet = {}
          for i, host in pairs(self.ftconfig.hosts.ACS) do
              local ret, stop, acs = oil.pcall(Utils.fetchService,
                                                      orb,
                                                      self.ftconfig.hosts.ACS[i],
                                                      Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
              Check.assertTrue(stop)
              table.insert(acsFacet,acs)
          end
          --loga na primeira réplica
          local success, credential = acsFacet[1]:loginByPassword(self.login.user, self.login.password)
          Check.assertTrue(success)
          self.credentialManager:setValue(credential)

          -- Recupera o Serviço de Registro a partir da primeira réplica
          local acsIComp1 = acsFacet[1]:_component()
          acsIComp1 = orb:narrow(acsIComp1, "IDL:scs/core/IComponent:1.0")
          local acsIRecept1 = acsIComp1:getFacetByName("IReceptacles")
          acsIRecept1 = orb:narrow(acsIRecept1, "IDL:scs/core/IReceptacles:1.0")
          local conns1 = acsIRecept1:getConnections("RegistryServiceReceptacle")
          local rsIComp1 = orb:narrow(conns1[1].objref, "IDL:scs/core/IComponent:1.0")

          Check.assertNotNil(rsIComp1)

          -- Recupera o Serviço de Registro a partir da segunda réplica
          local acsIComp2 = acsFacet[2]:_component()
          acsIComp2 = orb:narrow(acsIComp2, "IDL:scs/core/IComponent:1.0")
          local acsIRecept2 = acsIComp2:getFacetByName("IReceptacles")
          acsIRecept2 = orb:narrow(acsIRecept2, "IDL:scs/core/IReceptacles:1.0")
          local conns2 = acsIRecept2:getConnections("RegistryServiceReceptacle")
          local rsIComp2 = orb:narrow(conns2[1].objref, "IDL:scs/core/IComponent:1.0")

          Check.assertNotNil(rsIComp2)

          --Desconecta o RGS do ACS
          acsIRecept1:disconnect(1)
          oil.sleep(2)
          --verifica se desconectou na segunda replica
          local conns2 = acsIRecept2:getConnections("RegistryServiceReceptacle")
          Check.assertNil(conns2[1])

          Check.assertTrue(acsFacet[1]:logout(credential))
          --espera para deslogar nas outras replicas
          oil.sleep(2)

          self.credentialManager:invalidate()
       end
    end,

  },

}

return Suite
