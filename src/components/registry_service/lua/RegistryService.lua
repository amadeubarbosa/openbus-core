require "uuid"

local oop = require "loop.base"
local verbose = require "Verbose"

RegistryService = oop.class{
  invalidIdentifier = "",
  entries = {},
  identifiersByType = {},
  identifiersByFacet = {},
}

function RegistryService:__init(picurrent)
  self = oop.rawnew(self, {
    picurrent = picurrent,
  })
  return self
end

function RegistryService:register(serviceOffer)
    local identifier = self:generateIdentifier()
    local credential = self.picurrent:getValue()
    local entry = {
      serviceOffer = serviceOffer,
      credential = credential,
      time = os.time()
    }
    self:addEntry(identifier, entry)
    return true, identifier
end

function RegistryService:addEntry(identifier, entry)
    self.entries[identifier] = entry
    if not self.identifiersByType[entry.serviceOffer.type] then
        self.identifiersByType[entry.serviceOffer.type] = {}
    end
    self.identifiersByType[entry.serviceOffer.type][identifier] = true
    local facetDescriptions = entry.serviceOffer.member:getFacets()
    for _, facetDescription in ipairs(facetDescriptions) do
        if not self.identifiersByFacet[facetDescription.interface_name] then
            self.identifiersByFacet[facetDescription.interface_name] = {}
        end
        self.identifiersByFacet[facetDescription.interface_name][identifier] = true
    end
end

function RegistryService:generateIdentifier()
    return uuid.new("time")
end

function RegistryService:unregister(identifier)
    local entry = self.entries[identifier]
    if not entry then
        return false
    end
    self:removeEntry(identifier, entry)
    return true
end

function RegistryService:removeEntry(identifier, entry)
    self.entries[identifier] = nil
    self.identifiersByType[entry.serviceOffer.type][identifier] = nil
    local facetDescriptions = entry.serviceOffer.member:getFacets()
    for _, facetDescription in ipairs(facetDescriptions) do
        self.identifiersByFacet[facetDescription.interface_name][identifier] = nil
    end
end

function RegistryService:refresh(identifier, serviceOffer)
    local entry = self.entries[identifier]
    if not entry then
        return false
    end
    self:removeEntry(identifier, entry)
    local newEntry = {serviceOffer = serviceOffer, credential = credential, time = os.time()}
    self:addEntry(identifier, newEntry)
    return true
end

function RegistryService:find(typeValue, criteria)
    local facets = {}
    for _, criterion in ipairs(criteria) do
       if criterion.name == "facet" then
            table.insert(facets, criterion.value)
        end
    end
    local identifiers = {}
    if self.identifiersByType[typeValue] then
        for identifier, exists in pairs(self.identifiersByType[typeValue]) do
            if exists then
                table.insert(identifiers, identifier)
            end
        end
    end
    local serviceOffers = {}
    for _, identifier in ipairs(identifiers) do
        table.insert(serviceOffers, self.entries[identifier].serviceOffer)
    end
    return serviceOffers
end

function RegistryService:credentialWasDeleted(credential)
    for identifier, entry in pairs(self.serviceOffers) do
        if entry.credential == credential then
            self:unregister(identifier)
        end
    end
end

function RegistryService:deleteOffersFromCredential(credential)
    local identifiers = {}
    for identifier, entry in pairs(self.entries) do
        if entry.credential == credential then
            table.insert(identifiers, identifier)
        end
    end
    for _, identifier in ipairs(identifiers) do
        self:unregister(identifier)
    end
end
