--
-- Testes unitários para mecanismo de consistência do estado do Serviço de Registro
--
--[[
  Esses testes assumem que existem *pelo menos* duas (2) réplicas do RGS.
--]]
local table = table
require "oil"
local orb = oil.orb
local Check = require "latt.Check"
local Utils = require "openbus.util.Utils"
local ComponentContext = require "scs.core.ComponentContext"
local oop = require "loop.base"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")

function loadidls(self)
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/registry_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_PREV.."/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_PREV.."/registry_service.idl")
  orb:loadidl("interface IHello_vft { };")
end

local beforeTestCaseFTRGS = dofile("registry/beforeTestCaseFTRGS.lua")
local afterTestCase = dofile("accesscontrol/afterTestCase.lua")

-------------------------------------------------------------------------------
-- Informações sobre os componentes usados nos testes
--

-- Descrições

local Hello_properties = {
  {name = "type",        value = {"IHello FT"}},
  {name = "description", value = {"IHello FT versão 1.0"}},
  {name = "version",     value = {"1.0"}},
  -- Teste de propriedade vazia
  {name = "bugs",        value = {}},
}

Suite = {

  Test1 = {
    beforeTestCase = beforeTestCaseFTRGS,

    afterTestCase = afterTestCase,

    testOffersSincronization =  function(self)
       Check.assertTrue(# self.ftconfig.hosts.RS > 1)

       local acsComp = orb:newproxy("corbaloc::"..
           self.acsHostName..":"..self.acsHostPort.."/"..Utils.OPENBUS_KEY,
           "synchronous", Utils.COMPONENT_INTERFACE)
       local facet = acsComp:getFacet(Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
       local acsFacet = orb:narrow(facet,
           Utils.ACCESS_CONTROL_SERVICE_INTERFACE)

       -- Login do serviço para a realização do teste
       local challenge = acsFacet:getChallenge(self.deploymentId)
       local privateKey = lce.key.readprivatefrompemfile(self.testKeyFile)
       challenge = lce.cipher.decrypt(privateKey, challenge)
       cert = lce.x509.readfromderfile(self.acsCertFile)
       challenge = lce.cipher.encrypt(cert:getpublickey(), challenge)
       local succ
       succ, self.credential, self.lease =
       acsFacet:loginByCertificate(self.deploymentId, challenge)
       self.credentialManager:setValue(self.credential)

       -- Recupera o Serviço de Registro
       local acsIComp = acsFacet:_component()
       acsIComp = orb:narrow(acsIComp, Utils.COMPONENT_INTERFACE)
       local acsIRecept = acsIComp:getFacetByName("IReceptacles")
       acsIRecept = orb:narrow(acsIRecept, "IDL:scs/core/IReceptacles:1.0")
       local conns = acsIRecept:getConnections("RegistryServiceReceptacle")
       local rsIComp1 = orb:narrow(conns[1].objref, Utils.COMPONENT_INTERFACE)
       local rsFacet1 = rsIComp1:getFacetByName("IRegistryService_" .. Utils.IDL_VERSION)
       rsFacet1 = orb:narrow(rsFacet1, Utils.REGISTRY_SERVICE_INTERFACE)
       rsFacet1 = orb:newproxy(rsFacet1, "protected")
       --cadastra oferta na primeira réplica
      local componentId = {
        name = "Hello_vft",
        major_version = 1,
        minor_version = 0,
        patch_version = 0,
        platform_spec = "",
      }
      local member = ComponentContext(orb, componentId)
      member:addFacet("IHello_vft", "IDL:IHello_vft:1.0", oop.class({})())

       -- Identificar local propositalmente
       local success, registryIdentifier = rsFacet1:register({
        member = member.IComponent,
        properties = Hello_properties,
       })
       Check.assertTrue(success)
       Check.assertNotNil(registryIdentifier)

       --busca em todas as réplicas (tem que encontrar)
       for connId,conn in pairs(conns) do
           if type (conn) == "table" then
                local rsIComp = orb:narrow(conns[connId].objref,
                    Utils.COMPONENT_INTERFACE)
                local rsFacet = rsIComp:getFacetByName("IRegistryService_"..
                    Utils.IDL_VERSION)
                rsFacet = orb:narrow(rsFacet, Utils.REGISTRY_SERVICE_INTERFACE)

                local offers = rsFacet:find({"IHello_vft"})
                Check.assertFalse(nil, offers[1])
           end
       end
       --descadastra oferta na primeira réplica
       local success, ret, retRemote = rsFacet1:unregister(registryIdentifier)
       Check.assertTrue(success)
       Check.assertTrue(ret)
       Check.assertTrue(retRemote)

       --busca oferta nas outras réplicas (nao deveria encontrar)
       for connId,conn in pairs(conns) do
           if type (conn) == "table" then
                local rsIComp = orb:narrow(conns[connId].objref,
                    Utils.COMPONENT_INTERFACE)
                local rsFacet = rsIComp:getFacetByName(
                    "IRegistryService_".. Utils.IDL_VERSION)
                rsFacet = orb:narrow(rsFacet, Utils.REGISTRY_SERVICE_INTERFACE)

                local offers = rsFacet:find({"IHello_vft"})
                Check.assertTrue(nil, offers[1])
           end
       end

       Check.assertTrue(acsFacet:logout(self.credential))
       self.credentialManager:invalidate()

    end,
  },

}

return Suite
