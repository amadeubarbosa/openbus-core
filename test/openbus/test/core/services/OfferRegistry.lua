local _G = require "_G"
local pcall = _G.pcall
local ipairs = _G.ipairs

local oil = require "oil"
local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local openbus = require "openbus"
local idl = require "openbus.core.idl"
local offertypes = idl.types.services.offer_registry
local throwsysex = require "openbus.util.sysex"

local ComponentContext = require "scs.core.ComponentContext"

local Check = require "latt.Check"

-- Configurações --------------------------------------------------------------
bushost, busport = ...
require "openbus.test.configs"
local host = bushost
local port = busport
local admin = admin
local adminPassword = admpsw
local dUser = user
local dPassword = password
local entity = system

-- Inicialização --------------------------------------------------------------
local orb = openbus.initORB{ localrefs="proxy" }
local OpenBusContext = orb.OpenBusContext
local connprops = { accesskey = openbus.newKey() }

-- Casos de Teste -------------------------------------------------------------
Suite = {}
Suite.Test1 = {}
Suite.Test2 = {}
Suite.Test3 = {}
Suite.Test4 = {}
Suite.Test5 = {}
Suite.Test6 = {}
Suite.Test7 = {}

-- Aliases
local InvalidParamCase = Suite.Test1
local NoAuthorizedCase = Suite.Test2
local AuthorizationInUseCase = Suite.Test3
local ServiceOfferCase = Suite.Test4
local ORCase = Suite.Test5
local OfferObserversCase = Suite.Test6
local RegistryObserversCase = Suite.Test7

-- Constantes -----------------------------------------------------------------
local testCompName = "Ping test's component"
local pingIdl = "interface Ping { boolean ping(); };"

local offerProps = { 
  {name="var1", value="value1"},
  {name="var2", value="value2"},
  {name="var3", value="value3"},
}

local ComponentId = {
  name = "name",
  major_version = 1,
  minor_version = 0,
  patch_version = 0,
  platform_spec = "none",
}

local ReservedProperties = {
  ["openbus.offer.id"] = true,
  ["openbus.offer.login"] = true,
  ["openbus.offer.entity"] = true,
  ["openbus.offer.timestamp"] = true,
  ["openbus.offer.year"] = true,
  ["openbus.offer.month"] = true,
  ["openbus.offer.day"] = true,
  ["openbus.offer.hour"] = true,
  ["openbus.offer.minute"] = true,
  ["openbus.offer.second"] = true,
  ["openbus.component.name"] = true,
  ["openbus.component.version.major"] = true,
  ["openbus.component.version.minor"] = true,
  ["openbus.component.version.patch"] = true,
}

-- Funções auxiliares ---------------------------------------------------------
local function assertCondOrTimeout(condition,timeout)
  if timeout == nil then timeout = 2 end
  local deadline = oil.time()+timeout
  while not condition() do
    if oil.time() > deadline then
      error("Assert failed after "..tostring(timeout).." seconds.",2)
    end
    oil.sleep(.1)
  end
end

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

-- Funções de configuração de testes padrão -----------------------------------
local function beforeTestCase(self)
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(self.user or entity, self.password or entity)
  self.conn = conn
  self.offers = OpenBusContext:getOfferRegistry()
  oil.newthread(conn.orb.run, conn.orb)
end

local function afterTestCase(self)
  self.conn.orb:shutdown()
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
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
-- ServiceOfferDescSeq getAllServices() raises (ServiceFailure);

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
  Check.assertEquals(offertypes.InvalidService, err._repid)
end

function InvalidParamCase.testRegisterBadGetComponentId(self)
  local comp = {}
  function comp:getComponentId()
    throwsysex.NO_PERMISSION{completed="COMPLETED_NO",minor=1234}
  end
  local ok, err = pcall(self.offers.registerService, self.offers, comp, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidService, err._repid)
end

function InvalidParamCase.testRegisterBadGetMetaInterface(self)
  local comp = {}
  function comp:getComponentId()
    return ComponentId
  end
  function comp:getFacetByName()
    throwsysex.NO_PERMISSION{completed="COMPLETED_NO",minor=1234}
  end
  local ok, err = pcall(self.offers.registerService, self.offers, comp, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidService, err._repid)
end

function InvalidParamCase.testRegisterNoMetaInterfaceFacet(self)
  local comp = {}
  function comp:getComponentId()
    return ComponentId
  end
  function comp:getFacetByName()
    return nil
  end
  local ok, err = pcall(self.offers.registerService, self.offers, comp, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidService, err._repid)
end

function InvalidParamCase.testRegisterBadGetFacets(self)
  local comp = {}
  function comp:getComponentId()
    return ComponentId
  end
  local orb = self.conn.orb
  function comp:getFacetByName(name)
    if name == "IMetaInterface" then
      local meta = {__type="IDL:scs/core/IMetaInterface:1.0"}
      function meta:getFacets()
        throwsysex.NO_PERMISSION{completed="COMPLETED_NO",minor=1234}
      end
      return meta
    end
  end
  local ok, err = pcall(self.offers.registerService, self.offers, comp, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidService, err._repid)
end

function InvalidParamCase.testRegisterEmptyFacets(self)
  local comp = {}
  function comp:getComponentId()
    return ComponentId
  end
  local orb = self.conn.orb
  function comp:getFacetByName(name)
    if name == "IMetaInterface" then
      local meta = {__type="IDL:scs/core/IMetaInterface:1.0"}
      function meta:getFacets()
        return {}
      end
      return meta
    end
  end
  self.offers:registerService(comp, {})
end

function InvalidParamCase.testRegisterNilComponent(self)
  local ok, err = pcall(self.offers.registerService, self.offers, nil, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidService, err._repid)
end

function InvalidParamCase.testRegisterEmptyComponent(self)
  local ok, err = pcall(self.offers.registerService, self.offers, {}, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidService, err._repid)
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
  for reservedname in pairs(ReservedProperties) do
    local props = { {name=reservedname, value="blah"}, }
    local ok, err = pcall(self.offers.registerService, self.offers, comp, props)
    Check.assertTrue(not ok)
    Check.assertEquals(offertypes.InvalidProperties, err._repid)  
    Check.assertTrue(isContained(props, err.properties))
    Check.assertTrue(isContained(err.properties, props))
  end
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

NoAuthorizedCase.user = dUser
NoAuthorizedCase.password = dPassword
NoAuthorizedCase.beforeTestCase = beforeTestCase
NoAuthorizedCase.afterTestCase = afterTestCase

function NoAuthorizedCase.testRegisterUnauthorizedEntity(self)
  local orb = self.conn.orb
  local context = createPingComponent(orb)
  local comp = context.IComponent
  local ok, err = pcall(self.offers.registerService, self.offers, comp, {})
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.UnauthorizedFacets, err._repid)
end

---------------------------------------
-- Caso de teste "AuthorizationInUse"
---------------------------------------

function AuthorizationInUseCase.beforeTestCase(self)
  beforeTestCase(self)
  local orb = self.conn.orb
  local context = createPingComponent(orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
end

function AuthorizationInUseCase.afterTestCase(self)
  local aconn = self.aconn
  if aconn ~= nil then
    aconn:logout()
    OpenBusContext:setCurrentConnection(nil)
    self.aconn = nil
  end
  self.serviceOffer:remove()
  afterTestCase(self)
end

function AuthorizationInUseCase.testAuhtorizationInUse(self)
  self.aconn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setCurrentConnection(self.aconn)
  self.aconn:loginByPassword(admin, adminPassword)
  local entities = OpenBusContext:getEntityRegistry()
  local theEntity = entities:getEntity(entity)
  local ok, err = pcall(theEntity.revokeInterface, theEntity, "IDL:Ping:1.0")
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.AuthorizationInUse, err._repid)
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
  for reservedname in pairs(ReservedProperties) do
    local invalidProps = {{ name=reservedname, value="blah"}}
    local ok, err = pcall(self.serviceOffer.setProperties, self.serviceOffer, 
      invalidProps)
    Check.assertTrue(not ok)
    Check.assertEquals(offertypes.InvalidProperties, err._repid)
    Check.assertTrue(isContained(invalidProps, err.properties))
    Check.assertTrue(isContained(err.properties, invalidProps))
  end
end

function ServiceOfferCase.testRemoveProperties(self)
  self.serviceOffer:setProperties({})
  local myProps = self.serviceOffer:_get_properties()
  Check.assertFalse(isContained(offerProps, myProps))
  for i, prop in ipairs(offerProps) do
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

function ORCase.testGetAllServices(self)
  local services = self.offers:getAllServices()
  local preSize = #services
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  services = self.offers:getAllServices()
  Check.assertEquals(preSize + 1, #services)
  self.serviceOffer:remove()
  self.serviceOffer = nil
  services = self.offers:getAllServices()
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
  local subscript1 = tOffer:subscribeObserver(obs)
  local subscript2 = tOffer:subscribeObserver(obs)
  local subscript3 = tOffer:subscribeObserver(obs)
  subscript2:remove()
  subscript1:remove()
  subscript3:remove()
  local ok, err = pcall(subscript3.remove, subscript3)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.OBJECT_NOT_EXIST, err._repid)
end

function OfferObserversCase.testNotification(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local obs = createOfferObserver()
  tOffer:subscribeObserver(obs)
  local newProps = { offerProps[1], }
  tOffer:setProperties(newProps)
  assertCondOrTimeout(function() return obs.wasChanged == 1 end)
  tOffer:remove()
  assertCondOrTimeout(function() return obs.wasRemoved == 1 end)
  self.serviceOffer = nil
end

function OfferObserversCase.testMultipleNotification(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local obs = createOfferObserver()
  local subscript1 = tOffer:subscribeObserver(obs)
  local subscript2 = tOffer:subscribeObserver(obs)
  local subscript3 = tOffer:subscribeObserver(obs)
  subscript2:remove()
  tOffer:remove()
  self.serviceOffer = nil
  assertCondOrTimeout(function() return obs.wasRemoved == 2 end)
end

function OfferObserversCase.testSubscribe(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local obs = createOfferObserver()
  local subscript = tOffer:subscribeObserver(obs)
  local newProps = { offerProps[1], }
  tOffer:setProperties(newProps)
  assertCondOrTimeout(function() return obs.wasChanged == 1 end)
  subscript:remove()
  tOffer:remove()
  assertCondOrTimeout(function() return obs.wasRemoved == 0 end)
  self.serviceOffer = nil
end

function OfferObserversCase.testFailSubscription(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  local ok, err = pcall(tOffer.subscribeObserver, tOffer, nil)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.BAD_PARAM, err._repid)
end

function OfferObserversCase.testSubscribeInvalid(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  tOffer:subscribeObserver({})
  local newProps = { offerProps[1], }
  local ok, err = pcall(tOffer.setProperties, tOffer, newProps)
  -- Erro é apenas loggado no lado do bus
  Check.assertTrue(ok)
  ok, err = pcall(tOffer.remove, tOffer)
  -- Erro é apenas loggado no lado do bus
  Check.assertTrue(ok)
  self.serviceOffer = nil
end

-----------------------------------------------------
-- Caso de teste de Observação de Registro de Ofertas
-----------------------------------------------------

RegistryObserversCase.beforeTestCase = beforeTestCase
RegistryObserversCase.afterTestCase = afterTestCase
RegistryObserversCase.afterEachTest = afterEachTest

function RegistryObserversCase.testCookiesGeneration(self)
  local obs = createOfferRegistryObserver()
  local subscript1 = self.offers:subscribeObserver(obs, offerProps)
  local subscript2 = self.offers:subscribeObserver(obs, offerProps)
  local subscript3 = self.offers:subscribeObserver(obs, offerProps)
  subscript2:remove()
  subscript2 = self.offers:subscribeObserver(obs, offerProps)
  subscript1:remove()
  subscript2:remove()
  subscript3:remove()
end

function RegistryObserversCase.testNotification(self)
  local obs = createOfferRegistryObserver()
  local subscript = self.offers:subscribeObserver(obs, offerProps)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  assertCondOrTimeout(function() return obs.registered == 1 end)
  subscript:remove()
end

function RegistryObserversCase.testMultipleNotification(self)
  local obs = createOfferRegistryObserver()
  local subscript1 = self.offers:subscribeObserver(obs, offerProps)
  local subscript2 = self.offers:subscribeObserver(obs, offerProps)
  local subscript3 = self.offers:subscribeObserver(obs, offerProps)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  assertCondOrTimeout(function() return obs.registered == 3 end)
  self.serviceOffer:remove()
  subscript2:remove()
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  assertCondOrTimeout(function() return obs.registered == 5 end)
  subscript1:remove()
  subscript3:remove()
end

function RegistryObserversCase.testSubscribe(self)
  local newProps = { offerProps[1], }
  local obs = createOfferRegistryObserver()
  local subscript = self.offers:subscribeObserver(obs, newProps)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  assertCondOrTimeout(function() return obs.registered == 1 end)
  tOffer:setProperties(newProps)
  assertCondOrTimeout(function() return obs.registered == 2 end)
  newProps = { offerProps[2], }
  tOffer:setProperties(newProps)
  assertCondOrTimeout(function() return obs.registered == 2 end)
  subscript:remove()
  tOffer:setProperties(offerProps)
  assertCondOrTimeout(function() return obs.registered == 2 end)
end

function RegistryObserversCase.testFailSubscription(self)
  local ok, err = pcall(self.offers.subscribeObserver, self.offers, nil, offerProps)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.BAD_PARAM, err._repid)
  local obs = createOfferRegistryObserver()
  ok, err = pcall(self.offers.subscribeObserver, self.offers, obs, nil)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, err._repid)
end

function RegistryObserversCase.testSubscribeInvalid(self)
  local subscript = self.offers:subscribeObserver({}, offerProps)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  -- Erro é apenas loggado no lado do bus
  subscript:remove()
end
