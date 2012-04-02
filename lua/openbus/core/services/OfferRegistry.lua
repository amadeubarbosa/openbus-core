-- $Id$

local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local pcall = _G.pcall
local tostring = _G.tostring

local array = require "table"
local concat = array.concat

local os = require "os"
local date = os.date

local table = require "loop.table"
local memoize = table.memoize

local uuid = require "uuid"
local newid = uuid.new

local oo = require "openbus.util.oo"
local class = oo.class
local sysex = require "openbus.util.sysex"
local BAD_PARAM = sysex.BAD_PARAM
local log = require "openbus.util.logger"

local idl = require "openbus.core.idl"
local assert = idl.serviceAssertion
local ServiceFailure = idl.throw.services.ServiceFailure
local throw = idl.throw.services.offer_registry
local types = idl.types.services.offer_registry
local const = idl.const.services.offer_registry

local msg = require "openbus.core.services.messages"
local AccessControl = require "openbus.core.services.AccessControl"
AccessControl = AccessControl.AccessControl
local PropertyIndex = require "openbus.core.services.PropertyIndex"


local OfferRegistry -- forward declaration
local EntityRegistry -- forward declaration

local function assertRights(registry, expected)
  local callers = registry.access:getCallerChain().callers
  local originator = callers[1].entity
  local caller = callers[#callers].entity
  if (caller ~= expected and originator ~= expected) then
    local admins = registry.admins
    if (admins[caller] == nil and admins[originator] == nil) then
      sysex.NO_PERMISSION{ minor = 1234, completed = "COMPLETED_NO" }
    end
    return "admin"
  end
  return "request"
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
    ServiceFailure{message=errmsg}
  end
end

local function makePropertyList(entry, service_props)
  local props = {
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

local function observersListToPersist(observers)
  local list = {}
  for cookie, observer in pairs(observers) do
    list[cookie] = { 
      obs_ref = tostring(observer.obs_ref),
      id = observer.id,
      login = observer.login,
    }
  end
  return list
end

------------------------------------------------------------------------------
-- Faceta OfferRegistry
------------------------------------------------------------------------------

local Offer = class{ __type = types.ServiceOffer }
  
function Offer:__init()
  self.ref = self -- IDL struct attribute (see operation 'describe')
  self.__objkey = "Offer:"..self.id -- for the ORB
  self.registry.offers:add(self)
end

function Offer:describe()
  return self
end

function Offer:setProperties(properties)
  local registry = self.registry
  local tag = assertRights(registry, self.entity)
  -- try to change properties (may raise expections)
  local allprops = makePropertyList(self, properties)
  assert(self.database:setentryfield(self.id, "properties", properties))
  -- commit changes in memory
  local offers = registry.offers
  offers:remove(self)
  self.properties = allprops
  offers:add(self)
  log[tag](log, msg.UpdateOfferProperties:tag{ offer = self.id })
  self:notifyObservers("propertiesChanged")
  -- also notifies registration observers
  self.registry:notifyObservers(self)
end

function Offer:remove(tag)
  local registry = self.registry
  local tag = tag or assertRights(registry, self.entity)
  assert(self.database:removeentry(self.id))
  assert(self.orb:deactivate(self))
  registry.offers:remove(self)
  log[tag](log, msg.RemoveServiceOffer:tag{ offer = self.id })
  self:notifyObservers("removed")
end

function Offer:subscribe(observer)
  if observer == nil then
    BAD_PARAM{ completed = "COMPLETED_NO", minor = 0 }
  end
  local callers = self.registry.access:getCallerChain().callers
  local login = callers[#callers].id
  local observers = self.observers
  local cookie = #observers + 1
  -- try to include observer (may raise expections)
  local obsList = observersListToPersist(observers)
  local includeObs = {
    obs_ref = tostring(observer),
    id = cookie,
    login = login,
  }
  obsList[cookie] = includeObs
  assert(self.database:setentryfield(self.id, "observers", obsList))
  -- commit changes in memory
  includeObs.obs_ref = observer
  observers[cookie] = includeObs
  local list = self.registry.login2observer[login]
  list[#list+1] = {
    offer = self,
    observer = cookie,
  }
  return cookie
end

function Offer:unsubscribe(cookie)
  local observers = self.observers
  if observers[cookie] ~= nil then
    -- try to remove observer (may raise expections)
    local obsList = observersListToPersist(observers)
    obsList[cookie] = nil
    assert(self.database:setentryfield(self.id, "observers", obsList))
    -- commit changes in memory
    local login = observers[cookie].login
    observers[cookie] = nil
    local login2obs = self.registry.login2observer
    local list = login2obs[login]
    for idx, entry in pairs(list) do
      if entry.offer.id == self.id and entry.observer == cookie then
        list[idx] = nil
      end
    end
    return true
  end
  return false
end

function Offer:notifyObservers(event)
  local observers = self.observers
  for idx, entry in pairs(self.observers) do
    local observer = entry.obs_ref
    local ok, errmsg = pcall(observer[event], observer, self)
    if not ok then
      log:exception(msg.OfferObserverException:tag{id=idx, errmsg=errmsg})
    end
  end
end


OfferRegistry = { -- is local (see forward declaration)
  __type = types.OfferRegistry,
  __objkey = const.OfferRegistryFacet,
}

function OfferRegistry:loginRemoved(login)
  -- offer observer
  for idx, entry in pairs(self.login2observer[login.id]) do
    log:action(msg.RemoveOfferObserverAfterOwnerLogoff:tag{
      observer = entry.observer,
      offer = entry.offer.id,
      login = login.id,
    })
    entry.offer:unsubscribe(entry.observer)
  end
  self.login2observer[login.id] = nil
  -- offers
  local set = self.offers:get("openbus.offer.login", login.id)
  for offer in pairs(set) do
    log:action(msg.RemoveOfferAfterOwnerLogoff:tag{
      offer = offer.id,
      entity = login.entity,
      login = login.id,
    })
    offer:remove("action")
  end
  -- offer registry observers
  for idx, observer in pairs(self.observers) do
    if observer.login == login.id then
      log:action(msg.RemoveOfferRegistryObserverAfterOwnerLogoff:tag{
        id = observer.id,
        login = login.id,
      })
      self:unsubscribeObserver(observer.id)
    end
  end
end

function OfferRegistry:loginObserverRemoved()
  -- empty
end

function OfferRegistry:__init(data)
  self.access = data.access
  self.admins = data.admins
  self.enforceAuth = data.enforceAuth
  self.offers = PropertyIndex()
  self.offerDB = assert(data.database:gettable("Offers"))
  self.login2observer = memoize(function () return {} end)
  self.observers = {}
  self.obsIndex = PropertyIndex()
  self.registryDB = assert(data.database:gettable("RegistryObservers"))
  
  -- register itself to receive logout notifications
  rawset(AccessControl.publisher, self, self)
  
  local access = self.access
  local orb = access.orb
  local offerDB = self.offerDB
  local toberemoved = {}
  toberemoved.offers = {}
  toberemoved.observers = {}
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
      local service_ref = orb:newproxy(entry.service_ref, nil, types.OfferedService)
      entry.id = id
      entry.service_ref = service_ref
      entry.properties = makePropertyList(entry, entry.properties)
      entry.orb = orb
      entry.registry = self
      entry.database = offerDB
      if entry.observers ~= nil then
        local observers = {}
        for i, observer in pairs(entry.observers) do
          if AccessControl:getLoginEntry(observer.login) then
            log:action(msg.RecoverPersistedOfferObserver:tag{
              observer = observer.id,
              login = observer.login,
            })
            observer.obs_ref = orb:newproxy(observer.obs_ref, nil, types.OfferObserver)
            observers[observer.id] = observer
            local list = self.login2observer[observer.login]
            list[#list+1] = {
              offer = entry,
              observer = observer.id,
            }
          else
            log:action(msg.DiscardOfferObserverAfterLogout:tag{
              offer = id,
              observer = observer.id,
              login = observer.login,
            })
          end
        end
        entry.observers = observers
      end
      orb:newservant(Offer(entry))
    else
      log:action(msg.DiscardPersistedOfferAfterLogout:tag{
        offer = id,
        entity = entity,
        login = login,
      })
      toberemoved.offers[id] = true
    end
  end
  for id in pairs(toberemoved.offers) do
    offerDB:removeentry(id)
  end
  for id, entry in assert(self.registryDB:ientries()) do
    if AccessControl:getLoginEntry(entry.login) then
      log:action(msg.RecoverPersistedOfferRegistryObserver:tag{
        observer = entry.id,
        login = entry.login,
      })
      local obs_ref = orb:newproxy(entry.observer, nil, types.OfferRegistrationObserver)
      entry.observer = obs_ref
      self.observers[entry.id] = entry
      self.obsIndex:add(entry)
    else
      log:action(msg.DiscardOfferRegistryObserverAfterLogout:tag{
        observer = entry.id,
        login = entry.login,
      })
      toberemoved.observers[entry.id] = true
    end
  end
  for id in pairs(toberemoved.observers) do
    self.registryDB:removeentry(id)
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
  local callers = self.access:getCallerChain().callers
  local login = callers[#callers]
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
  local entry = {
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
  local id = newid("new")
  local database = self.offerDB
  assert(database:setentry(id, entry))
  -- create object for the new offer
  entry.id = id
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
  local theOffer = Offer(entry)
  self:notifyObservers(theOffer)
  return theOffer
end

function OfferRegistry:findServices(properties)
  return self.offers:find(properties)
end

function OfferRegistry:getServices()
  local result = {}
  for _, offers in pairs(self.offers.index["openbus.offer.login"]) do
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
  local callers = self.access:getCallerChain().callers
  local login = callers[#callers].id
  local observers = self.observers
  local cookie = #observers + 1
  -- try to include observer (may raise expections)
  local database = self.registryDB
  local entry = { 
    observer = tostring(observer),
    properties = properties,
    id = cookie,
    login = login,
  }
  assert(database:setentry(cookie, entry))
  -- commit change to memory
  entry.observer = observer
  observers[cookie] = entry
  self.obsIndex:add(entry)
  return cookie
end

function OfferRegistry:unsubscribeObserver(cookie)
  local observers = self.observers
  if observers[cookie] ~= nil then
    -- try to remove observer (may raise expections)
    local database = self.registryDB
    assert(database:removeentry(cookie))
    -- commit change to memory
    local entry = observers[cookie]
    observers[cookie] = nil
    self.obsIndex:remove(entry)
    return true
  end
  return false
end

--------------------- TODO: a ser removido ------------------------------------
-- Utilizando esse modelo de busca enquanto não encontro uma melhor solução que
-- faça uso do Inverted Index implementado em PropertyIndex
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
-------------------------------------------------------------------------------

function OfferRegistry:notifyObservers(offer)
  local observers = self.observers
  for i, entry in pairs(observers) do
    if isContained(entry.properties, offer.properties) then
      local observer = entry.observer
      local ok, errmsg = pcall(observer.offerRegistered, observer, offer)
      if not ok then
        log:exception(msg.OfferRegistrationObserverException:tag{
          id = entry.id,
          errmsg = errmsg,
        })
      end
    end
  end
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
    log:request(msg.RegisteredInterfaceAdded:tag{interface=ifaceId})
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
    log:request(msg.RegisteredInterfaceRemoved:tag{interface=ifaceId})
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
  log:request(msg.AuthorizedEntityNameChanged:tag{entity=self.id,name=name})
end

function Entity:remove()
  local id = self.id
  if self.registry.enforceAuth then
    local offers = OfferRegistry.offers:get("openbus.offer.entity", id)
    for offer in pairs(offers) do
      offer:remove()
    end
  end
  assert(self.database:removeentry(id))
  assert(self.orb:deactivate(self))
  local interfaces = InterfaceRegistry.interfaces
  for ifaceId in pairs(self.authorized) do
    interfaces[ifaceId][self] = nil
  end
  self.registry.entities[id] = nil
  self.category.entities[id] = nil
  log:request(msg.AuthorizedEntityRemoved:tag{entity=id})
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
    log:request(msg.GrantedInterfaceAddedForEntity:tag{
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
    log:request(msg.GrantedInterfaceRemovedFromEntity:tag{
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
  log:request(msg.EntityCategoryNameChanged:tag{category=self.id,name=name})
end

function Category:remove()
  if next(self.entities) ~= nil then
    throw.EntityCategoryInUse{ entities = self:getEntities() }
  end
  local id = self.id
  assert(self.database:removeentry(id))
  assert(self.orb:deactivate(self))
  self.registry.categories[id] = nil
  log:request(msg.EntityCategoryRemoved:tag{category=id})
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
  log:request(msg.AuthorizedEntityRegistered:tag{entity=id,name=name})
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
  log:request(msg.EntityCategoryCreated:tag{category=id,name=name})
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
