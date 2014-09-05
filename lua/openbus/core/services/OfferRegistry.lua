-- $Id$

local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local pcall = _G.pcall
local rawget = _G.rawget
local rawset = _G.rawset
local tostring = _G.tostring

local coroutine = require "coroutine"
local newthread = coroutine.create

local array = require "table"
local concat = array.concat

local os = require "os"
local date = os.date
local time = os.time

local cothread = require "cothread"
local schedule = cothread.schedule

local uuid = require "uuid"
local newid = uuid.new

local autotable = require "openbus.util.autotable"
local newautotab = autotable.create
local delautotab = autotable.remove
local getautotab = autotable.get
local log = require "openbus.util.logger"
local oo = require "openbus.util.oo"
local class = oo.class
local sysex = require "openbus.util.sysex"
local BAD_PARAM = sysex.BAD_PARAM

local idl = require "openbus.core.idl"
local assert = idl.serviceAssertion
local ServiceFailure = idl.throw.services.ServiceFailure
local offexp = idl.throw.services.offer_registry
local InvalidProperties = offexp.InvalidProperties
local InvalidService = offexp.InvalidService
local UnauthorizedFacets = offexp.UnauthorizedFacets
local offtyp = idl.types.services.offer_registry
local OfferedService = offtyp.OfferedService
local OfferObsType = offtyp.OfferObserver
local OffObserverSubType = offtyp.OfferObserverSubscription
local OffRegObserverType = offtyp.OfferRegistryObserver
local OffRegObsSubType = offtyp.OfferRegistryObserverSubscription
local OfferRegistryType = offtyp.OfferRegistry
local ServiceOfferType = offtyp.ServiceOffer

local mngidl = require "openbus.core.admin.idl"
local mngexp = mngidl.throw.services.offer_registry.admin.v1_0
local AuthorizationInUse = mngexp.AuthorizationInUse
local EntityAlreadyRegistered = mngexp.EntityAlreadyRegistered
local EntityCategoryAlreadyExists = mngexp.EntityCategoryAlreadyExists
local EntityCategoryInUse = mngexp.EntityCategoryInUse
local InterfaceInUse = mngexp.InterfaceInUse
local InvalidInterface = mngexp.InvalidInterface
local mngtyp = mngidl.types.services.offer_registry.admin.v1_0
local EntityCategory = mngtyp.EntityCategory
local EntityRegistryType = mngtyp.EntityRegistry
local InterfaceRegistryType = mngtyp.InterfaceRegistry
local RegisteredEntity = mngtyp.RegisteredEntity

local msg = require "openbus.core.services.messages"
local AccessControl = require "openbus.core.services.AccessControl"
AccessControl = AccessControl.AccessControl
local PropertyIndex = require "openbus.core.services.PropertyIndex"

local coreutil = require "openbus.core.services.util"
local assertCaller = coreutil.assertCaller

local OfferRegistry -- forward declaration
local EntityRegistry -- forward declaration


local function ifaceId2Key(ifaceId)
  local name, version = ifaceId:match("^IDL:(.-):(%d+%.%d+)$")
  if name == nil then
    InvalidInterface{ ifaceId = ifaceId }
  end
  return name:gsub("/", ".").."-"..version
end

local function updateAuthorization(db, id, set, spec, value)
  local backup = set[spec]
  set[spec] = value
  local ok, errmsg = db:setentryfield(id, "authorized", set)
  if not ok then
    set[spec] = backup
    ServiceFailure{message=errmsg}
  end
end

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
  ["openbus.component.platform"] = true,
  ["openbus.component.interface"] = true,
  ["openbus.component.facet"] = true,
}

local function makePropertyList(entry, service_props)
  local props = {
    { name = "openbus.offer.id", value = entry.id },
    { name = "openbus.offer.login", value = entry.login },
    { name = "openbus.offer.entity", value = entry.entity },
    { name = "openbus.offer.timestamp", value = entry.creation.timestamp },
    { name = "openbus.offer.year", value = entry.creation.year },
    { name = "openbus.offer.month", value = entry.creation.month },
    { name = "openbus.offer.day", value = entry.creation.day },
    { name = "openbus.offer.hour", value = entry.creation.hour },
    { name = "openbus.offer.minute", value = entry.creation.minute },
    { name = "openbus.offer.second", value = entry.creation.second },
    { name = "openbus.component.name", value = entry.component.name },
    { name = "openbus.component.version.major", value = tostring(entry.component.major_version) },
    { name = "openbus.component.version.minor", value = tostring(entry.component.minor_version) },
    { name = "openbus.component.version.patch", value = tostring(entry.component.patch_version) },
    { name = "openbus.component.platform", value = entry.component.platform_spec },
  }
  local interfaces = {}
  for _, facet in ipairs(entry.facets) do
    interfaces[facet.interface_name] = true
    props[#props+1] = {name="openbus.component.facet",value=facet.name}
  end
  for interface in pairs(interfaces) do
    props[#props+1] = {name="openbus.component.interface",value=interface}
  end
  local illegal = {}
  for _, prop in ipairs(service_props) do
    if ReservedProperties[prop.name] == nil then
      props[#props+1] = prop
    else
      illegal[#illegal+1] = prop
    end
  end
  if #illegal > 0 then
    InvalidProperties{ properties = illegal }
  end
  return props
end

local function registerObserver(self, watched, id, subscription)
  local login = subscription.login
  watched.observers[id] = login
  self.observerLogins[login][watched][id] = subscription
end

local function unregisterObserver(self, watched, id)
  local observers = watched.observers
  local login = observers[id]
  observers[id] = nil
  return delautotab(self.observerLogins, login, watched, id)
end

local function notifyOfferObservers(self, watched, event, offer)
  local observerLogins = self.observerLogins
  for id, login in pairs(watched.observers) do
    local subscription = observerLogins[login][watched][id]
    local observer = subscription.observer
    schedule(newthread(function()
      local ok, errmsg = pcall(observer[event], observer, offer)
      if not ok then
        log:exception(msg.OfferObserverException:tag{
          id = id,
          owner = subscription.login,
          watched = watched.id,
          errmsg = errmsg,
        })
      end
    end))
  end
end

------------------------------------------------------------------------------
-- Faceta OfferRegistry
------------------------------------------------------------------------------

local OfferObserverSubscription = class{
  __type = OffObserverSubType,
}

function OfferObserverSubscription:__init()
  local id = self.id
  local offer = self.offer
  self.__objkey = "OfferObserver_v2.1:"..id -- for the ORB
  registerObserver(offer.registry, offer, id, self)
end

function OfferObserverSubscription:describe()
  return self
end

function OfferObserverSubscription:remove(tag)
  local id = self.id
  local offer = self.offer
  local registry = offer.registry
  local tag = tag or assertCaller(registry,
    AccessControl:getLoginEntry(self.login).entity)
  -- try to remove persisted observer (may raise expections)
  assert(offer.database:setentryfield(offer.id, "observers", id, nil))
  -- commit changes in memory
  registry.access.orb:deactivate(self)
  unregisterObserver(registry, offer, id)
  log[tag](log, msg.UnsubscribeOfferObserver:tag{
    login = self.login,
    offer = offer.id,
    id = id,
  })
end



local OfferRegistryObserverSubscription = class{
  __type = OffRegObsSubType,
}

function OfferRegistryObserverSubscription:__init()
  local id = self.id
  local registry = self.registry
  self.__objkey = "OfferRegObs_v2.1:"..id -- for the ORB
  registerObserver(registry, registry, id, self)
end

function OfferRegistryObserverSubscription:describe()
  return self
end

function OfferRegistryObserverSubscription:remove(tag)
  local id = self.id
  local registry = self.registry
  local tag = tag or assertCaller(registry,
    AccessControl:getLoginEntry(self.login).entity)
  -- try to remove persisted observer (may raise expections)
  assert(registry.offerRegObsDB:removeentry(id))
  -- commit change to memory
  registry.access.orb:deactivate(self)
  unregisterObserver(registry, registry, id)
  log[tag](log, msg.UnsubscribeOfferRegistryObserver:tag{
    login = self.login,
    id = id,
  })
end


local Offer = class{ __type = ServiceOfferType }
  
function Offer:__init()
  self.ref = self -- IDL struct attribute (see operation 'describe')
  self.__objkey = "Offer_v2.1:"..self.id -- for the ORB
  self.registry.offers:add(self)
  -- recover observers
  local persistedObs = self.observers -- backup observer persisted entries
  self.observers = {} -- this table will contain entries in memory only
                      -- which is filled by operation 'registerObserver'
  local orb = self.registry.access.orb
  for id, entry in pairs(persistedObs) do
    local login = entry.login
    if AccessControl:getLoginEntry(login) then
      log:action(msg.RecoverPersistedOfferObserver:tag{
        login = login,
        offer = self.id,
        id = id,
      })
      orb:newservant(OfferObserverSubscription{
        login = login,
        id = id,
        observer = orb:newproxy(entry.observer, nil, OfferObsType),
        offer = self,
      })
    else
      log:action(msg.DiscardOfferObserverAfterLogout:tag{
        login = login,
        offer = self.id,
        id = id,
      })
      persistedObs[id] = nil
    end
  end
  -- commit removal of logged out observers (may raise expections)
  assert(self.database:setentryfield(self.id, "observers", persistedObs))
end

function Offer:describe()
  return self
end

function Offer:setProperties(properties)
  local registry = self.registry
  local tag = assertCaller(registry, self.entity)
  -- try to change persisted properties (may raise expections)
  local allprops = makePropertyList(self, properties)
  assert(self.database:setentryfield(self.id, "properties", properties))
  -- commit changes in memory
  local offers = registry.offers
  offers:remove(self)
  self.properties = allprops
  offers:add(self)
  log[tag](log, msg.UpdateOfferProperties:tag{ offer = self.id })
  -- notify observers
  notifyOfferObservers(registry, self, "propertiesChanged", self)
  registry:notifyRegistryObservers(self)
end

function Offer:remove(tag)
  local registry = self.registry
  local tag = tag or assertCaller(registry, self.entity)
  -- schedule notification of observers
  notifyOfferObservers(registry, self, "removed", self)
  -- unregister observers from the logout callback
  local observerLogins = registry.observerLogins
  for id, login in pairs(self.observers) do
    observerLogins[login][self][id]:remove(tag)
  end
  -- try to remove persisted offer (may raise expections)
  assert(self.database:removeentry(self.id))
  -- commit changes in memory
  registry.access.orb:deactivate(self)
  registry.offers:remove(self)
  log[tag](log, msg.RemoveServiceOffer:tag{
    offer = self.id,
    entity = self.entity,
    login = self.login,
  })
end

function Offer:subscribeObserver(observer)
  if observer == nil then
    BAD_PARAM{ completed = "COMPLETED_NO", minor = 0 }
  end
  local registry = self.registry
  local offerid = self.id
  local login = registry.access:getCallerChain().caller.id
  local entry = {
    login = login,
    observer = tostring(observer),
  }
  local id = newid("time")
  -- try to persist observer (may raise expections)
  assert(self.database:setentryfield(offerid, "observers", id, entry))
  -- commit changes in memory
  log:request(msg.SubscribeOfferObserver:tag{
    login = login,
    offer = offerid,
    id = id,
  })
  entry.id = id
  entry.observer = observer
  entry.offer = self
  return OfferObserverSubscription(entry)
end


OfferRegistry = { __type = OfferRegistryType } -- is local (see forward declaration)

function OfferRegistry:loginRemoved(login)
  do -- observers
    local watchedMap = rawget(self.observerLogins, login.id)
    if watchedMap ~= nil then
      for watched, subscriptions in pairs(watchedMap) do
        for id, subscription in pairs(subscriptions) do
          subscription:remove("action")
        end
      end
    end
  end
  do -- offers
    for offer in pairs(self.offers:get("openbus.offer.login", login.id)) do
      offer:remove("action")
    end
  end
end

function OfferRegistry:loginObserverRemoved()
  -- empty
end

function OfferRegistry:notifyRegistryObservers(offer)
  local offers = self.offers
  local observerLogins = self.observerLogins
  for id, login in pairs(self.observers) do
    local subscription = observerLogins[login][self][id]
    local matched
    for _, prop in ipairs(subscription.properties) do
      matched = offers:get(prop.name, prop.value)[offer]
      if not matched then break end
    end
    if matched then
      local observer = subscription.observer
      schedule(newthread(function()
        local ok, errmsg = pcall(observer.offerRegistered, observer, offer)
        if not ok then
          log:exception(msg.OfferRegistryObserverException:tag{
            id = id,
            errmsg = errmsg,
          })
        end
      end))
    end
  end
end

function OfferRegistry:__init(data)
  self.access = data.access
  self.admins = data.admins
  self.enforceAuth = data.enforceAuth
  self.offers = PropertyIndex()
  self.observers = {}
  self.observerLogins = newautotab()
  self.offerDB = assert(data.database:gettable("Offers"))
  self.offerRegObsDB = assert(data.database:gettable("OfferRegistryObservers"))
  
  -- register itself to receive logout notifications
  rawset(AccessControl.activeLogins.publisher, self, self)
  
  local access = self.access
  local orb = access.orb
  do -- recover offers
    local offerDB = self.offerDB
    local toberemoved = {}
    for id, entry in assert(offerDB:ientries()) do
      local entity = entry.entity
      local login = entry.login
      if AccessControl:getLoginEntry(login) then
        log:action(msg.RecoverPersistedOffer:tag{
          offer = id,
          entity = entity,
          login = login,
        })
        if self.enforceAuth and EntityRegistry:getEntity(entity) == nil then
          ServiceFailure{
            message = msg.CorruptedDatabaseDueToMissingEntity:tag{
              entity = entity,
            }
          }
        end
        -- create object for the new offer
        entry.id = id
        entry.service_ref = orb:newproxy(entry.service_ref, nil,
                                         OfferedService)
        entry.properties = makePropertyList(entry, entry.properties)
        entry.registry = self
        entry.database = offerDB
        orb:newservant(Offer(entry))
      else
        log:action(msg.DiscardPersistedOfferAfterLogout:tag{
          offer = id,
          entity = entity,
          login = login,
        })
        toberemoved[id] = true
      end
    end
    for id in pairs(toberemoved) do
      offerDB:removeentry(id)
    end
  end
  local observerLogins = self.observerLogins
  do -- recover observers
    local offerRegObsDB = self.offerRegObsDB
    local toberemoved = {}
    for id, entry in assert(offerRegObsDB:ientries()) do
      local login = entry.login
      if AccessControl:getLoginEntry(login) then
        log:action(msg.RecoverPersistedOfferRegistryObserver:tag{
          id = id,
          login = login,
        })
        entry.id = id
        entry.observer = orb:newproxy(entry.observer, nil,
                                      OffRegObserverType)
        entry.registry = self
        orb:newservant(OfferRegistryObserverSubscription(entry))
      else
        log:action(msg.DiscardOfferRegistryObserverAfterLogout:tag{
          id = id,
          login = login,
        })
        toberemoved[id] = true
      end
    end
    for id in pairs(toberemoved) do
      offerRegObsDB:removeentry(id)
    end
  end
end

local IgnoredFacets = {
  IComponent = true,
  IMetaInterface = true,
  IReceptacles = true,
}

function OfferRegistry:registerService(service_ref, properties)
  if service_ref == nil then
    InvalidService{ message = msg.NullReference }
  end
  -- collect information about the SCS component implementing the service
  local ok, result = pcall(service_ref.getComponentId, service_ref)
  if not ok then
    InvalidService{message=msg.UnableToObtainComponentId:tag{
      error = result,
    }}
  end
  local compId = result
  ok, result = pcall(service_ref.getFacetByName, service_ref, "IMetaInterface")
  if not ok then
    InvalidService{message=msg.UnableToObtainStandardFacet:tag{
      name = "IMetaInterface",
      error = result,
    }}
  elseif result == nil then
    InvalidService{message=msg.MissingStandardFacet:tag{
      name = "IMetaInterface",
    }}
  end
  local meta = result:__narrow("scs::core::IMetaInterface")
  ok, result = pcall(meta.getFacets, meta)
  if not ok then
    InvalidService{message=msg.UnableToObtainServiceFacets:tag{
      error = result,
    }}
  end
  local facets = {}
  for index, facet in ipairs(result) do
    facets[index] = {
      name = facet.name,
      interface_name = facet.interface_name,
    }
  end
  -- get information about the caller
  local login = self.access:getCallerChain().caller
  local entityId = login.entity
  -- check the caller is authorized to offer such service
  if self.enforceAuth then
    local entity = EntityRegistry:getEntity(entityId)
    local unauthorized = {}
    for _, facet in ipairs(facets) do
      local facetname = facet.name
      if IgnoredFacets[facetname] == nil
      and (entity == nil or entity.authorized[facet.interface_name] == nil)
      then
        unauthorized[#unauthorized+1] = facetname
      end
    end
    if #unauthorized > 0 then
      UnauthorizedFacets{
        entity = entityId,
        facets = unauthorized,
      }
    end
  end
  -- validate provided properties
  local id = newid("time")
  local timestamp = time()
  local entry = {
    id = id,
    service_ref = tostring(service_ref),
    entity = entityId,
    login = login.id,
    creation = {
      timestamp = tostring(timestamp),
      day = date("%d", timestamp),
      month = date("%m", timestamp),
      year = date("%Y", timestamp),
      hour = date("%H", timestamp),
      minute = date("%M", timestamp),
      second = date("%S", timestamp),
    },
    component = compId,
    facets = facets,
    properties = properties,
    observers = {},
  }
  local allprops = makePropertyList(entry, properties)
  -- persist the new offer
  local database = self.offerDB
  assert(database:setentry(id, entry))
  -- create object for the new offer
  entry.service_ref = service_ref
  entry.properties = allprops
  entry.registry = self
  entry.database = database
  log:request(msg.RegisterServiceOffer:tag{
    offer = id,
    entity = entityId,
    login = login.id,
  })
  local offer = Offer(entry)
  self:notifyRegistryObservers(offer)
  return offer
end

function OfferRegistry:findServices(properties)
  return self.offers:find(properties)
end

function OfferRegistry:getAllServices()
  local result = {}
  for _, offers in pairs(self.offers.index["openbus.offer.id"]) do
    for offer in pairs(offers) do
      result[#result+1] = offer
    end
  end
  return result
end

function OfferRegistry:subscribeObserver(observer, properties)
  if observer == nil then
    BAD_PARAM{ completed = "COMPLETED_NO", minor = 0 }
  end
  local login = self.access:getCallerChain().caller.id
  local id = newid("time")
  local entry = { 
    login = login,
    properties = properties,
    observer = tostring(observer),
  }
  -- try to persist observer (may raise expections)
  assert(self.offerRegObsDB:setentry(id, entry))
  -- commit change to memory
  log:request(msg.SubscribeOfferRegistryObserver:tag{
    login = login,
    id = id,
  })
  entry.id = id
  entry.observer = observer
  entry.registry = self
  return OfferRegistryObserverSubscription(entry)
end

------------------------------------------------------------------------------
-- Faceta InterfaceRegistry
------------------------------------------------------------------------------

local InterfaceRegistry = {
  __type = InterfaceRegistryType,
  interfaces = {},
}

function InterfaceRegistry:__init(data)
  -- initialize attributes
  self.database = data.database
  
  -- setup permissions
  local access = data.access
  local admins = data.admins
  access:setGrantedUsers(self.__type,"registerInterface",admins)
  access:setGrantedUsers(self.__type,"removeInterface",admins)
  
  -- recover all registered interfaces
  local database = self.database
  local interfaces = self.interfaces
  local interfaceDB = assert(database:gettable("Interfaces"))
  for _, ifaceId in assert(interfaceDB:ientries()) do
    interfaces[ifaceId] = {}
  end
  self.interfaceDB = interfaceDB
end

function InterfaceRegistry:registerInterface(ifaceId)
  local interfaces = self.interfaces
  local entities = interfaces[ifaceId]
  if entities == nil then
    self.interfaceDB:setentry(ifaceId2Key(ifaceId), ifaceId)
    interfaces[ifaceId] = {}
    log:admin(msg.RegisteredInterfaceAdded:tag{interface=ifaceId})
    return true
  end
  return false
end

function InterfaceRegistry:removeInterface(ifaceId)
  local interfaces = self.interfaces
  local entities = interfaces[ifaceId]
  if entities ~= nil then
    if next(entities) ~= nil then
      local list = {}
      for entity in pairs(entities) do
        list[#list+1] = entity
      end
      InterfaceInUse{ ifaceId = ifaceId, entities = list }
    end
    self.interfaceDB:removeentry(ifaceId2Key(ifaceId))
    interfaces[ifaceId] = nil
    log:admin(msg.RegisteredInterfaceRemoved:tag{interface=ifaceId})
    return true
  end
  return false
end

function InterfaceRegistry:getInterfaces()
  local list = {}
  for ifaceId in pairs(self.interfaces) do
    list[#list+1] = ifaceId
  end
  return list
end


------------------------------------------------------------------------------
-- Faceta EntityRegistry
------------------------------------------------------------------------------

local Entity = class{ __type = RegisteredEntity }

function Entity:__init()
  local id = self.id
  self.authorized = self.authorized or {}
  self.ref = self -- IDL struct attribute (see operation 'describe')
  self.__objkey = "Entity:"..id -- for the ORB
  self.registry.entities[id] = self
  self.category.entities[id] = self
end

function Entity:describe()
  return self
end

function Entity:setName(name)
  assert(self.database:setentryfield(self.id, "name", name))
  self.name = name
  log:admin(msg.AuthorizedEntityNameChanged:tag{entity=self.id,name=name})
end

function Entity:remove()
  local id = self.id
  local registry = self.registry
  if registry.enforceAuth then
    local offers = OfferRegistry.offers:get("openbus.offer.entity", id)
    for offer in pairs(offers) do
      offer:remove()
    end
  end
  assert(self.database:removeentry(id))
  registry.access.orb:deactivate(self)
  local interfaces = InterfaceRegistry.interfaces
  for ifaceId in pairs(self.authorized) do
    interfaces[ifaceId][self] = nil
  end
  registry.entities[id] = nil
  self.category.entities[id] = nil
  log:admin(msg.AuthorizedEntityRemoved:tag{entity=id})
end

function Entity:grantInterface(ifaceId)
  -- check if interface is registered
  local entities = InterfaceRegistry.interfaces[ifaceId]
  if entities == nil then
    InvalidInterface{ ifaceId = ifaceId }
  end
  -- grant interface
  local authorized = self.authorized
  if authorized[ifaceId] == nil then
    updateAuthorization(self.database, self.id, authorized, ifaceId, true)
    entities[self] = true
    log:admin(msg.GrantedInterfaceAddedForEntity:tag{
      entity = self.id,
      interface = ifaceId,
    })
    return true
  end
  return false
end

function Entity:revokeInterface(ifaceId)
  -- check if interface is implemented by an offer
  if self.registry.enforceAuth then
    local unauthorized = {}
    local offers = OfferRegistry.offers:get("openbus.offer.entity", self.id)
    for offer in pairs(offers) do
      for _, facet in ipairs(offer.facets) do
        if facet.interface_name == ifaceId then
          unauthorized[#unauthorized+1] = offer
        end
      end
    end
    if #unauthorized > 0 then
      AuthorizationInUse{ ifaceId = ifaceId, offers = unauthorized }
    end
  end
  -- check if interface is registered
  local entities = InterfaceRegistry.interfaces[ifaceId]
  if entities == nil then
    InvalidInterface{ ifaceId = ifaceId }
  end
  -- revoke interface
  local authorized = self.authorized
  if authorized[ifaceId] == true then
    updateAuthorization(self.database, self.id, authorized, ifaceId, nil)
    entities[self] = nil
    log:admin(msg.GrantedInterfaceRemovedFromEntity:tag{
      entity = self.id,
      interface = ifaceId,
    })
    return true
  end
  return false
end

function Entity:getGrantedInterfaces()
  local list = {}
  for spec in pairs(self.authorized) do
    list[#list+1] = spec
  end
  return list
end




local Category = class{ __type = EntityCategory }
  
function Category:__init()
  local id = self.id
  self.entities = {}
  self.ref = self -- IDL struct attribute (see operation 'describe')
  self.__objkey = "Category:"..id -- for the ORB
  self.registry.categories[id] = self
end

function Category:describe()
  return self
end
  
function Category:setName(name)
  assert(self.database:setentry(self.id, name))
  self.name = name
  log:admin(msg.EntityCategoryNameChanged:tag{category=self.id,name=name})
end

function Category:remove()
  local id = self.id
  if next(self.entities) ~= nil then
    EntityCategoryInUse{ category = id, entities = self:getEntities() }
  end
  assert(self.database:removeentry(id))
  local registry = self.registry
  registry.access.orb:deactivate(self)
  registry.categories[id] = nil
  log:admin(msg.EntityCategoryRemoved:tag{category=id})
end

function Category:removeAll()
  for id, entity in pairs(self.entities) do
    entity:remove()
  end
  self:remove()
end

function Category:registerEntity(id, name)
  if id == "" then
    BAD_PARAM{ completed = "COMPLETED_NO", minor = 0 }
  end
  local categoryId = self.id
  local registry = self.registry
  -- check if entity already exists
  local entity = registry.entities[id]
  if entity ~= nil then
    EntityAlreadyRegistered{ category = categoryId, existing = entity }
  end
  -- persist the new entity
  local database = registry.entityDB
  assert(database:setentry(id, {categoryId=categoryId, name=name}))
  -- create object for the new entity
  log:admin(msg.AuthorizedEntityRegistered:tag{entity=id,name=name})
  return Entity{
    id = id,
    name = name,
    category = self,
    registry = registry,
    database = database,
  }
end

function Category:getEntities()
  local entities = {}
  for id, entity in pairs(self.entities) do
    entities[#entities+1] = entity
  end
  return entities
end



EntityRegistry = { __type = EntityRegistryType } -- is local (see forward declaration)

function EntityRegistry:__init(data)
  -- initialize attributes
  self.access = data.access
  self.database = data.database
  self.enforceAuth = data.enforceAuth
  self.categories = {}
  self.entities = {}
  
  -- setup permissions
  local access = data.access
  local admins = data.admins
  access:setGrantedUsers(self.__type,"createEntityCategory",admins)
  access:setGrantedUsers(Category.__type,"remove",admins)
  access:setGrantedUsers(Category.__type,"removeAll",admins)
  access:setGrantedUsers(Category.__type,"setName",admins)
  access:setGrantedUsers(Category.__type,"registerEntity",admins)
  access:setGrantedUsers(Entity.__type,"remove",admins)
  access:setGrantedUsers(Entity.__type,"setName",admins)
  access:setGrantedUsers(Entity.__type,"grantInterface",admins)
  access:setGrantedUsers(Entity.__type,"revokeInterface",admins)
  
  local orb = access.orb
  local database = self.database
  -- recover all category objects
  local categoryDB = assert(database:gettable("Categories"))
  for id, name in assert(categoryDB:ientries()) do
    orb:newservant(Category{
      id = id,
      name = name,
      registry = self,
      database = categoryDB,
    })
  end
  -- recover all entity objects
  local entityDB = assert(database:gettable("Entities"))
  for id, entry in assert(entityDB:ientries()) do
    -- check if referenced category exists
    local category = self.categories[entry.categoryId]
    if category == nil then
      ServiceFailure{
        message = msg.CorruptedDatabaseDueToMissingCategory:tag{
          category = entry.category,
        },
      }
    end
    -- create the entity object
    local entry = Entity{
      id = id,
      name = entry.name,
      category = category,
      authorized = entry.authorized,
      registry = self,
      database = entityDB,
    }
    -- check if authorized interfaces exist
    local interfaces = InterfaceRegistry.interfaces
    for ifaceId in pairs(entry.authorized) do
      entities = interfaces[ifaceId]
      if entities == nil then
        ServiceFailure{
          message = msg.CorruptedDatabaseDueToMissingInterface:tag{
            interface = ifaceId,
          },
        }
      end
      entities[entry] = true
    end
    -- create object
    orb:newservant(entry)
  end
  
  self.categoryDB = categoryDB
  self.entityDB = entityDB
end

function EntityRegistry:createEntityCategory(id, name)
  if id == "" then
    BAD_PARAM{ completed = "COMPLETED_NO", minor = 0 }
  end
  local categories = self.categories
  -- check if category already exists
  local category = categories[id]
  if category ~= nil then
    EntityCategoryAlreadyExists{ category = id, existing = category }
  end
  -- persist the new category
  local database = self.categoryDB
  assert(database:setentry(id, name))
  -- create object for the new category
  log:admin(msg.EntityCategoryCreated:tag{category=id,name=name})
  return Category{
    id = id,
    name = name,
    registry = self,
    database = database,
  }
end

function EntityRegistry:getEntityCategory(id)
  return self.categories[id]
end

function EntityRegistry:getEntityCategories()
  local categories = {}
  for id, category in pairs(self.categories) do
    categories[#categories+1] = category
  end
  return categories
end

function EntityRegistry:getEntity(id)
  return self.entities[id]
end

function EntityRegistry:getEntities()
  local entities = {}
  for id, entity in pairs(self.entities) do
    entities[#entities+1] = entity
  end
  return entities
end

function EntityRegistry:getAuthorizedEntities()
  local entities = {}
  for id, entity in pairs(self.entities) do
    if next(entity.authorized) ~= nil then
      entities[#entities+1] = entity
    end
  end
  return entities
end

function EntityRegistry:getEntitiesByAuthorizedInterfaces(interfaces)
  local entities = {}
  for id, entity in pairs(self.entities) do
    for _, interface in ipairs(interfaces) do
      if entity.authorized[interface] then
        entities[#entities+1] = entity
        break
      end
    end
  end
  return entities
end



return {
  InterfaceRegistry = InterfaceRegistry,
  EntityRegistry = EntityRegistry,
  OfferRegistry = OfferRegistry,
}
