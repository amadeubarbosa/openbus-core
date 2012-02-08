local _G = require "_G"
local io = _G.io
local pcall = _G.pcall
local pcall = _G.pcall
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

-- Aliases
local InvalidParamCase = Suite.Test1
local NoAuthorizedCase = Suite.Test2
local ServiceOfferCase = Suite.Test3
local ORCase = Suite.Test4

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

function InvalidParamCase.beforeTestCase(self)
  local conn = openbus.connectByAddress(host, port)
  conn:loginByPassword(entity, entity)
  self.conn = conn
  self.offers = conn.offers
  oil.newthread(conn.orb.run, conn.orb)
end

function InvalidParamCase.afterTestCase(self)
  if self.serviceOffer ~= nil then 
    self.serviceOffer:remove()
    self.serviceOffer = nil
  end
  self.conn.orb:shutdown()
  self.conn:logout()
  self.conn = nil
  self.offers = nil
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
  local conn = openbus.connectByAddress(host, port)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
  self.offers = conn.offers
  oil.newthread(conn.orb.run, conn.orb)
end

function NoAuthorizedCase.afterTestCase(self)
  self.conn.orb:shutdown()
  self.conn:logout()
  self.conn = nil
  self.offers = nil
end

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
  local conn = openbus.connectByAddress(host, port)
  conn:loginByPassword(entity, entity)
  self.conn = conn
  self.offers = conn.offers
  oil.newthread(conn.orb.run, conn.orb)
  local orb = conn.orb
  local context = createPingComponent(orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
end

function ServiceOfferCase.afterTestCase(self)
  self.serviceOffer:remove()
  self.conn.orb:shutdown()
  self.conn:logout()
  self.conn = nil
  self.offers = nil
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
    { name="openbus.reserved.name", value="should failed"},
  }
  local ok, err = pcall(self.serviceOffer.setProperties, self.serviceOffer, 
    invalidProps)
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidProperties, err._repid)
  Check.assertTrue(isContained(invalidProps, err.properties))
  Check.assertTrue(isContained(err.properties, invalidProps))
end

function ServiceOfferCase.testInvalidPropertiesType(self)
  local invalidProps = { name="n1", name2="n2", value="v1", value2="v2" }
  local ok, err = pcall(self.serviceOffer.setProperties, self.serviceOffer, 
    invalidProps)
  Check.assertTrue(not ok)
  Check.assertEquals(offertypes.InvalidProperties, err._repid)
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

function ORCase.beforeTestCase(self)
  local conn = openbus.connectByAddress(host, port)
  conn:loginByPassword(entity, entity)
  self.conn = conn
  self.offers = conn.offers
  oil.newthread(conn.orb.run, conn.orb)
end

function ORCase.afterTestCase(self)
  self.conn.orb:shutdown()
  self.conn:logout()
  self.conn = nil
  self.offers = nil
end

function ORCase.afterEachTest(self)
  if self.serviceOffer ~= nil then 
    self.serviceOffer:remove()
    self.serviceOffer = nil
  end
end

function ORCase.testRegisterRemove(self)
  local context = createPingComponent(self.conn.orb)
  local comp = context.IComponent
  self.serviceOffer = self.offers:registerService(comp, offerProps)
  local tOffer = self.serviceOffer
  Check.assertNotNil(tOffer.service_ref)
  local pingFacet = tOffer:_get_service_ref():getFacetByName("ping"):__narrow()
  Check.assertTrue(pingFacet:ping())
  tOffer:remove()
  local services = self.offers:findServices(offerProps)
  Check.assertEquals(0, #services)
  self.serviceOffer = nil
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
