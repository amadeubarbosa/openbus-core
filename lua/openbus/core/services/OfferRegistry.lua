-- $Id$

local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local pcall = _G.pcall
local rawget = _G.rawget
local tostring = _G.tostring

local array = require "table"
local concat = array.concat

local os = require "os"
local date = os.date

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

local idl = require "openbus.core.idl"
local assert = idl.serviceAssertion
local srvex = idl.throw.services
local throw = idl.throw.services.offer_registry
local types = idl.types.services.offer_registry
local const = idl.const.services.offer_registry

local msg = require "openbus.core.services.messages"
local checks = require "openbus.core.services.callchecks"
local getCaller = checks.getCaller
local AccessControl = require "openbus.core.services.AccessControl"
AccessControl = AccessControl.AccessControl
local PropertyIndex = require "openbus.core.services.PropertyIndex"


local OfferRegistry -- forward declaration
local EntityRegistry -- forward declaration

local function assertCaller(self, owner)
  local caller = getCaller(self)
  local entity = caller.entity
  local logtag
  if entity == owner then
    logtag = "request"
  elseif self.admins[entity] ~= nil then
    logtag = "admin"
  else
    srvex.UnauthorizedOperation()
  end
  return logtag
end

local function ifaceId2Key(ifaceId)
  local name, version = ifaceId:match("^IDL:(.-):(%d+%.%d+)$")
  if name == nil then
    throw.InvalidInterface{ ifaceId = ifaceId }
  end
  return name:gsub("/", ".").."-"..version
end

local function updateAuthorization(db, id, set, spec, value)
  local backup = set[spec]
  set[spec] = value
  local ok, errmsg = db:setentryfield(id, "authorized", set)
  if not ok then
    set[spec] = backup
    srvex.ServiceFailure{message=errmsg}
  end
end

local function makePropertyList(entry, service_props)
  local props = {
    { name = "openbus.offer.id", value = entry.id },
    { name = "openbus.offer.login", value = entry.login },
    { name = "openbus.offer.entity", value = entry.entity },
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
    if prop.name:find("openbus", 1, true) == 1 then
      illegal[#illegal+1] = prop
    else
      props[#props+1] = prop
    end
  end
  if #illegal > 0 then
    throw.InvalidProperties{ properties = illegal }
  end
  return props
end

local function registerObserver(self, watched, cookie, entry)
  local login = entry.login
  watched.observers[cookie] = login
  self.observerLogins[login][watched][cookie] = entry
end

local function unregisterObserver(self, watched, cookie)
  local observers = watched.observers
  local login = observers[cookie]
  observers[cookie] = nil
  return delautotab(self.observerLogins, login, watched, cookie)
end

local function callObservers(self, watched, op, ...)
  local observerLogins = self.observerLogins
  -- during notification (remote call) some new observers may be subscribed,
  -- so the iteration of 'pairs' will be corrupted. Therefore the notification
  -- first collect all observers to be notified and later notify them.
  local entries = {}
  for cookie, login in pairs(watched.observers) do
    entries[cookie] = observerLogins[login][watched][cookie]
  end
  for cookie, entry in pairs(entries) do
    -- check if observer is still subscribed, because it might have been
    -- unsubscribed during the previous notification.
    if getautotab(observerLogins, entry.login, watched, cookie) == entry then
      local observer = entry.observer
      local ok, errmsg = pcall(observer[op], observer, ...)
      if not ok then
        log:exception(msg.OfferObserverException:tag{id=idx, errmsg=errmsg})
      end
    end
  end
end

------------------------------------------------------------------------------
-- Faceta OfferRegistry
------------------------------------------------------------------------------

local Offer = class{ __type = types.ServiceOffer }
  
function Offer:__init()
  self.ref = self -- IDL struct attribute (see operation 'describe')
  self.__objkey = "Offer:"..self.id -- for the ORB
  local registry = self.registry
  registry.offers:add(self)
  -- recover observers
  local persistedObs = self.observers -- backup observer persisted entries
  self.observers = {} -- this table will contain entries in memory only
                      -- which is filled by operation 'registerObserver'
  local orb = self.orb
  for cookie, entry in pairs(persistedObs) do
    local login = entry.login
    if AccessControl:getLoginEntry(login) then
      log:action(msg.RecoverPersistedOfferObserver:tag{
        login = login,
        offer = self.id,
        cookie = cookie,
      })
      entry.observer = orb:newproxy(entry.observer, nil, types.OfferObserver)
      registerObserver(registry, self, cookie, entry)
    else
      log:action(msg.DiscardOfferObserverAfterLogout:tag{
        login = login,
        offer = self.id,
        cookie = cookie,
      })
      persistedObs[cookie] = nil
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
  callObservers(registry, self, "propertiesChanged", self)
  registry:notifyRegistryObservers(self)
end

function Offer:remove(tag)
  local registry = self.registry
  local tag = tag or assertCaller(registry, self.entity)
  -- try to remove persisted offer (may raise expections)
  assert(self.database:removeentry(self.id))
  -- commit changes in memory
  self.orb:deactivate(self)
  registry.offers:remove(self)
  log[tag](log, msg.RemoveServiceOffer:tag{ offer = self.id })
  -- notify observers and unregister them from the logout callback
  callObservers(registry, self, "removed", self)
  for cookie in pairs(self.observers) do
    unregisterObserver(registry, self, cookie)
  end
end

function Offer:subscribeObserver(observer)
  if observer == nil then
    sysex.BAD_PARAM{ completed = "COMPLETED_NO", minor = 0 }
  end
  local registry = self.registry
  local id = self.id
  local login = getCaller(registry).id
  local entry = {
    login = login,
    observer = tostring(observer),
  }
  local cookie = #self.observers + 1
  -- try to persist observer (may raise expections)
  assert(self.database:setentryfield(id, "observers", cookie, entry))
  -- commit changes in memory
  entry.observer = observer
  registerObserver(registry, self, cookie, entry)
  log:request(msg.SubscribeOfferObserver:tag{
    login = login,
    offer = id,
    cookie = cookie,
  })
  return cookie
end

function Offer:unsubscribeObserver(cookie)
  local id = self.id
  if self.observers[cookie] ~= nil then
    -- try to remove persisted observer (may raise expections)
    assert(self.database:setentryfield(id, "observers", cookie, nil))
    -- commit changes in memory
    local entry = unregisterObserver(self.registry, self, cookie)
    log:request(msg.UnsubscribeOfferObserver:tag{
      login = entry.login,
      offer = id,
      cookie = cookie,
    })
    return true
  end
  log:exception(msg.UnableToUnsubscribeInexistentOfferObserver:tag{
    offer = id,
    cookie = cookie,
  })
  return false
end


OfferRegistry = { -- is local (see forward declaration)
  __type = types.OfferRegistry,
  __objkey = const.OfferRegistryFacet,
}

function OfferRegistry:loginRemoved(login)
  do -- observers
    local watchedMap = rawget(self.observerLogins, login.id)
    if watchedMap ~= nil then
      for watched, cookies in pairs(watchedMap) do
        for cookie in pairs(cookies) do
          watched:unsubscribeObserver(cookie)
        end
      end
    end
  end
  do -- offers
    for offer in pairs(self.offers:get("openbus.offer.login", login.id)) do
      log:action(msg.RemoveOfferAfterOwnerLogoff:tag{
        offer = offer.id,
        entity = login.entity,
        login = login.id,
      })
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
  -- during notification (remote call) some new observers may be subscribed,
  -- so the iteration of 'pairs' will be corrupted. Therefore the notification
  -- first collect all observers to be notified and later notify them.
  local selected = {}
  for cookie, login in pairs(self.observers) do
    local entry = observerLogins[login][self][cookie]
    local matched
    for _, prop in ipairs(entry.properties) do
      matched = offers:get(prop.name, prop.value)[offer]
      if not matched then break end
    end
    if matched then
      selected[cookie] = entry.observer
    end
  end
  for cookie, observer in pairs(selected) do
    local ok, errmsg = pcall(observer.offerRegistered, observer, offer)
    if not ok then
      log:exception(msg.OfferRegistrationObserverException:tag{
        cookie = cookie,
        errmsg = errmsg,
      })
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
  rawset(AccessControl.publisher, self, self)
  
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
                                         types.OfferedService)
        entry.properties = makePropertyList(entry, entry.properties)
        entry.orb = orb
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
    local offers = self.offers
    local offerRegObsDB = self.offerRegObsDB
    local toberemoved = {}
    for cookie, entry in assert(offerRegObsDB:ientries()) do
      local login = entry.login
      if AccessControl:getLoginEntry(login) then
        log:action(msg.RecoverPersistedOfferRegistryObserver:tag{
          cookie = cookie,
          login = login,
        })
        entry.observer = orb:newproxy(entry.observer, nil,
                                      types.OfferRegistrationObserver)
        registerObserver(self, self, cookie, entry)
      else
        log:action(msg.DiscardOfferRegistryObserverAfterLogout:tag{
          cookie = cookie,
          login = login,
        })
        toberemoved[cookie] = true
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
    throw.InvalidService()
  end
  -- collect information about the SCS component implementing the service
  local compId = service_ref:getComponentId()
  local meta = service_ref:getFacetByName("IMetaInterface")
  if meta == nil then
    throw.InvalidService()
  end
  local allfacets = meta:__narrow("scs::core::IMetaInterface"):getFacets()
  local facets = {}
  for _, facet in ipairs(allfacets) do
    local facetname = facet.name
    if IgnoredFacets[facetname] == nil then
      facets[#facets+1] = {
        name = facetname,
        interface_name = facet.interface_name,
      }
    end
  end
  -- get information about the caller
  local login = getCaller(self)
  local entityId = login.entity
  -- check the caller is authorized to offer such service
  if self.enforceAuth then
    local entity = EntityRegistry:getEntity(entityId)
    local unauthorized = {}
    for _, facet in ipairs(facets) do
      if entity==nil or entity.authorized[facet.interface_name]==nil then
        unauthorized[#unauthorized+1] = facet.name
      end
    end
    if #unauthorized > 0 then
      throw.UnauthorizedFacets{
        entity = entityId,
        facets = unauthorized,
      }
    end
  end
  -- validate provided properties
  local id = newid("new")
  local entry = {
    id = id,
    service_ref = tostring(service_ref),
    entity = entityId,
    login = login.id,
    creation = {
      day = date("%d"),
      month = date("%m"),
      year = date("%Y"),
      hour = date("%H"),
      minute = date("%M"),
      second = date("%S"),
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
  entry.orb = self.access.orb
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

function OfferRegistry:getServices()
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
    sysex.BAD_PARAM{ completed = "COMPLETED_NO", minor = 0 }
  end
  local login = getCaller(self).id
  local observers = self.observers
  local cookie = #observers + 1
  local entry = { 
    login = login,
    properties = properties,
    observer = tostring(observer),
  }
  -- try to persist observer (may raise expections)
  assert(self.offerRegObsDB:setentry(cookie, entry))
  -- commit change to memory
  entry.observer = observer
  registerObserver(self, self, cookie, entry)
  log:request(msg.SubscribeOfferRegistryObserver:tag{
    login = login,
    cookie = cookie,
  })
  return cookie
end

function OfferRegistry:unsubscribeObserver(cookie)
  if self.observers[cookie] ~= nil then
    -- try to remove persisted observer (may raise expections)
    assert(self.offerRegObsDB:removeentry(cookie))
    -- commit change to memory
    local entry = unregisterObserver(self, self, cookie)
    log:request(msg.UnsubscribeOfferRegistryObserver:tag{
      login = entry.login,
      cookie = cookie,
    })
    return true
  end
  log:exception(msg.UnableToUnsubscribeInexistentOfferRegistryObserver:tag{
    cookie = cookie,
  })
  return false
end

------------------------------------------------------------------------------
-- Faceta InterfaceRegistry
------------------------------------------------------------------------------

local InterfaceRegistry = {
  __type = types.InterfaceRegistry,
  __objkey = const.InterfaceRegistryFacet,
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
      throw.InterfaceInUse{ entities = list }
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

local IgnoredFacets = {
  IComponent = true,
  IMetaInterface = true,
  IReceptacles = true,
}

local Entity = class{ __type = types.RegisteredEntity }

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
  self.orb:deactivate(self)
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
    throw.InvalidInterface{ ifaceId = ifaceId }
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
      for facet in ipairs(offer.facets) do
        if facet.interface_name == ifaceId then
          unauthorized[#unauthorized+1] = offer
        end
      end
    end
    if #unauthorized > 0 then
      throw.AuthorizationInUse{ offers = unauthorized }
    end
  end
  -- check if interface is registered
  local entities = InterfaceRegistry.interfaces[ifaceId]
  if entities == nil then
    throw.InvalidInterface{ ifaceId = ifaceId }
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




local Category = class{ __type = types.EntityCategory }
  
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
  if next(self.entities) ~= nil then
    throw.EntityCategoryInUse{ entities = self:getEntities() }
  end
  local id = self.id
  assert(self.database:removeentry(id))
  self.orb:deactivate(self)
  self.registry.categories[id] = nil
  log:admin(msg.EntityCategoryRemoved:tag{category=id})
end

function Category:removeAll()
  for id, entity in pairs(self.entities) do
    entity:remove()
  end
  self:remove()
end

function Category:registerEntity(id, name)
  local entities = self.entities
  -- check if category already exists
  local entity = entities[id]
  if entity ~= nil then
    throw.EntityAlreadyRegistered{ existing = entity }
  end
  -- persist the new entity
  local registry = self.registry
  local categoryId = self.id
  local database = registry.entityDB
  assert(database:setentry(id, {categoryId=categoryId, name=name}))
  -- create object for the new entity
  log:admin(msg.AuthorizedEntityRegistered:tag{entity=id,name=name})
  return Entity{
    id = id,
    name = name,
    category = self,
    orb = self.orb,
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



EntityRegistry = { -- is local (see forward declaration)
  __type = types.EntityRegistry,
  __objkey = const.EntityRegistryFacet,
}

function EntityRegistry:__init(data)
  -- initialize attributes
  self.orb = data.access.orb
  self.database = data.database
  self.enforceAuth = data.enforceAuth
  self.categories = {}
  self.entities = {}
  
  -- setup permissions
  local access = data.access
  local admins = data.admins
  access:setGrantedUsers(self.__type,"createEntityCategory",admins)
  access:setGrantedUsers(Category.__type,"remove",admins)
  access:setGrantedUsers(Category.__type,"setName",admins)
  access:setGrantedUsers(Category.__type,"registerEntity",admins)
  access:setGrantedUsers(Entity.__type,"remove",admins)
  access:setGrantedUsers(Entity.__type,"setName",admins)
  access:setGrantedUsers(Entity.__type,"addAuthorization",admins)
  access:setGrantedUsers(Entity.__type,"removeAuthorization",admins)
  
  local orb = self.orb
  local database = self.database
  -- recover all category objects
  local categoryDB = assert(database:gettable("Categories"))
  for id, name in assert(categoryDB:ientries()) do
    orb:newservant(Category{
      id = id,
      name = name,
      orb = orb,
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
      orb = orb,
      registry = self,
      database = entityDB,
    }
    -- check if authorized interfaces exist
    local interfaces = InterfaceRegistry.interfaces
    for ifaceId in pairs(entry.authorized) do
      if interfaces[ifaceId] == nil then
        ServiceFailure{
          message = msg.CorruptedDatabaseDueToMissingInterface:tag{
            interface = ifaceId,
          },
        }
      end
    end
    -- create object
    orb:newservant(entry)
  end
  
  self.categoryDB = categoryDB
  self.entityDB = entityDB
end

function EntityRegistry:createEntityCategory(id, name)
  local categories = self.categories
  -- check if category already exists
  local category = categories[id]
  if category ~= nil then
    throw.EntityCategoryAlreadyExists{ existing = category }
  end
  -- persist the new category
  local database = self.categoryDB
  assert(database:setentry(id, name))
  -- create object for the new category
  log:admin(msg.EntityCategoryCreated:tag{category=id,name=name})
  return Category{
    id = id,
    name = name,
    orb = self.orb,
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
