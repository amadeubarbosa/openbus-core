------------------------------------------------------------------------------
-- OpenBus 2.0 Support
-- $Id$
------------------------------------------------------------------------------

local _G = require "_G"
local assert = _G.assert
local ipairs = _G.ipairs
local pairs = _G.pairs
local rawset = _G.rawset

local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "openbus.util.oo"
local class = oo.class

local idl = require "openbus.core.legacy.idl"
local UnauthorizedOperation = idl.throw.services.UnauthorizedOperation
local acctyp = idl.types.services.access_control
local AccessControlType = acctyp.AccessControl
local LoginObsType = acctyp.LoginObserver
local LoginObsSubType = acctyp.LoginObserverSubscription
local LoginProcessType = acctyp.LoginProcess
local LoginRegistryType = acctyp.LoginRegistry
local offtyp = idl.types.services.offer_registry
local OfferObsType = offtyp.OfferObserver
local OffObserverSubType = offtyp.OfferObserverSubscription
local OffRegObserverType = offtyp.OfferRegistryObserver
local OffRegObsSubType = offtyp.OfferRegistryObserverSubscription
local OfferRegistryType = offtyp.OfferRegistry
local ServiceOfferType = offtyp.ServiceOffer

local function traceback(errmsg)
  if type(errmsg) == "string" then
    return debug.traceback(errmsg)
  end
  return errmsg
end

local function doexcept(ok, ...)
  if not ok then
    local ex = ...
    if type(ex) == "table" and type(ex._repid) == "string" then
      ex._repid = ex._repid:gsub("v2_1", "v2_0")
    end
    error(ex)
  end
  return ...
end

local function trymethod(object, field, ...)
  return doexcept(xpcall(object[field], traceback, object, ...))
end

local function wrapmethod(object, field)
  local method = object[field]
  object[field] = function (self, ...)
    return doexcept(xpcall(method, traceback, self, ...))
  end
end

local methods = memoize(function(method)
  return function(self, ...)
    return doexcept(xpcall(method, traceback, self.__object, ...))
  end
end, "k")

local Wrapper = class{
  __index = function(self, key)
    local value = self.__object[key]
    if type(value) == "function" then
      return methods[value]
    else
      return value
    end
  end,
}

------------------------------------------------------------------------------
-- Faceta AccessControl
------------------------------------------------------------------------------

local AccessControl = Wrapper{ __type = AccessControlType }

-- local operations

function AccessControl:__init(data)
  -- initialize attributes
  self.__object = data.services.AccessControl -- delegatee (see 'Wrapper' class)
  -- setup operation access
  local access = data.access
  access:setGrantedUsers(self.__type, "_get_busid", "any")
  access:setGrantedUsers(self.__type, "_get_buskey", "any")
  access:setGrantedUsers(self.__type, "loginByPassword", "any")
  access:setGrantedUsers(self.__type, "startLoginByCertificate", "any")
  access:setGrantedUsers(LoginProcessType, "*", "any")
end

-- IDL operations

function AccessControl:startLoginByCertificate(...)
  local logger, secret = trymethod(self.__object, "startLoginByCertificate", ...)
  logger.__type = LoginProcessType
  wrapmethod(logger, "login")
  return logger, secret
end

function AccessControl:startLoginBySharedAuth(...)
  local logger, secret = trymethod(self.__object, "startLoginBySharedAuth", ...)
  logger.__type = LoginProcessType
  wrapmethod(logger, "login")
  return logger, secret
end

------------------------------------------------------------------------------
-- Faceta LoginRegistry
------------------------------------------------------------------------------

local LoginRegistry = Wrapper{ __type = LoginRegistryType }

-- local operations

function LoginRegistry:__init(data)
  -- initialize attributes
  self.__object = data.services.LoginRegistry -- delegatee (see 'Wrapper' class)
  self.access = data.access
  self.admins = data.admins
  -- deactivate subscriptions of legacy observers and restore them as legacy
  -- subscriptions
  local orb = data.access.orb
  local refs = orb.ObjectReferrer.references
  for id, subscription in pairs(self.__object.subscriptionOf) do
    local ref = assert(refs:decodestring(subscription.observer.ior))
    if ref.type_id == LoginObsType then -- TODO: and a derived interface?
      orb:deactivate(subscription)
      subscription.__type = LoginObsSubType
      orb:newservant(subscription)
    end
  end
end

-- IDL operations

function LoginRegistry:getAllLogins(...)
  local entity = self.access:getCallerChain().caller.entity
  if self.admins[entity] == nil then
    UnauthorizedOperation()
  end
  return trymethod(self.__object, "getAllLogins", ...)
end

function LoginRegistry:getLoginInfo(...)
  local login, signedkey = trymethod(self.__object, "getLoginInfo", ...)
  return login, signedkey.encoded
end

do
  function LoginRegistry:subscribeObserver(...)
    local subscription = trymethod(self.__object, "subscribeObserver", ...)
    subscription.__type = LoginObsSubType
    wrapmethod(subscription, "remove")
    return subscription
  end
end

------------------------------------------------------------------------------
-- Faceta OfferRegistry
------------------------------------------------------------------------------

local wrapoffer -- forward declaration

local OfferObserverSubscription do
  local OfferObserver = class()

  function OfferObserver:propertiesChanged(offer)
    return self.__object:propertiesChanged(wrapoffer(offer))
  end

  function OfferObserver:removed(offer)
    return self.__object:removed(wrapoffer(offer))
  end

  local function _get_observer(self)
    return self.observer.__object
  end

  local function _get_offer(self)
    return wrapoffer(self.offer)
  end

  local function describe(self)
    return {
      observer = self:_get_observer(),
      offer = self:_get_offer(),
    }
  end

  function OfferObserverSubscription(subscription)
    subscription.observer = OfferObserver{ __object = subscription.observer }
    subscription.__type = OffObserverSubType
    subscription._get_observer = _get_observer
    subscription._get_offer = _get_offer
    subscription.describe = describe
    wrapmethod(subscription, "remove")
    return subscription
  end
end



local OfferRegistryObserverSubscription do
  local OfferRegistryObserver = class()

  function OfferRegistryObserver:offerRegistered(offer)
    return self.__object:offerRegistered(wrapoffer(offer))
  end

  local function _get_observer(self)
    return self.observer.__object
  end

  local function describe(self)
    return {
      observer = self:_get_observer(),
      properties = self.properties,
    }
  end

  function OfferRegistryObserverSubscription(subscription)
    subscription.observer = OfferRegistryObserver{
      __object = subscription.observer
    }
    subscription.__type = OffRegObsSubType
    subscription._get_observer = _get_observer
    subscription.describe = describe
    wrapmethod(subscription, "remove")
    return subscription
  end
end



do
  local LocalOfferObserverSubscription = class()

  function LocalOfferObserverSubscription:remove()
    self.offer.registry.access.orb:deactivate(self.wrapper)
  end

  function LocalOfferObserverSubscription:propertiesChanged()
    -- nothing to do when this offer observer notification happens
  end

  function LocalOfferObserverSubscription:removed()
    -- nothing to do when this offer observer notification happens
  end

  local function subscribeObserver(self, observer)
    local subscription = trymethod(self.__object, "subscribeObserver", observer)
    return OfferObserverSubscription(subscription)
  end

  local function describeOffer(self)
    return self
  end

  function wrapoffer(offer)
    local wrapper = offer.legacy
    if wrapper == nil then
      local id = offer.id
      wrapper = Wrapper{
        __object = offer,
        __type = ServiceOfferType,
        __objkey = "Offer:"..id,
        describe = describeOffer,
        subscribeObserver = subscribeObserver,
      }
      wrapper.ref = wrapper
      local subscription = LocalOfferObserverSubscription{
        offer = offer,
        wrapper = wrapper,
        __reference = {}, -- to make it look like an OiL proxy
      }
      subscription.observer = subscription
      local registry = offer.registry
      local login = registry.access.login.id
      offer.observers[id] = login
      offer.registry.observerLogins[login][offer][id] = subscription
      offer.legacy = wrapper
    end
    return wrapper
  end
end



local OfferRegistry = { __type = OfferRegistryType } -- is local (see forward declaration)

function OfferRegistry:__init(data)
  -- initialize attributes
  self.__object = data.services.OfferRegistry -- delegatee (see 'Wrapper' class)
  -- deactivate subscriptions of legacy observers and restore them as legacy
  -- subscriptions
  local orb = data.access.orb
  local registry = self.__object
  local observerLogins = registry.observerLogins
  for id, login in pairs(registry.observers) do
    local subscription = observerLogins[login][registry][id]
    local ref = subscription.observer.__reference
    if ref.type_id == OffRegObserverType then -- TODO: and a derived interface?
      orb:deactivate(subscription)
      subscription.observer = orb:newproxy(subscription.observer, nil,
                                           OffRegObserverType)
      orb:newservant(OfferRegistryObserverSubscription(subscription))
    end
  end
  for _, offers in pairs(registry.offers.index["openbus.offer.id"]) do
    for offer in pairs(offers) do
      orb:newservant(wrapoffer(offer))
      for id, login in pairs(offer.observers) do
        local subscription = observerLogins[login][offer][id]
        local ref = subscription.observer.__reference
        if ref.type_id == OfferObsType then -- TODO: and a derived interface?
          orb:deactivate(subscription)
          subscription.observer = orb:newproxy(subscription.observer, nil,
                                              OfferObsType)
          orb:newservant(OfferObserverSubscription(subscription))
        end
      end
    end
  end
end


-- IDL operations

function OfferRegistry:registerService(...)
  local offer = trymethod(self.__object, "registerService", ...)
  return wrapoffer(offer)
end

do
  local function wrapOffers(offers)
    for index, offer in ipairs(offers) do
      offers[index] = wrapoffer(offer)
    end
    return offers
  end

  function OfferRegistry:findServices(...)
    local offers = trymethod(self.__object, "findServices", ...)
    return wrapOffers(offers)
  end

  function OfferRegistry:getAllServices(...)
    local offers = trymethod(self.__object, "getAllServices", ...)
    return wrapOffers(offers)
  end
end

function OfferRegistry:subscribeObserver(observer, ...)
  local subscription = trymethod(self.__object, "subscribeObserver",
                                 observer, ...)
  return OfferRegistryObserverSubscription(subscription)
end

-- Exported Module -----------------------------------------------------------

return {
  AccessControl = AccessControl,
  LoginRegistry = LoginRegistry,
  OfferRegistry = OfferRegistry,
}
