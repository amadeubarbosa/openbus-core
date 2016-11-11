local table = require "loop.table"
local cached = require "loop.cached"
local checks = require "loop.test.checks"
local Fixture = require "loop.test.Fixture"
local Suite = require "loop.test.Suite"

local openbus = require "openbus"
local idl = require "openbus.core.idl"
local UnauthorizedOperation = idl.types.services.UnauthorizedOperation
local offtps = idl.types.services.offer_registry
local ServiceOffer = offtps.ServiceOffer
local InvalidService = offtps.InvalidService
local InvalidProperties = offtps.InvalidProperties
local UnauthorizedFacets = offtps.UnauthorizedFacets

local except = require "openbus.util.except"
local sysex = except.repid
local minor = except.minor

local ComponentContext = require "scs.core.ComponentContext"

-- Configurações --------------------------------------------------------------

require "openbus.test.core.services.utils"

-- Funções auxiliares ---------------------------------------------------------

local GrantedFacetName = "ping"
local GrantedInterface = "IDL:Ping:1.0"
local SomeFacetName = "unauthorized"
local SomeInterface = "IDL:Unauthorized:1.0"
local SomeEntityName = "Test Entity Description (should not remain after the tests)"

local SomeOfferProps = { 
  {name="prop1", value="value1"},
  {name="prop2", value="value2"},
  {name="prop3", value="value3"},
}

local SomeComponentId = {
  name = "Ping Component",
  major_version = 1,
  minor_version = 2,
  patch_version = 3,
  platform_spec = "none",
}

local ReservedProperties = {
  { name = "openbus.offer.id", value = "fake unique identifier" },
  { name = "openbus.offer.login", value = "fake login identifier" },
  { name = "openbus.offer.entity", value = SomeEntityName, },
  { name = "openbus.offer.timestamp", value = tostring(os.time()) },
  { name = "openbus.offer.year", value = os.date("%d") },
  { name = "openbus.offer.month", value = os.date("%m") },
  { name = "openbus.offer.day", value = os.date("%Y") },
  { name = "openbus.offer.hour", value = os.date("%H") },
  { name = "openbus.offer.minute", value = os.date("%M") },
  { name = "openbus.offer.second", value = os.date("%S") },
  { name = "openbus.component.name", value = SomeComponentId.name },
  { name = "openbus.component.version.major", value = tostring(SomeComponentId.major_version) },
  { name = "openbus.component.version.minor", value = tostring(SomeComponentId.minor_version) },
  { name = "openbus.component.version.patch", value = tostring(SomeComponentId.patch_version) },
  { name = "openbus.component.platform", value = tostring(SomeComponentId.platform_spec) },
  { name = "openbus.component.facet", value = SomeFacetName },
  { name = "openbus.component.interface", value = SomeInterface },
}

local BadOpExMsg = "CORBA System Exception "..sysex.BAD_CONTEXT..": minor code: 1234, completed: COMPLETED_YES"

local function badOpImpl()
  error{
    _repid = sysex.BAD_CONTEXT,
    completed = "COMPLETED_YES",
    minor = 1234,
  }
end

local function isInvalidServiceEx(...)
  local messages = {...}
  return function (value)
    checks.assert(value._repid, checks.equal(InvalidService))
    for _, msg in ipairs(messages) do
      checks.assert(value.message, checks.match(msg, nil, 1, true))
    end
    return true
  end
end

local function numberAsStrInRange(lower, upper)
  return function (value)
    local number = tonumber(value)
    if number ~= nil then
      if lower ~= nil then checks.assert(number, checks.greater(lower-1)) end
      if upper ~= nil then checks.assert(number, checks.less(upper+1)) end
      return true
    end
    return false, checks.viewer:tostring(value).." is not a number"
  end
end

local function isPropsList(comp, login, props)
  local facet = comp.IComponent:getFacetByName(GrantedFacetName)
  return function (list)
    local day = tonumber(os.date("%d"))
    local month = tonumber(os.date("%m"))
    local year = tonumber(os.date("%Y"))
    local hour = tonumber(os.date("%H"))
    local expected = {
      ["openbus.offer.id"] = checks.type("string"),
      ["openbus.offer.login"] = checks.equal(login.id),
      ["openbus.offer.entity"] = checks.equal(login.entity),
      ["openbus.offer.timestamp"] = numberAsStrInRange(),
      ["openbus.offer.year"] = numberAsStrInRange(year-1, year+1),
      ["openbus.offer.month"] = numberAsStrInRange(month-1, month+1),
      ["openbus.offer.day"] = numberAsStrInRange(day-1, day+1),
      ["openbus.offer.hour"] = numberAsStrInRange(hour-1, hour+1),
      ["openbus.offer.minute"] = numberAsStrInRange(0, 59),
      ["openbus.offer.second"] = numberAsStrInRange(0, 59),
      ["openbus.component.name"] = checks.equal(SomeComponentId.name),
      ["openbus.component.version.major"] = checks.equal(tostring(SomeComponentId.major_version)),
      ["openbus.component.version.minor"] = checks.equal(tostring(SomeComponentId.minor_version)),
      ["openbus.component.version.patch"] = checks.equal(tostring(SomeComponentId.patch_version)),
      ["openbus.component.platform"] = checks.equal(tostring(SomeComponentId.platform_spec)),
      ["openbus.component.facet"] = {
        ["IComponent"] = true,
        ["IMetaInterface"] = true,
        ["IReceptacles"] = true,
        [GrantedFacetName] = facet and true,
      },
      ["openbus.component.interface"] = {
        ["IDL:scs/core/IComponent:1.0"] = true,
        ["IDL:scs/core/IMetaInterface:1.0"] = true,
        ["IDL:scs/core/IReceptacles:1.0"] = true,
        [GrantedInterface] = facet and true,
      },
    }
    for _, prop in ipairs(props) do
      expected[prop.name] = checks.equal(prop.value)
    end
    for index, prop in ipairs(list) do
      local checker = expected[prop.name]
      if type(checker) == "table" then
        if checker[prop.value] == nil then
          return false, "unexpected value for service offer property "..checks.viewer:tostring(prop)
        end
        checker[prop.value] = nil
        if next(checker) == nil then
          expected[prop.name] = nil
        end
      elseif checker == nil then
        return false, "unexpected service offer property "..checks.viewer:tostring(prop)
      else
        checks.assert(prop.value, checker)
        expected[prop.name] = nil
      end
    end
    local missing, checker = next(expected)
    if missing ~= nil then
      if type(checker) == "table" then
        return false, "missing service offer property "..checks.viewer:tostring{name=missing,value=next(checker)}
      end
      return false, "missing service offer property "..checks.viewer:tostring(missing)
    end
    return true
  end
end

local function isServiceOffer(comp, ...)
  local checkprops = ...
  if type(checkprops) ~= "function" then
    checkprops = isPropsList(comp, ...)
  end
  return function (offer)
    checks.assert(offer:_get_service_ref(), checks.equal(comp.IComponent.__servant))
    local props = offer:_get_properties()
    checks.assert(props, checkprops)
    local desc = offer:describe()
    props = desc.properties
    checks.assert(props, checkprops)
    checks.assert(desc.service_ref, checks.equal(comp.IComponent.__servant))
    checks.assert(desc.ref:_is_a(ServiceOffer), checks.equal(true))
    return true
  end
end

local function isServiceOfferDesc(comp, login, props, removed)
  local checkprops = isPropsList(comp, login, props)
  local checkoffer = isServiceOffer(comp, checkprops)
  return function (desc)
    checks.assert(desc.service_ref, checks.equal(comp.IComponent.__servant))
    checks.assert(desc.properties, checkprops)
    if removed then
      checks.assert(desc.ref, checks.type("table"))
      checks.assert(desc.ref.__reference.type_id, checks.equal(ServiceOffer))
    else
      checks.assert(desc.ref, checkoffer)
    end
    return true
  end
end

local function isOfferSubscription(login, observer, comp, ...)
  local checkoffer = isServiceOffer(comp, ...)
  return function (subs)
    checks.assert(subs:_get_owner(), checks.like(login))
    checks.assert(subs:_get_observer(), checks.equal(observer))
    checks.assert(subs:_get_offer(), checkoffer)
    local desc = subs:describe()
    checks.assert(desc.observer, checks.equal(observer))
    checks.assert(desc.offer, checkoffer)
    return true
  end
end

local function isOfferRegSubscription(login, observer, properties)
  local checkprops = checks.like(properties)
  return function (subs)
    checks.assert(subs:_get_owner(), checks.like(login))
    checks.assert(subs:_get_observer(), checks.equal(observer))
    checks.assert(subs:_get_properties(), checkprops)
    local desc = subs:describe()
    checks.assert(desc.observer, checks.equal(observer))
    checks.assert(desc.properties, checkprops)
    return true
  end
end

local function getProperty(list, name)
  for _, prop in ipairs(list) do
    if prop.name == name then
      return prop.value
    end
  end
end


local OffersFixture = cached.class({}, IdentityFixture)

function OffersFixture:setup(openbus)
  local emptycomp = self.emptycomp
  if emptycomp == nil then
    emptycomp = ComponentContext(openbus.orb, SomeComponentId)
    self.emptycomp = emptycomp
  end
  local component = self.component
  if component == nil then
    component = ComponentContext(openbus.orb, SomeComponentId)
    component:addFacet(GrantedFacetName, GrantedInterface, {
      ping = function ()
        component.count = component.count+1
        return true
      end,
    })
    self.component = component
  end
  component.count = 0
  IdentityFixture.setup(self, openbus)
  local offers = self.offers
  if offers == nil then
    offers = openbus.context:getOfferRegistry()
    self.offers = offers
  end
  local registered = self.registered
  if registered ~= nil then
    local context = openbus.context
    if self.identity ~= "system" then
      local system = self:newConn("system")
      context:setCurrentConnection(system)
      self.system = system
    end
    self.offer = offers:registerService(component.IComponent, SomeOfferProps)
    context:setCurrentConnection(nil)
  end
end

-- Testes do OfferRegistry ----------------------------------------------

return OpenBusFixture{
  idlloaders = { function (orb) orb:loadidl("interface Ping { boolean ping(); };") end },
  Suite{
    AsUser = OffersFixture{
      identity = "user",
      tests = makeSimpleTests{
        offers = {
          registerService = {
            Null = {
              params = { nil, SomeOfferProps },
              except = isInvalidServiceEx("null reference"),
            },
            Inaccessible = {
              params = {
                function (fixture, openbus)
                  return openbus.orb:newproxy("corbaloc::inaccessible:2809/Inexistent", nil, "::scs::core::IComponent")
                end,
                SomeOfferProps,
              },
              except = isInvalidServiceEx("unable to obtain component id (error=unable to connect "),
            },
            Inexistent = {
              params = {
                function (fixture, openbus)
                  -- TODO:[maia] OiL should provide means to create references
                  --             for inexistent objects, just like
                  --             'objectid_to_refence' of CORBA.
                  local assert = require("oil.assert").results
                  local orb = openbus.orb
                  local servants = orb.ServantManager
                  local address = assert(servants.listener:getaddress())
                  local iface = assert(servants.types:resolve("::scs::core::IComponent"))
                  local objref = assert(servants.referrer:newreference({__objkey="inexistent",__type=iface}, address))
                  return orb:newproxy({__reference = objref}, nil, iface)
                end,
                SomeOfferProps,
              },
              except = isInvalidServiceEx("unable to obtain component id (error=CORBA System Exception IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0: minor code: 0, completed: COMPLETED_NO"),
            },
            BadGetComponentId = {
              params = {
                {
                  getComponentId = badOpImpl,
                },
                SomeOfferProps,
              },
              except = isInvalidServiceEx("unable to obtain component id (error="..BadOpExMsg),
            },
            BadGetFacetByName = {
              params = {
                {
                  getComponentId = function() return SomeComponentId end,
                  getFacetByName = badOpImpl,
                },
                SomeOfferProps
              },
              except = isInvalidServiceEx("unable to obtain standard facet", 'name="IMetaInterface"', "error="..BadOpExMsg),
            },
            NoMetaInterfaceFacet = {
              params = {
                {
                  getComponentId = function() return SomeComponentId end,
                  getFacetByName = function() end,
                },
                SomeOfferProps,
              },
              except = isInvalidServiceEx('missing standard facet (name="IMetaInterface")'),
            },
            BadMetaInterfaceFacet = {
              params = {
                {
                  getComponentId = function() return SomeComponentId end,
                  getFacetByName = function(self, name)
                    if name == "IMetaInterface" then
                      return {
                        __type = "::scs::core::IMetaInterface",
                        getFacets = badOpImpl,
                      }
                    end
                  end,
                },
                SomeOfferProps,
              },
              except = isInvalidServiceEx("unable to obtain service facets (error="..BadOpExMsg),
            },
            LogoutDuringRegister = {
              params = {
                function (fixture, openbus)
                  return {
                    getComponentId = function()
                      return SomeComponentId
                    end,
                    getFacetByName = function(self, name)
                      if name == "IMetaInterface" then
                        return {
                          __type = "::scs::core::IMetaInterface",
                          getFacets = function ()
                            openbus.context:getCurrentConnection():logout()
                            return {}
                          end,
                        }
                      end
                    end,
                  }
                end,
                SomeOfferProps,
              },
              except = checks.like{
                _repid = NO_PERMISSION,
                completed = "COMPLETED_NO",
                minor = minor.NoLogin,
              },
            },
            InvalidProperties = {
              params = {
                function (fixture)
                  return fixture.emptycomp.IComponent
                end,
                ReservedProperties,
              },
              except = checks.like{
                _repid = InvalidProperties,
                properties = ReservedProperties,
              },
            },
            UnauthorizedFacets = {
              params = {
                function (fixture) return fixture.component.IComponent end,
                SomeOfferProps,
              },
              except = checks.like{
                _repid = UnauthorizedFacets,
                facets = { GrantedFacetName },
              },
            },
          },
          findServices = {
            NoProperties = {
              params = { {} },
              result = { checks.like({n=0}, nil, {isomorphic=true}) }
            },
          },
          subscribeObserver = {
            Null = {
              params = { nil, SomeOfferProps },
              except = checks.like{
                _repid = sysex.BAD_PARAM,
                completed = "COMPLETED_NO",
                minor = 0,
              },
            },
          },
        },
        RegisterComponentWithoutFacets = function (fixture, openbus)
          local comp = fixture.emptycomp
          local login = openbus.context:getCurrentConnection().login
          local offer = fixture.offers:registerService(comp.IComponent, SomeOfferProps)
          return checks.assert(offer, isServiceOffer(comp, login, SomeOfferProps))
        end,
        RegisterComponentWithReservedButUnusedProps = function (fixture, openbus)
          local comp = fixture.emptycomp
          local login = openbus.context:getCurrentConnection().login
          local props = {
            {name="openbus.unused_01", value="value1"},
            {name="openbus.unused_02", value="value2"},
            {name="openbus.unused_03", value="value3"},
          }
          local offer = fixture.offers:registerService(comp.IComponent, props)
          return checks.assert(offer, isServiceOffer(comp, login, props))
        end,
        RegisterAndFindComponentWithoutProperties = function (fixture, openbus)
          local offers = fixture.offers
          local comp = fixture.emptycomp
          local login = openbus.context:getCurrentConnection().login
          local offer = offers:registerService(comp.IComponent, {})
          checks.assert(offer, isServiceOffer(comp, login, {}))
          local found = offers:findServices({})
          checks.assert(found, checks.like({n=0}, nil, {isomorphic=true}))
        end,
        SubscribeAndRemoveRegistryObservers = function (fixture, openbus)
          local offers = fixture.offers
          local observer = {}
          local subscriptions = {}
          local owner = openbus.context:getCurrentConnection().login
          for i, prop in ipairs(SomeOfferProps) do
            local props = {prop}
            subscriptions[i] = offers:subscribeObserver(observer, props)
            checks.assert(subscriptions[i], isOfferRegSubscription(owner,
                                                                   observer,
                                                                   props))
          end
          for i = #subscriptions, 1, -1 do
            subscriptions[i]:remove()
          end
          for _, subs in ipairs(subscriptions) do
            local ok, err = pcall(subs.remove, subs)
            checks.assert(ok, checks.equal(false))
            checks.assert(err, checks.like{
              _repid = sysex.OBJECT_NOT_EXIST,
              completed = "COMPLETED_NO",
              minor = 0,
            })
          end
        end,
        EmptyRegistryObserver = function (fixture, openbus)
          -- subscribe observer
          local offers = fixture.offers
          local observer = {}
          local subscription = offers:subscribeObserver(observer, SomeOfferProps)
          local owner = openbus.context:getCurrentConnection().login
          checks.assert(subscription, isOfferRegSubscription(owner,
                                                             observer,
                                                             SomeOfferProps))
          -- change service offer properties
          local context = openbus.context
          context:setCurrentConnection(fixture:newConn("system"))
          offers:registerService(fixture.component.IComponent, SomeOfferProps)
          context:setCurrentConnection(nil)
          -- error is only in bus log
          subscription:remove()
        end,
        RegistryObserver = function (fixture, openbus)
          -- create observer
          local context = openbus.context
          local observer = newObserver({ offerRegistered = true }, context)
          -- subscribe observer
          local offers = fixture.offers
          local subscription = offers:subscribeObserver(observer, SomeOfferProps)
          local owner = openbus.context:getCurrentConnection().login
          checks.assert(subscription, isOfferRegSubscription(owner,
                                                             observer,
                                                             SomeOfferProps))
          -- change service offer properties
          local system = fixture:newConn("system")
          context:setCurrentConnection(system)
          local comp = fixture.component
          offers:registerService(comp.IComponent, SomeOfferProps)
          context:setCurrentConnection(nil)
          -- wait for observer notification
          local desc = observer:_wait("offerRegistered")
          -- assert the notification is correct
          checks.assert(desc, isServiceOfferDesc(comp, system.login, SomeOfferProps))
          -- unsubscribe observer
          subscription:remove()
          -- change service offer properties again
          context:setCurrentConnection(system)
          offers:registerService(comp.IComponent, SomeOfferProps)
          context:setCurrentConnection(nil)
          -- assert no notifications have arrived
          checks.assert(observer:_get("offerRegistered"), checks.equal(nil))
        end,
        MultipleRegistryObservers = function (fixture, openbus)
          -- subscribe multiple observers
          local context = openbus.context
          local offers = fixture.offers
          local observers = {}
          local subscriptions = {}
          local owner = openbus.context:getCurrentConnection().login
          for i, prop in ipairs(SomeOfferProps) do
            observers[i] = newObserver({ offerRegistered = true }, context)
            local props = {prop}
            subscriptions[i] = offers:subscribeObserver(observers[i], props)
            checks.assert(subscriptions[i], isOfferRegSubscription(owner,
                                                                   observers[i],
                                                                   props))
          end
          -- change service offer properties
          local system = fixture:newConn("system")
          context:setCurrentConnection(system)
          local comp = fixture.component
          offers:registerService(comp.IComponent, SomeOfferProps)
          context:setCurrentConnection(nil)
          -- assert the subscribed observers were property notified
          local login = system.login
          for index, subscription in pairs(subscriptions) do
            local observer = observers[index]
            local desc = observer:_wait("offerRegistered")
            checks.assert(desc, isServiceOfferDesc(comp, login, SomeOfferProps))
          end
          -- unsubscribe the second observer
          local subscription = subscriptions[2]
          subscription:remove()
          subscriptions[2] = nil
          -- change service offer properties and remove the offer
          context:setCurrentConnection(system)
          offers:registerService(comp.IComponent, SomeOfferProps)
          context:setCurrentConnection(nil)
          -- assert the subscribed observers were property notified
          for index, subscription in pairs(subscriptions) do
            local observer = observers[index]
            local desc = observer:_wait("offerRegistered")
            checks.assert(desc, isServiceOfferDesc(comp, login, SomeOfferProps))
          end
          -- assert the unsubscribed observer were not notified
          local observer = observers[2]
          checks.assert(observer:_get("offerRegistered"), checks.equal(nil))
        end,
        RegistryObserverAfterSetProperties = function (fixture, openbus)
          -- create observer
          local context = openbus.context
          local observer = newObserver({ offerRegistered = true }, context)
          -- subscribe observer
          local offers = fixture.offers
          local newprops = { SomeOfferProps[1] }
          local subscription = offers:subscribeObserver(observer, newprops)
          local owner = openbus.context:getCurrentConnection().login
          checks.assert(subscription, isOfferRegSubscription(owner,
                                                             observer,
                                                             newprops))
          -- change service offer properties
          local system = fixture:newConn("system")
          context:setCurrentConnection(system)
          local comp = fixture.component
          local offer = offers:registerService(comp.IComponent, SomeOfferProps)
          context:setCurrentConnection(nil)
          -- wait for observer notification
          local desc = observer:_wait("offerRegistered")
          checks.assert(desc, isServiceOfferDesc(comp, system.login, SomeOfferProps))
          -- change service offer properties to a new set of watched properties
          context:setCurrentConnection(system)
          offer:setProperties(newprops)
          context:setCurrentConnection(nil)
          -- wait for observer notification
          desc = observer:_wait("offerRegistered")
          checks.assert(desc, isServiceOfferDesc(comp, system.login, newprops))
          -- change service offer properties to unwatched properties
          context:setCurrentConnection(system)
          offer:setProperties{ SomeOfferProps[2] }
          context:setCurrentConnection(nil)
          -- assert no notifications have arrived
          checks.assert(observer:_get("offerRegistered"), checks.equal(nil))
          -- unsubscribe observer
          subscription:remove()
          -- change service offer properties to the watched properties
          context:setCurrentConnection(system)
          offer:setProperties(SomeOfferProps)
          context:setCurrentConnection(nil)
          -- assert no notifications have arrived
          checks.assert(observer:_get("offerRegistered"), checks.equal(nil))
        end,
        UnauthorizedObserverRemoval = function (fixture, openbus)
          -- create observer
          local context = openbus.context
          local observer = newObserver({ offerRegistered = true }, context)
          -- subscribe observer
          local offers = fixture.offers
          local newprops = { SomeOfferProps[1] }
          local subscription = offers:subscribeObserver(observer, newprops)
          local owner = context:getCurrentConnection().login
          checks.assert(subscription, isOfferRegSubscription(owner,
                                                             observer,
                                                             newprops))
          local system = fixture:newConn("system")
          context:setCurrentConnection(system)
          -- attempt to remove observer
          local ok, err = pcall(subscription.remove, subscription)
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{ _repid = UnauthorizedOperation })
          -- change service offer properties
          local comp = fixture.component
          local offer = offers:registerService(comp.IComponent, SomeOfferProps)
          context:setCurrentConnection(nil)
          -- wait for observer notification
          local desc = observer:_wait("offerRegistered")
          checks.assert(desc, isServiceOfferDesc(comp, system.login, SomeOfferProps))
          -- unsubscribe observer
          subscription:remove()
          -- change service offer properties to the watched properties
          context:setCurrentConnection(system)
          offer:setProperties(SomeOfferProps)
          context:setCurrentConnection(nil)
          -- assert no notifications have arrived
          checks.assert(observer:_get("offerRegistered"), checks.equal(nil))
        end,
      },
    },
    AsSystem = OffersFixture{
      identity = "system",
      registered = true,
      tests = makeSimpleTests{
        offer = {
          setProperties = {
            Call = {
              params = { SomeOfferProps },
              result = {},
            },
            InvalidProperties = {
              params = { ReservedProperties },
              except = checks.like{
                _repid = InvalidProperties,
                properties = ReservedProperties,
              },
            },
          },
          remove = {
            Call = {
              params = {},
              result = {},
            },
          },
        },
        RemoveServiceOfferFound = function (fixture, openbus)
          local conn = fixture.system or openbus.context:getCurrentConnection()
          local login = conn.login
          local found = fixture.offers:findServices(SomeOfferProps)
          checks.assert(#found, checks.equal(1))
          local desc = found[1]
          checks.assert(desc, isServiceOfferDesc(fixture.component, login, SomeOfferProps))
          desc.ref:remove()
          found = fixture.offers:findServices(SomeOfferProps)
          checks.assert(#found, checks.equal(0))
        end,
        AddPropsAndFindServiceOffer = function (fixture, openbus)
          local conn = fixture.system or openbus.context:getCurrentConnection()
          local login = conn.login
          local offers = fixture.offers
          local found = offers:findServices(SomeOfferProps)
          checks.assert(#found, checks.equal(1))
          local desc = found[1]
          checks.assert(desc, isServiceOfferDesc(fixture.component, login, SomeOfferProps))
          -- change offer properties
          local newprops = {{name="newprop",value="newval"}}
          local props = table.copy(SomeOfferProps)
          props[#props+1] = newprops[1]
          desc.ref:setProperties(props)
          -- search offer again with old props
          local checkoffer = isServiceOfferDesc(fixture.component, login, props)
          found = offers:findServices(SomeOfferProps)
          checks.assert(#found, checks.equal(1))
          checks.assert(found[1], checkoffer)
          -- search offer again with new props
          found = offers:findServices(newprops)
          checks.assert(#found, checks.equal(1))
          checks.assert(found[1], checkoffer)
        end,
        RemovePropsAndFindServiceOffer = function (fixture, openbus)
          local conn = fixture.system or openbus.context:getCurrentConnection()
          local login = conn.login
          local offers = fixture.offers
          local found = offers:findServices(SomeOfferProps)
          checks.assert(#found, checks.equal(1))
          local desc = found[1]
          local checkoffer = 
          checks.assert(desc, isServiceOfferDesc(fixture.component, login, SomeOfferProps))
          -- change offer properties
          local newprops = {{name="newprop",value="newval"}}
          desc.ref:setProperties(newprops)
          -- search offer again with old props
          found = offers:findServices(SomeOfferProps)
          checks.assert(#found, checks.equal(0))
          -- search offer again with new props
          found = offers:findServices(newprops)
          checks.assert(#found, checks.equal(1))
          checks.assert(found[1], isServiceOfferDesc(fixture.component, login, newprops))
        end,
        RegisterManyOffers = function (fixture, openbus)
          local conn = fixture.system or openbus.context:getCurrentConnection()
          local login = conn.login
          local offers = fixture.offers
          local comp = fixture.component
          -- register one service offer
          local props1 = table.copy(SomeOfferProps)
          props1[#props1+1] = {name="specific", value="1st offer"}
          local offer1 = offers:registerService(comp.IComponent, props1)
          -- register another service offer
          local props2 = table.copy(SomeOfferProps)
          props2[#props2+1] = {name="specific", value="2nd offer"}
          local offer2 = offers:registerService(comp.IComponent, props2)
          
          -- search first service offer
          local found = offers:findServices(props1)
          checks.assert(#found, checks.equal(1))
          checks.assert(found[1], isServiceOfferDesc(comp, login, props1))
          -- search second service offer
          found = offers:findServices(props2)
          checks.assert(#found, checks.equal(1))
          checks.assert(found[1], isServiceOfferDesc(comp, login, props2))

          found = offers:findServices(SomeOfferProps)
          checks.assert(#found, checks.equal(3))
          for _, offer in ipairs(found) do
            local expected
            local val = getProperty(offer.properties, "specific")
            if val == "1st offer" then
              expected = props1
            elseif val == "2nd offer" then
              expected = props2
            else
              checks.assert(val, checks.equal(nil))
              expected = SomeOfferProps
              login = fixture.system or login
            end
            checks.assert(offer, isServiceOfferDesc(comp, login, expected))
          end
        end,
        RemoveOfferTwice = function (fixture)
          local offer = fixture.offer
          offer:remove()
          local ok, err = pcall(offer.remove, offer)
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{
            _repid = sysex.OBJECT_NOT_EXIST,
            completed = "COMPLETED_NO",
            minor = 0,
          })
        end,
        JIRA_OPENBUS_2577 = function (fixture, openbus)
          local conn = fixture.system or openbus.context:getCurrentConnection()
          local login = conn.login
          local offers = fixture.offers
          local comp = fixture.component
          local offer1 = offers:registerService(comp.IComponent, {
            {name="prop1", value="value1"},
            {name="prop2", value="YYYYYY"},
            {name="prop3", value="XXXXXX"},
          })
          local offer2 = offers:registerService(comp.IComponent, {
            {name="prop1", value="ZZZZZZ"},
            {name="prop2", value="value2"},
            {name="prop3", value="XXXXXX"},
          })
          -- search first service offer
          local props = {
            {name="prop1", value="value1"},
            {name="prop3", value="XXXXXX"},
            {name="prop2", value="value2"},
          }
          local found = offers:findServices(props)
          checks.assert(#found, checks.equal(0))
        end,
      },
    },
    AsClient = OffersFixture{
      identity = "user",
      registered = true,
      tests = makeSimpleTests{
        offer = {
          setProperties = {
            Unauthorized = {
              params = { SomeOfferProps },
              except = checks.like{ _repid = UnauthorizedOperation }
            },
          },
          remove = {
            Unauthorized = {
              params = {},
              except = checks.like{ _repid = UnauthorizedOperation }
            },
          },
          subscribeObserver = {
            Null = {
              params = { nil },
              except = checks.like{
                _repid = sysex.BAD_PARAM,
                completed = "COMPLETED_NO",
                minor = 0,
              },
            },
          },
        },
        FindServiceOffer = function (fixture, openbus)
          local login = fixture.system.login
          local found = fixture.offers:findServices(SomeOfferProps)
          checks.assert(#found, checks.equal(1))
          local desc = found[1]
          checks.assert(desc, isServiceOfferDesc(fixture.component, login, SomeOfferProps))
          local offer = desc.ref
          local ok, err = pcall(offer.setProperties, offer, SomeOfferProps)
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{_repid=UnauthorizedOperation})
          ok, err = pcall(offer.remove, offer)
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{_repid=UnauthorizedOperation})
          found = fixture.offers:findServices(SomeOfferProps)
          checks.assert(#found, checks.equal(1))
        end,
        FindBySingleProperty = function (fixture)
          local comp = fixture.component
          local login = fixture.system.login
          local offers = fixture.offers
          for _, prop in ipairs(SomeOfferProps) do
            local found = offers:findServices({prop})
            checks.assert(#found, checks.equal(1))
            checks.assert(found[1], isServiceOfferDesc(comp, login, SomeOfferProps))
          end
        end,
        GetAllServices = function (fixture)
          local comp = fixture.component
          local login = fixture.system.login
          local found = fixture.offers:getAllServices()
          checks.assert(#found, checks.equal(1))
          checks.assert(found[1], isServiceOfferDesc(comp, login, SomeOfferProps))
        end,
        SubscribeAndRemoveOfferObservers = function (fixture)
          local offer = fixture.offer
          local observer = {}
          local subs1 = offer:subscribeObserver(observer)
          local subs2 = offer:subscribeObserver(observer)
          local subs3 = offer:subscribeObserver(observer)
          subs2:remove()
          subs1:remove()
          subs3:remove()
          for subs in pairs({[subs1]=true,[subs2]=true,[subs3]=true}) do
            local ok, err = pcall(subs.remove, subs)
            checks.assert(ok, checks.equal(false))
            checks.assert(err, checks.like{
              _repid = sysex.OBJECT_NOT_EXIST,
              completed = "COMPLETED_NO",
              minor = 0,
            })
          end
        end,
        EmptyOfferObserver = function (fixture, openbus)
          -- subscribe observer
          local offer = fixture.offer
          local observer = {}
          local subscription = offer:subscribeObserver(observer)
          local owner = openbus.context:getCurrentConnection().login
          checks.assert(subscription, isOfferSubscription(owner,
                                                          observer,
                                                          fixture.component,
                                                          fixture.system.login,
                                                          SomeOfferProps))
          -- change service offer properties
          openbus.context:setCurrentConnection(fixture.system)
          offer:setProperties({{name="newprop",value="newval"}})
          offer:remove()
          -- error is only in bus log
        end,
        OfferPropertiesObserver = function (fixture, openbus)
          -- create observer
          local context = openbus.context
          local observer = newObserver({
            propertiesChanged = true,
            removed = true,
          }, context)
          -- subscribe observer
          local offer = fixture.offer
          local comp = fixture.component
          local system = fixture.system
          local login = system.login
          local subscription = offer:subscribeObserver(observer)
          local owner = openbus.context:getCurrentConnection().login
          checks.assert(subscription, isOfferSubscription(owner,
                                                          observer,
                                                          comp,
                                                          login,
                                                          SomeOfferProps))
          -- change service offer properties
          context:setCurrentConnection(system)
          local newprops = {{name="newprop",value="newval"}}
          offer:setProperties(newprops)
          context:setCurrentConnection(nil)
          -- wait for observer notification
          local desc = observer:_wait("propertiesChanged")
          -- assert the notification is correct
          checks.assert(desc, isServiceOfferDesc(comp, login, newprops))
          -- assert no other notification has arrived
          checks.assert(observer:_get("removed"), checks.equal(nil))
          -- unsubscribe observer
          subscription:remove()
          -- change service offer properties again
          context:setCurrentConnection(system)
          offer:setProperties(SomeOfferProps)
          context:setCurrentConnection(nil)
          -- assert no notifications have arrived
          checks.assert(observer:_get("propertiesChanged"), checks.equal(nil))
          checks.assert(observer:_get("removed"), checks.equal(nil))
        end,
        OfferRemovalObserver = function (fixture, openbus)
          -- create observer
          local context = openbus.context
          local observer = newObserver({
            propertiesChanged = true,
            removed = true,
          }, context)
          -- subscribe observer
          local offer = fixture.offer
          local comp = fixture.component
          local system = fixture.system
          local login = system.login
          local subscription = offer:subscribeObserver(observer)
          local owner = openbus.context:getCurrentConnection().login
          checks.assert(subscription, isOfferSubscription(owner,
                                                          observer,
                                                          comp,
                                                          login,
                                                          SomeOfferProps))
          -- remove service offer
          context:setCurrentConnection(system)
          offer:remove()
          context:setCurrentConnection(nil)
          -- wait for observer notification
          local desc = observer:_wait("removed")
          -- assert the notification is correct
          checks.assert(desc, isServiceOfferDesc(comp, login, SomeOfferProps, "removed"))
          -- assert no other notification has arrived
          checks.assert(observer:_get("propertiesChanged"), checks.equal(nil))
        end,
        MultipleOfferObservers = function (fixture, openbus)
          -- subscribe multiple observers
          local context = openbus.context
          local offer = fixture.offer
          local comp = fixture.component
          local system = fixture.system
          local login = system.login
          local observers = {}
          local subscriptions = {}
          local owner = openbus.context:getCurrentConnection().login
          for i = 1, 3 do
            observers[i] = newObserver({
              propertiesChanged = true,
              removed = true,
            }, context)
            subscriptions[i] = offer:subscribeObserver(observers[i])
            checks.assert(subscriptions[i], isOfferSubscription(owner,
                                                                observers[i],
                                                                comp,
                                                                login,
                                                                SomeOfferProps))
          end
          -- change service offer properties
          context:setCurrentConnection(system)
          local newprops = {{name="newprop",value="newval"}}
          offer:setProperties(newprops)
          context:setCurrentConnection(nil)
          -- assert the subscribed observers were property notified
          for index, subscription in pairs(subscriptions) do
            local observer = observers[index]
            local desc = observer:_wait("propertiesChanged")
            checks.assert(desc, isServiceOfferDesc(comp, login, newprops))
            checks.assert(observer:_get("removed"), checks.equal(nil))
          end
          -- unsubscribe the second observer
          local subscription = subscriptions[2]
          subscription:remove()
          subscriptions[2] = nil
          -- change service offer properties and remove the offer
          context:setCurrentConnection(system)
          offer:setProperties(SomeOfferProps)
          offer:remove()
          context:setCurrentConnection(nil)
          -- assert the subscribed observers were property notified
          local comp = fixture.component
          local login = system.login
          for index, subscription in pairs(subscriptions) do
            local observer = observers[index]
            local desc = observer:_wait("propertiesChanged")
            checks.assert(desc, isServiceOfferDesc(comp, login, SomeOfferProps, "removed"))
            desc = observer:_wait("removed")
            checks.assert(desc, isServiceOfferDesc(comp, login, SomeOfferProps, "removed"))
          end
          -- assert the unsubscribed observer were not notified
          local observer = observers[2]
          checks.assert(observer:_get("removed"), checks.equal(nil))
          checks.assert(observer:_get("propertiesChanged"), checks.equal(nil))
        end,
        UnauthorizedObserverRemoval = function (fixture, openbus)
          -- create observer
          local context = openbus.context
          local observer = newObserver({
            propertiesChanged = true,
            removed = true,
          }, context)
          -- subscribe observer
          local offer = fixture.offer
          local comp = fixture.component
          local system = fixture.system
          local login = system.login
          local subscription = offer:subscribeObserver(observer)
          local owner = context:getCurrentConnection().login
          checks.assert(subscription, isOfferSubscription(owner,
                                                          observer,
                                                          comp,
                                                          login,
                                                          SomeOfferProps))
          -- attempt to remove observer as other entity
          context:setCurrentConnection(system)
          local ok, err = pcall(subscription.remove, subscription)
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{ _repid = UnauthorizedOperation })
          -- remove service offer
          offer:remove()
          context:setCurrentConnection(nil)
          -- wait for observer notification
          local desc = observer:_wait("removed")
          -- assert the notification is correct
          checks.assert(desc, isServiceOfferDesc(comp, login, SomeOfferProps, "removed"))
          -- assert no other notification has arrived
          checks.assert(observer:_get("propertiesChanged"), checks.equal(nil))
        end,
      },
    },
  },
}
