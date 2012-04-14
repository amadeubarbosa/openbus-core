------------------------------------------------------------------------------
-- OpenBus 1.5 Support
-- $Id: 
------------------------------------------------------------------------------

local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local pcall = _G.pcall

local idl = require "openbus.core.legacy.idl"
local throw = idl.throw.registry_service
local types = idl.types.registry_service

local newidl = require "openbus.core.idl"
local newtypes = newidl.types.services.offer_registry

local checks = require "openbus.core.services.callchecks"
local assertCaller = checks.assertCaller
local newfacets = require "openbus.core.services.OfferRegistry"

-- Faceta IRegistryService --------------------------------------------------------

local function convertProps(props)
  local properties = {}
  for _, prop in ipairs(props) do
    local name = prop.name
    for _, value in ipairs(prop.value) do
      properties[#properties+1] = { name = name, value = value }
    end
  end
  return properties
end

local IRegistryService = {
  __type = types.IRegistryService,
  __objkey = "RS_v1_05",
  __facet = "IRegistryService_v1_05",
}

function IRegistryService:register(offer)
  local registry = newfacets.OfferRegistry
  assertCaller(registry)
  local ok, result = pcall(registry.registerService, registry,
                           offer.member, convertProps(offer.properties))
  if ok then
    local orb = newfacets.OfferRegistry.access.orb
    orb:newservant(result)
    return result.id 
  end
  if result._repid ~= newtypes.UnauthorizedFacets then
    error(result)
  end
  throw.UnathorizedFacets{ facets = result.facets }
end

function IRegistryService:unregister(id)
  local registry = newfacets.OfferRegistry
  assertCaller(registry)
  local orb = registry.access.orb
  local offer = orb.ServantManager.servants:retrieve("Offer:"..id)
  return offer ~= nil and pcall(offer.remove, offer)
end

function IRegistryService:update(id, newProperties)
  local registry = newfacets.OfferRegistry
  assertCaller(registry)
  local orb = registry.access.orb
  local offer = orb.ServantManager.servants:retrieve("Offer:"..id)
  if offer == nil then
    throw.ServiceOfferNonExistent()
  else
    pcall(offer.setProperties, offer, convertProps(newProperties))
  end
end

function IRegistryService:find(facets)
  return self:findByCriteria(facets, {})
end

function IRegistryService:findByCriteria(facets, criteria)
  local registry = newfacets.OfferRegistry
  assertCaller(registry)
  local props = {}
  for _, facetname in ipairs(facets) do
    props[#props+1] = {
      name = "openbus.component.facet",
      value = facetname,
    }
  end
  for _, prop in ipairs(criteria) do
    local name = prop.name
    if name == "component_id" then
      for _, value in ipairs(prop.value) do
        if value ~= "name" then
          local name,major,minor,patch=value:match("^(.+)%:(.-)%.(.-)%.(.-)$")
          props[#props+1]={name="openbus.component.name",value=name}
          props[#props+1]={name="openbus.component.version.major",value=major}
          props[#props+1]={name="openbus.component.version.minor",value=minor}
          props[#props+1]={name="openbus.component.version.patch",value=patch}
        end
      end
    else
      if name == "registered_by" then
        name = "openbus.offer.entity"
      end
      for _, value in ipairs(prop.value) do
        props[#props+1] = { name = name, value = value }
      end
    end
  end
  local offers = registry:findServices(props)
  for index, offer in ipairs(offers) do
    local compId = {}
    local name2index = {}
    local props = {}
    for _, prop in ipairs(offer.properties) do
      local name = prop.name
      if name == "openbus.component.name" then
        compId.name = prop.value
      elseif name == "openbus.component.version.major" then
        compId.major = prop.value
      elseif name == "openbus.component.version.minor" then
        compId.minor = prop.value
      elseif name == "openbus.component.version.patch" then
        compId.patch = prop.value
      else
        if name == "openbus.offer.entity" then
          name = "registered_by"
        end
        local index = name2index[name]
        if index == nil then
          index = #props+1
          name2index[name] = index
          props[index] = { name = name, value = {} }
        end
        local value = props[index].value
        value[#value+1] = prop.value
      end
    end
    props[#props+1] = {
      name = "component_id",
      value = { "name", ("$name:$major.$minor.$patch"):tag(compId) }
    }
    offers[index] = {
      member = offer.service_ref,
      properties = props,
    }
  end
  return offers
end

function IRegistryService:localFind(facets, criteria)
  assertCaller(newfacets.OfferRegistry)
  return {}
end

-- Exported Module -----------------------------------------------------------

return {
  IRegistryService = IRegistryService,
}
