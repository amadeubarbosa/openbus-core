local _G = require "_G"
local io = _G.io
local pcall = _G.pcall
local pcall = _G.pcall
local table = _G.table
local string = _G.string
local ipairs = _G.ipairs

local oil = require "oil"
local oillog = require "oil.verbose"
local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local ComponentContext = require "scs.core.ComponentContext"

local openbus = require "openbus"
local log = require "openbus.util.logger"
local server = require "openbus.util.server"
local setuplog = server.setuplog
local Check = require "latt.Check"

local idl = require "openbus.core.idl"
local offertypes = idl.types.services.offer_registry

-- Configurações --------------------------------------------------------------
local host = "localhost"
local port = 2089
local dUser = "user"
local dPassword = "user"
local entity = "TestEntity"
local sdklevel = 5
local oillevel = 0 

local scsutils = require ("scs.core.utils")()
local props = {}
scsutils:readProperties(props, "test.properties")
scsutils = nil

host = props:getTagOrDefault("host", host)
port = props:getTagOrDefault("port", port)
admin = props:getTagOrDefault("adminLogin", admin)
adminPassword = props:getTagOrDefault("adminPassword", adminPassword)
dUser = props:getTagOrDefault("login", dUser)
dPassword = props:getTagOrDefault("password", dPassword)
entity = props:getTagOrDefault("entity", entity)
sdklevel = props:getTagOrDefault("sdkLogLevel", sdklevel)
oillevel = props:getTagOrDefault("oilLogLevel", oillevel)

-- Casos de Teste -------------------------------------------------------------
Suite = {}
Suite.Test1 = {}
Suite.Test2 = {}
Suite.Test3 = {}
Suite.Test4 = {}
Suite.Test5 = {}
Suite.Test6 = {}

-- Aliases
local InvalidParamCase = Suite.Test1
local NoAuthorizedCase = Suite.Test2
local ServiceOfferCase = Suite.Test3
local ORCase = Suite.Test4
local OfferObserversCase = Suite.Test5
local RegistryObserversCase = Suite.Test6

-- Constantes -----------------------------------------------------------------
local testCompName = "Ping test's component"
local pingIdl = "interface Ping { boolean ping(); };"

local offerProps = { 
  {name="var1", value="value1"},
  {name="var2", value="value2"},
  {name="var3", value="value3"},
}

-- Funções auxiliares ---------------------------------------------------------
local function getPingImpl()
  local ping = {}
  function ping:ping()
    return true
  end
  return ping
end

local function createPingComponent(orb)
  orb:loadidl(pingIdl)
  local ping = getPingImpl()
  -- create service SCS component
  local component = ComponentContext(orb, {
  	name = testCompName,
  	major_version = 1,
  	minor_version = 0,
  	patch_version = 0,
  	platform_spec = "",
  })
  component:addFacet("ping", orb.types:lookup("Ping").repID, ping)
  return component
end

local function createOfferObserver()
  local obs = {}
  obs.wasChanged = 0
  obs.wasRemoved = 0
  function obs:propertiesChanged(desc)
    self.wasChanged = self.wasChanged + 1
  end
  function obs:removed(desc)
    self.wasRemoved = self.wasRemoved + 1
  end
  return obs
end

local function createOfferRegistryObserver()
  local obs = {}
  obs.registered = 0
  function obs:offerRegistered(desc)
    self.registered = self.registered + 1
  end
  return obs
end

---
-- Verifica se a lista de propriedades 'one' esta contida dentro de 'other'
---
local function isContained(one, other)
  for _,v1 in ipairs(one) do
    local found = false
    for _,v2 in ipairs(other) do
      if v1.name == v2.name and v1.value == v2.value then
        found = true
        break
      end
    end
    if not found then
      return false
    end
  end
  return true
end

-- Inicialização --------------------------------------------------------------
setuplog(log, sdklevel)
setuplog(oillog, oillevel)

-- Funções de configuração de testes padrão -----------------------------------
local function beforeTestCase(self)
  local orb = openbus.createORB{ localrefs="proxy" }
  local conn = openbus.connectByAddress(host, port, orb)
  conn:loginByPassword(entity, entity)
  self.conn = conn
  self.offers = conn.offers
  oil.newthread(conn.orb.run, conn.orb)
end

local function afterTestCase(self)
  self.conn.orb:shutdown()
  self.conn:logout()
  self.conn = nil
  self.offers = nil
end

local function afterEachTest(self)
  if self.serviceOffer ~= nil then 
    self.serviceOffer:remove()
    self.serviceOffer = nil
  end
end

-- Testes do OfferRegistry ----------------------------------------------

-- -- IDL operations
-- Interface OfferRegistry:
-- ServiceOffer registerService(in OfferedService service_ref,
--                              in ServicePropertySeq properties)
--  raises (InvalidService, InvalidProperties, UnauthorizedFacets,
--          ServiceFailure);
-- ServiceOfferDescSeq findServices(in ServicePropertySeq properties)
--  raises (ServiceFailure);
-- ServiceOfferDescSeq getServices() raises (ServiceFailure);

-- Interface ServiceOffer: 
-- readonly attribute OfferedService service_ref;
-- readonly attribute ServicePropertySeq properties;
-- ServiceOfferDesc describe();
-- void setProperties(in ServicePropertySeq properties)
--  raises (InvalidProperties, ServiceFailure);
-- void remove() raises (ServiceFailure);

-------------------------------------
-- Caso de teste "INVALID PARAMETERS"
-------------------------------------

InvalidParamCase.beforeTestCase = beforeTestCase

function InvalidParamCase.afterTestCase(self)
  afterEachTest(self)
  afterTestCase(self)
end

function InvalidParamCase.testRegisterInvalidComponent(self)
  local orb = self.conn.orb
  local context = createPingComponent(orb)
  local comp = context.IComponent
  orb:loadidl("interface Ping2 { boolean ping(); };")
  context:addFacet("ping2", orb.types:lookup("Ping2").repID, getPingImpl())
  local ok, err = pcall(self.offers.registerService, self.offers, context, {})
  Check.assertEquals(sysex.BAD_PARAM, err._repid)
end

function InvalidParamCase.testRegisterNilComponent(self)
  local ok, err = pcall(self.offers.registerService, self.offers, nil, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidService, err._repid)
end

function InvalidParamCase.testRegisterEmptyComponent(self)
  local ok, err = pcall(self.offers.registerService, self.offers, {}, {})
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_IMPLEMENT, err._repid)
end

function InvalidParamCase.testRegisterNilProperties(self)
  local orb = self.conn.orb
  local context = createPingComponent(orb)
  local comp = context.IComponent
  local ok, err = pcall(self.offers.registerService, self.offers, comp, nil)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, err._repid)
end

function InvalidParamCase.testRegisterInvalidProperties(self)
  local orb = self.conn.orb
  local context = createPingComponent(orb)
  local comp = context.IComponent
  local props = { {name="openbus.myname", value="ping"}, }
  local ok, err = pcall(self.offers.registerService, self.offers, comp, props)
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidProperties, err._repid)  
end

function InvalidParamCase.testRegisterUnauthorizedFacets(self)
  local orb = self.conn.orb
  local comp = createPingComponent(orb)
  orb:loadidl("interface Ping2 { boolean ping(); };")
  comp:addFacet("ping2", orb.types:lookup("Ping2").repID, getPingImpl())
  local ok, err = pcall(self.offers.registerService, self.offers, comp.IComponent, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.UnauthorizedFacets, err._repid)
end

function InvalidParamCase.testFindNilProps(self)
  local ok, err = pcall(self.offers.findServices, self.offers, nil)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, err._repid)
end

function InvalidParamCase.testFindEmptyProps(self)
  local ok, err = pcall(self.offers.findServices, self.offers, {})
  Check.assertTrue(ok)
  Check.assertEquals(0, #err)
end

function InvalidParamCase.testFindEmptyProps(self)
  local orb = self.conn.orb
  local context = createPingComponent(orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, {})
  local offs = self.offers:findServices({})
  Check.assertEquals(0, #offs)
  self.serviceOffer:remove()
  self.serviceOffer = nil
end

---------------------------------------
-- Caso de teste "NO AUTHORIZED ENTITY"
---------------------------------------

function NoAuthorizedCase.beforeTestCase(self)
  local orb = openbus.createORB{ localrefs="proxy" }
  local conn = openbus.connectByAddress(host, port, orb)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
  self.offers = conn.offers
  oil.newthread(conn.orb.run, conn.orb)
end

NoAuthorizedCase.afterTestCase = afterTestCase

function NoAuthorizedCase.testRegisterUnauthorizedEntity(self)
  local orb = self.conn.orb
  local context = createPingComponent(orb)
  local comp = context.IComponent
  local ok, err = pcall(self.offers.registerService, self.offers, comp, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.UnauthorizedFacets, err._repid)
end

--------------------------------
-- Caso de teste "SERVICE OFFER"
--------------------------------

function ServiceOfferCase.beforeTestCase(self)
  beforeTestCase(self)
  local orb = self.conn.orb
  local context = createPingComponent(orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
end

function ServiceOfferCase.afterTestCase(self)
  self.serviceOffer:remove()
  afterTestCase(self)
end

function ServiceOfferCase.afterEachTest(self)
  -- restaurando as propriedades 
  self.serviceOffer:setProperties(offerProps)
end

function ServiceOfferCase.testOfferDesc(self)
  local offerSeq = self.offers:findServices({
    { name="openbus.component.name", value=testCompName },
  })
  Check.assertEquals(1, #offerSeq)
  local desc = offerSeq[1]
  Check.assertNotNil(desc.service_ref)
  local pingFacet = desc.service_ref:getFacetByName("ping"):__narrow()
  Check.assertTrue(pingFacet:ping())
  Check.assertNotNil(desc.properties)
  Check.assertTrue(#desc.properties > #offerProps)
  Check.assertTrue(isContained(offerProps, desc.properties))
  Check.assertNotNil(desc.ref)
  local newDesc = desc.ref:describe()
  Check.assertNotNil(newDesc)
  Check.assertTrue(#desc.properties == #newDesc.properties)
  Check.assertTrue(isContained(desc.properties, newDesc.properties))
end

function ServiceOfferCase.testSetProperties(self)
  local offerSeq = self.offers:findServices({
    { name="openbus.component.name", value=testCompName },
  })
  Check.assertEquals(1, #offerSeq)
  local desc = offerSeq[1]
  local fstProps = desc.properties
  local fstSize = #fstProps
  -- lista com 1 propriedade ao inves de #offerProps (igual a 3)
  local newProps = { offerProps[1], }
  local sizeDiff = #offerProps - #newProps
  desc.ref:setProperties(newProps)
  local newDesc = desc.ref:describe()
  Check.assertTrue(isContained(newProps, newDesc.properties))
  local newSize = #newDesc.properties
  Check.assertEquals(fstSize, newSize + sizeDiff)
end

function ServiceOfferCase.testInvalidProperties(self)
  local invalidProps = {
    { name="openbus.reserved.name", value="should fail"},
  }
  local ok, err = pcall(self.serviceOffer.setProperties, self.serviceOffer, 
    invalidProps)
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidProperties, err._repid)
  Check.assertTrue(isContained(invalidProps, err.properties))
  Check.assertTrue(isContained(err.properties, invalidProps))
end

function ServiceOfferCase.testRemoveProperties(self)
  self.serviceOffer:setProperties({})
  local myProps = self.serviceOffer:_get_properties()
  Check.assertFalse(isContained(offerProps, myProps))
  for i, prop in ipairs(offerProps) do
    print(i,prop.name,prop.value)
    local services = self.offers:findServices({offerProps[i]})
    Check.assertEquals(0, #services)
  end
  local services = self.offers:findServices({
    { name="openbus.component.name", value=testCompName },
  })
  Check.assertEquals(1, #services)
  local desc = services[1]
  local pingFacet = desc.service_ref:getFacetByName("ping"):__narrow()
  Check.assertTrue(pingFacet:ping())
end


------------------------------------------
-- Caso de teste "PADRÃO" do OfferRegistry
------------------------------------------

ORCase.beforeTestCase = beforeTestCase
ORCase.afterTestCase = afterTestCase
ORCase.afterEachTest = afterEachTest

function ORCase.testRegisterRemove(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local pingFacet = tOffer:_get_service_ref():getFacetByName("ping"):__narrow()
  Check.assertTrue(pingFacet:ping())
  tOffer:remove()
  local services = self.offers:findServices(offerProps)
  Check.assertEquals(0, #services)
  self.serviceOffer = nil
end

function ORCase.testRegisterTwoOffers(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  local lastpos = #offerProps + 1
  offerProps[lastpos] = {name="specific", value="1st offer"}
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  offerProps[lastpos] = {name="specific", value="2nd offer"}
  local otherOffer = self.offers:registerService(comp, offerProps)
  
  local services = self.offers:findServices(offerProps)
  Check.assertEquals(1, #services)
  offerProps[lastpos] = nil
  services = self.offers:findServices(offerProps)
  Check.assertEquals(2, #services)
  otherOffer:remove()
  services = self.offers:findServices(offerProps)
  Check.assertEquals(1, #services)
  self.serviceOffer:remove()
  services = self.offers:findServices(offerProps)
  Check.assertEquals(0, #services)
  self.serviceOffer = nil
end

function ORCase.testRemoveTwice(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  tOffer:remove()
  self.serviceOffer = nil
  local ok, err = pcall(tOffer.remove, tOffer)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.OBJECT_NOT_EXIST, err._repid)
end

function ORCase.testFindBySingleProperty(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps) 
  for i, prop in ipairs(offerProps) do
    local services = self.offers:findServices({prop})
    Check.assertEquals(1, #services)
  end
end

function ORCase.testGetServices(self)
  local services = self.offers:getServices()
  local preSize = #services
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  services = self.offers:getServices()
  Check.assertEquals(preSize + 1, #services)
  self.serviceOffer:remove()
  self.serviceOffer = nil
  services = self.offers:getServices()
  Check.assertEquals(preSize, #services)
end

------------------------------------------
-- Caso de teste de Observação de Ofertas
------------------------------------------

OfferObserversCase.beforeTestCase = beforeTestCase
OfferObserversCase.afterTestCase = afterTestCase
OfferObserversCase.afterEachTest = afterEachTest

function OfferObserversCase.testCookiesGeneration(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local obs = createOfferObserver()
  local cookie1 = tOffer:subscribe(obs)
  Check.assertEquals(1, cookie1)
  local cookie2 = tOffer:subscribe(obs)
  Check.assertEquals(2, cookie2)
  local cookie3 = tOffer:subscribe(obs)
  Check.assertEquals(3, cookie3)
  local ok = tOffer:unsubscribe(cookie2)
  Check.assertTrue(ok)
  cookie2 = 0
  cookie2 = tOffer:subscribe(obs)
  Check.assertEquals(2, cookie2)
  ok = tOffer:unsubscribe(cookie1)
  Check.assertTrue(ok)
  ok = tOffer:unsubscribe(cookie2)
  Check.assertTrue(ok)
  ok = tOffer:unsubscribe(cookie3)
  Check.assertTrue(ok)
end

function OfferObserversCase.testNotification(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local obs = createOfferObserver()
  local cookie = tOffer:subscribe(obs)
  local newProps = { offerProps[1], }
  tOffer:setProperties(newProps)
  Check.assertEquals(1, obs.wasChanged)
  tOffer:remove()
  Check.assertEquals(1, obs.wasRemoved)
  self.serviceOffer = nil
end

function OfferObserversCase.testMultipleNotification(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local obs = createOfferObserver()
  local cookie1 = tOffer:subscribe(obs)
  local cookie2 = tOffer:subscribe(obs)
  local cookie3 = tOffer:subscribe(obs)
  local ok = tOffer:unsubscribe(cookie2)
  tOffer:remove()
  Check.assertEquals(2, obs.wasRemoved)
  self.serviceOffer = nil
end

function OfferObserversCase.testSubscribe(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local obs = createOfferObserver()
  local cookie = tOffer:subscribe(obs)
  local newProps = { offerProps[1], }
  tOffer:setProperties(newProps)
  Check.assertEquals(1, obs.wasChanged)
  local ok = tOffer:unsubscribe(cookie)
  Check.assertTrue(ok)
  tOffer:remove()
  Check.assertEquals(0, obs.wasRemoved)
  self.serviceOffer = nil
end

function OfferObserversCase.testFailSubscription(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local ok, err = pcall(tOffer.subscribe, tOffer, nil)
  Check.assertTrue(not ok)
  -- existe uma verificacao de nil para lançar BAD_PARAM. Parece ser desnecessário
  Check.assertEquals(sysex.MARSHAL, err._repid)
end

function OfferObserversCase.testSubscribeInvalid(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local cookie = tOffer:subscribe({})
  local newProps = { offerProps[1], }
  local ok, err = pcall(tOffer.setProperties, tOffer, newProps)
  -- Erro é apenas loggado no lado do bus
  Check.assertTrue(ok)
  ok, err = pcall(tOffer.remove, tOffer)
  -- Erro é apenas loggado no lado do bus
  Check.assertTrue(ok)
  self.serviceOffer = nil
end

function OfferObserversCase.testFailUnsubscription(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local invalidCookie = -1
  local ok = tOffer:unsubscribe(invalidCookie)
  Check.assertTrue(not ok)
end

-----------------------------------------------------
-- Caso de teste de Observação de Registro de Ofertas
-----------------------------------------------------

RegistryObserversCase.beforeTestCase = beforeTestCase
RegistryObserversCase.afterTestCase = afterTestCase

function RegistryObserversCase.afterEachTest(self)
  afterEachTest(self)
  -- se ocorreu algum erro, garantindo que os observadores foram removidos.
  for i = 1, 3 do
    self.offers:unsubscribeObserver(i)
  end
end

function RegistryObserversCase.testCookiesGeneration(self)
  local obs = createOfferRegistryObserver()
  local cookie1 = self.offers:subscribeObserver(obs, offerProps)
  Check.assertEquals(1, cookie1)
  local cookie2 = self.offers:subscribeObserver(obs, offerProps)
  Check.assertEquals(2, cookie2)
  local cookie3 = self.offers:subscribeObserver(obs, offerProps)
  Check.assertEquals(3, cookie3)
  local ok = self.offers:unsubscribeObserver(cookie2)
  Check.assertTrue(ok)
  cookie2 = 0
  cookie2 = self.offers:subscribeObserver(obs, offerProps)
  Check.assertEquals(2, cookie2)
  ok = self.offers:unsubscribeObserver(cookie1)
  Check.assertTrue(ok)
  ok = self.offers:unsubscribeObserver(cookie2)
  Check.assertTrue(ok)
  ok = self.offers:unsubscribeObserver(cookie3)
  Check.assertTrue(ok)
end

function RegistryObserversCase.testNotification(self)
  local obs = createOfferRegistryObserver()
  local cookie = self.offers:subscribeObserver(obs, offerProps)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  Check.assertEquals(1, obs.registered)
  local ok = self.offers:unsubscribeObserver(cookie)
  Check.assertTrue(ok)  
end

function RegistryObserversCase.testMultipleNotification(self)
  local obs = createOfferRegistryObserver()
  local cookie1 = self.offers:subscribeObserver(obs, offerProps)
  local cookie2 = self.offers:subscribeObserver(obs, offerProps)
  local cookie3 = self.offers:subscribeObserver(obs, offerProps)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  Check.assertEquals(3, obs.registered)
  self.serviceOffer:remove()
  local ok = self.offers:unsubscribeObserver(cookie2)
  Check.assertTrue(ok)
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  Check.assertEquals(5, obs.registered)
  ok = self.offers:unsubscribeObserver(cookie1)
  ok = self.offers:unsubscribeObserver(cookie3)
end

function RegistryObserversCase.testSubscribe(self)
  local newProps = { offerProps[1], }
  local obs = createOfferRegistryObserver()
  local cookie = self.offers:subscribeObserver(obs, newProps)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  Check.assertEquals(1, obs.registered)
  tOffer:setProperties(newProps)
  Check.assertEquals(2, obs.registered)
  newProps = { offerProps[2], }
  tOffer:setProperties(newProps)
  Check.assertEquals(2, obs.registered)
  local ok = self.offers:unsubscribeObserver(cookie)
  Check.assertTrue(ok)  
  tOffer:setProperties(offerProps)
  Check.assertEquals(2, obs.registered)
end

function RegistryObserversCase.testFailSubscription(self)
  local ok, err = pcall(self.offers.subscribeObserver, self.offers, nil, newProps)
  Check.assertTrue(not ok)
  -- existe uma verificacao de nil para lançar BAD_PARAM. Parece ser desnecessário
  Check.assertEquals(sysex.MARSHAL, err._repid)
  local obs = createOfferRegistryObserver()
  ok, err = pcall(self.offers.subscribeObserver, self.offers, obs, nil)
  Check.assertTrue(not ok)
  -- existe uma verificacao de nil para lançar BAD_PARAM. Parece ser desnecessário
  Check.assertEquals(sysex.MARSHAL, err._repid)
end

function RegistryObserversCase.testSubscribeInvalid(self)
  local cookie = self.offers:subscribeObserver({}, offerProps)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  -- Erro é apenas loggado no lado do bus
  self.offers:unsubscribeObserver(cookie)
end

function RegistryObserversCase.testFailUnsubscription(self)
  local cookie = -1
  self.offers:unsubscribeObserver(cookie)
  Check.assertTrue(not ok)
end
