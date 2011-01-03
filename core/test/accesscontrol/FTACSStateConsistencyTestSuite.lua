--
-- Suite de Testes para mecanismo de consist�ncia do estado do Servi�o de Controle de Acesso
--
--[[
  Esses testes assumem que existem *pelo menos* duas (2) r�plicas do ACS e *somente* uma do RGS.
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
  local idlfile = IDLPATH_DIR.."/"..Utils.OB_VERSION.."/access_control_service.idl"
  orb:loadidlfile(idlfile)
  idlfile = IDLPATH_DIR.."/"..Utils.OB_PREV.."/access_control_service.idl"
  orb:loadidlfile(idlfile)
end

local beforeTestCaseFTACS = dofile("accesscontrol/beforeTestCaseFTACS.lua")

Suite = {

  Test1 = {
    beforeTestCase = beforeTestCaseFTACS,

    testCredentialSincronization =  function(self)

       Check.assertTrue(# self.ftconfig.hosts.ACS > 1)
       local acsFacet = {}
       for i, host in pairs(self.ftconfig.hosts.ACS) do
          local ret, stop, acs = oil.pcall(Utils.fetchService,
                                           orb,
                                           self.ftconfig.hosts.ACS[i],
                                           Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
          Check.assertTrue(stop)
          table.insert(acsFacet,acs)
       end
       --loga na primeira r�plica
       local success, credential = acsFacet[1]:loginByPassword(self.login.user, self.login.password)
       Check.assertTrue(success)
       self.credentialManager:setValue(credential)
       oil.sleep(1)
       --verifica se a credencial � v�lida nas outras r�plicas
       for i, host in pairs(self.ftconfig.hosts.ACS) do
          if i > 1 then
             local isValid = acsFacet[i]:isValid(credential)
             Check.assertTrue(isValid)
          end
       end
       Check.assertTrue(acsFacet[1]:logout(credential))
       oil.sleep(1)
       --verifica se a credencial � inv�lida nas outras r�plicas
       for i, host in pairs(self.ftconfig.hosts.ACS) do
          if i > 1 then
              local isValid = acsFacet[i]:isValid(credential)
              Check.assertFalse(isValid)
          end
       end

       self.credentialManager:invalidate()

    end,

    testRegistryServiceConnectionSincronization =  function(self)

       Check.assertTrue(# self.ftconfig.hosts.ACS > 1)
       local acsFacet = {}
       for i, host in pairs(self.ftconfig.hosts.ACS) do
           local ret, stop, acs = oil.pcall(Utils.fetchService,
                                            orb,
                                            self.ftconfig.hosts.ACS[i],
                                            Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
           Check.assertTrue(stop)
           table.insert(acsFacet,acs)
       end
       --loga na primeira r�plica
       local success, credential = acsFacet[1]:loginByPassword(self.login.user, self.login.password)
       Check.assertTrue(success)
       self.credentialManager:setValue(credential)

       -- Recupera o Servi�o de Registro a partir da primeira r�plica
       local acsIComp1 = acsFacet[1]:_component()
       acsIComp1 = orb:narrow(acsIComp1, "IDL:scs/core/IComponent:1.0")
       local acsIRecept1 = acsIComp1:getFacetByName("IReceptacles")
       acsIRecept1 = orb:narrow(acsIRecept1, "IDL:scs/core/IReceptacles:1.0")
       local conns1 = acsIRecept1:getConnections("RegistryServiceReceptacle")
       local rsIComp1 = orb:narrow(conns1[1].objref, "IDL:scs/core/IComponent:1.0")

       Check.assertNotNil(rsIComp1)

       -- Recupera o Servi�o de Registro a partir da segunda r�plica
       local acsIComp2 = acsFacet[2]:_component()
       acsIComp2 = orb:narrow(acsIComp2, "IDL:scs/core/IComponent:1.0")
       local acsIRecept2 = acsIComp2:getFacetByName("IReceptacles")
       acsIRecept2 = orb:narrow(acsIRecept2, "IDL:scs/core/IReceptacles:1.0")
       local conns2 = acsIRecept2:getConnections("RegistryServiceReceptacle")
       local rsIComp2 = orb:narrow(conns2[1].objref, "IDL:scs/core/IComponent:1.0")

       Check.assertNotNil(rsIComp2)

       --INICIO:Comentei esse teste porque o RGS se reconecta mais r�pido
       --       do que o teste. Pensar em uma abordagem melhor, talvez
       --       mantando o processo do RGS para conseguir verificar a desconex�o
       --Desconecta o RGS da primeira replica do ACS
       --acsIRecept1:disconnect(1)
       --oil.sleep(2)
       --verifica se desconectou na segunda replica
       --conns2 = acsIRecept2:getConnections("RegistryServiceReceptacle")
       --Check.assertNil(conns2[1])
       --FIM

       Check.assertTrue(acsFacet[1]:logout(credential))
       --espera para deslogar nas outras replicas
       oil.sleep(2)

       self.credentialManager:invalidate()

    end,

  },

}

return Suite
