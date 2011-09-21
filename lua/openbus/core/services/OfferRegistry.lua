-- $Id$

local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local pcall = _G.pcall
local tostring = _G.tostring

local os = require "os"
local date = os.date

local uuid = require "uuid"
local newid = uuid.new

local oo = require "openbus.util.oo"
local class = oo.class
local sysex = require "openbus.util.sysex"
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
local OfferIndex = require "openbus.core.services.OfferIndex"


local function assertRights(registry, expected)
	local chain = registry.access:getCallerChain()
	local originator = chain[1].entity
	local caller = chain[#chain].entity
	if (caller ~= expected and originator ~= expected) then
		local admins = registry.admins
		if (admins[caller] == nil and admins[originator] == nil) then
			sysex.NO_PERMISSION{ completed = "NO" }
		end
		return "admin"
	end
	return "request"
end

local function versionPattern(capture)
	if capture == "*" then
		return "%d+"
	elseif capture:find("*", 1, true) == nil then
		return capture
	end
	throw.InvalidAuthorization()
end

local function authorizationPattern(spec)
	local name, version = spec:match("^IDL:([%w_*][%w_/*]*):([%d.*]+)$")
	if name == nil then
		throw.InvalidAuthorization()
	end
	local pos = name:find("*", 1, true)
	if pos == #name then
		name = name:gsub("%*$", "[%w_/]*")
	elseif pos ~= nil then
		throw.InvalidAuthorization()
	end
	if version == "*" then
		version = "%d+%.%d+"
	else
		local major, minor = version:match("^([%d*]+)%.([%d*]+)$")
		if major == nil then
			throw.InvalidAuthorization()
		end
		version = versionPattern(major).."%."..versionPattern(minor)
	end
	return "^IDL:"..name..":"..version.."$"
end

local function updateAuthorization(id, authorizations, db, spec, pattern)
	local backup = authorizations[spec]
	authorizations[spec] = pattern
	local ok, errmsg = db:setentryfield(id, "authorizations", authorizations)
	if not ok then
		authorizations[spec] = backup
		ServiceFailure{message=errmsg}
	end
end

local function makePropertyList(entry, service_props)
	local props = {
		{ name = "openbus.offer.login", value = entry.login },
		{ name = "openbus.offer.entity", value = entry.entity.id },
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
		throw.IllegalProperties{ properties = illegal }
	end
	return props
end

local function getUnauthorizedOffers(entity, removedspec)
	local unauthorized = {}
	for offer in pairs(entity.offers) do
		for facet in ipairs(offer.facets) do
			if not entity:hasAuthorization(facet.interface_name, removedspec) then
				unauthorized[#unauthorized+1] = offer
			end
		end
	end
	return unauthorized
end

------------------------------------------------------------------------------
-- Faceta OfferRegistry
------------------------------------------------------------------------------

local EntityRegistry -- forward declaration



local Offer = class{ __type = types.ServiceOffer }
	
function Offer:__init()
	self.ref = self -- IDL struct attribute (see operation 'describe')
	self.__objkey = "Offer:"..self.id -- for the ORB
	self.registry.offers:add(self)
	self.entity.offers[self] = true
end

function Offer:describe()
	return self
end

function Offer:setProperties(properties)
	local registry = self.registry
	local tag = assertRights(registry, self.entity.id)
	-- try to change properties (may raise expections)
	local allprops = makePropertyList(self, properties)
	assert(self.database:setentryfield(self.id, "properties", properties))
	-- commit changes in memory
	self.properties = allprops
	log[tag](log, msg.UpdateOfferProperties:tag{ offer = self.id })
end

function Offer:remove(tag)
	local registry = self.registry
	local tag = tag or assertRights(registry, self.entity.id)
	assert(self.database:removeentry(self.id))
	assert(self.orb:deactivate(self))
	registry.offers:remove(self)
	self.entity.offers[self] = nil
	log[tag](log, msg.RemoveServiceOffer:tag{ offer = self.id })
end



local OfferRegistry = {
	__type = types.OfferRegistry,
	__objkey = const.OfferRegistryFacet,
}

function OfferRegistry:loginRemoved(login)
	local set = self.offers.index["openbus.offer.login"][login.id]
	for offer in pairs(set) do
		log:action(msg.RemoveOfferAfterOwnerLogoff:tag{
			offer = offer.id,
			entity = login.entity,
			login = login.id,
		})
		offer:remove("action")
	end
end

function OfferRegistry:__init(data)
	local access = data.access
	self.access = access
	self.offers = OfferIndex()
	self.offerDB = assert(data.database:gettable("Offers"))
	
	-- register itself to receive logout notifications
	rawset(AccessControl.publisher, self, self)
	
	local orb = access.orb
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
			entity = EntityRegistry:getEntity(entity)
			if entity == nil then
				ServiceFailure{
					message = msg.CorruptedDatabaseDueToMissingEntity:tag{
						entity = entry.entity,
					}
				}
			end
			-- create object for the new offer
			local service_ref = orb:newproxy(entry.service_ref, nil, types.OfferedService)
			entry.id = id
			entry.service_ref = service_ref
			entry.entity = entity
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

local IgnoredFacets = {
	IComponent = true,
	IMetaInterface = true,
	IReceptacles = true,
}

function OfferRegistry:registerService(service_ref, properties)
	-- collect information about the SCS component implementing the service
	local compId = service_ref:getComponentId()
	local meta = service_ref:getFacetByName("IMetaInterface")
	local allfacets = meta == nil and {} or
	                  meta:__narrow("scs::core::IMetaInterface"):getFacets()
	-- check the caller is authorized to offer such service
	local chain = self.access:getCallerChain()
	local login = chain[#chain]
	entity = EntityRegistry:getEntity(login.entity)
	local facets = {}
	local unauthorized = {}
	for _, facet in ipairs(allfacets) do
		local facetname = facet.name
		local facetiface = facet.interface_name
		if IgnoredFacets[facetname] == nil then
			if entity~= nil and entity:hasAuthorization(facetiface) then
				facets[#facets+1] = {
					name = facetname,
					interface_name = facetiface,
				}
			else
				unauthorized[#unauthorized+1] = facetname
			end
		end
	end
	if #unauthorized > 0 then
		throw.UnauthorizedFacets{ facets = unauthorized }
	end
	-- validate provided properties
	local entry = {
		service_ref = tostring(service_ref),
		entity = entity.id,
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
	}
	-- persist the new offer
	local id = newid("new")
	local database = self.offerDB
	assert(database:setentry(id, entry))
	-- create object for the new offer
	entry.id = id
	entry.service_ref = service_ref
	entry.entity = entity
	entry.properties = makePropertyList(entry, properties)
	entry.orb = self.access.orb
	entry.registry = self
	entry.database = database
	log:request(msg.RegisterServiceOffer:tag{
		offer = id,
		entity = entity.id,
		login = login.id,
	})
	return Offer(entry)
end

function OfferRegistry:findServices(properties)
	return self.offers:find(properties)
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
	self.authorizations = self.authorizations or {}
	self.offers = {}
	self.ref = self -- IDL struct attribute (see operation 'describe')
	self.__objkey = "Entity:"..id -- for the ORB
	self.registry.entities[id] = self
	self.category.entities[id] = self
end

function Entity:hasAuthorization(interface, ignored)
	for spec, pattern in pairs(self.authorizations) do
		if spec ~= ignored then
			if interface:match(pattern) then
				return true
			end
		end
	end
	return false
end

function Entity:describe()
	return self
end

function Entity:setName(name)
	assert(self.database:setentryfield(self.id, "name", name))
	self.name = name
end

function Entity:remove()
	local id = self.id
	OfferRegistry:removeAuthorizationsOf(id)
	assert(self.database:removeentry(id))
	assert(self.orb:deactivate(self))
	self.registry.entities[id] = nil
	self.category.entities[id] = nil
end

function Entity:addAuthorization(spec)
	local pattern = authorizationPattern(spec)
	updateAuthorization(self.id, self.authorizations, self.database, spec, pattern)
end

function Entity:removeAuthorization(spec)
	local unauthorized = getUnauthorizedOffers(self, spec)
	if #unauthorized > 0 then
		throw.AuthorizationInUse{ offers = unauthorized }
	end
	updateAuthorization(self.id, self.authorizations, self.database, spec, nil)
end

function Entity:removeAuthorizationAndOffers(spec)
	local unauthorized = getUnauthorizedOffers(self, spec)
	for _, offer in ipairs(unauthorized) do
		offer:remove()
	end
	updateAuthorization(self.id, self.authorizations, self.database, spec, nil)
end

function Entity:removeAllAuthorizationsAndOffers()
	for spec in pairs(self.authorizations) do
		self:removeAuthorizationAndOffers(spec)
	end
end

function Entity:getAuthorizationSpecs()
	local list = {}
	for spec in pairs(self.authorizations) do
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
end

function Category:remove()
	if next(self.entities) ~= nil then
		throw.EntityCategoryInUse{ entities = self:getEntities() }
	end
	local id = self.id
	assert(self.database:removeentry(id))
	assert(self.orb:deactivate(self))
	self.registry.categories[id] = nil
end

function Category:removeAll()
	for id, entity in self.iEntities() do
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
	self.admins = data.admins
	self.categories = {}
	self.entities = {}
	
	-- setup permissions
	local access = data.access
	local admins = self.admins
	access:setGrantedUsers(self.__type,"createEntityCategory",admins)
	access:setGrantedUsers(Category.__type,"remove",admins)
	access:setGrantedUsers(Category.__type,"setName",admins)
	access:setGrantedUsers(Category.__type,"registerEntity",admins)
	access:setGrantedUsers(Entity.__type,"remove",admins)
	access:setGrantedUsers(Entity.__type,"setName",admins)
	access:setGrantedUsers(Entity.__type,"addAuthorization",admins)
	access:setGrantedUsers(Entity.__type,"removeAuthorization",admins)
	access:setGrantedUsers(Entity.__type,"removeAuthorizationAndOffers",admins)
	access:setGrantedUsers(Entity.__type,"removeAllAuthorizationAndOffers",admins)
	
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
		-- check is referenced category exists
		local category = self.categories[entry.categoryId]
		if category == nil then
			ServiceFailure{
				message = msg.CorruptedDatabaseDueToMissingCategory:tag{
					category = entry.category,
				},
			}
		end
		-- create object
		orb:newservant(Entity{
			id = id,
			name = entry.name,
			category = category,
			authorizations = entry.authorizations,
			orb = orb,
			registry = self,
			database = entityDB,
		})
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
		if next(entity.authorizations) ~= nil then
			entities[#entities+1] = entity
		end
	end
	return entities
end

function EntityRegistry:getEntitiesByAuthorizedInterfaces(interfaces)
	local entities = {}
	for id, entity in pairs(self.entities) do
		local exclude
		for _, interface in ipairs(interfaces) do
			if not entity:hasAuthorization(interface) then
				exclude = true
				break
			end
		end
		if not exclude then
			entities[#entities+1] = entity
		end
	end
	return entities
end



return {
	EntityRegistry = EntityRegistry,
	OfferRegistry = OfferRegistry,
}
