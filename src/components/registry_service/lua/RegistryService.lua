require "uuid"

require "OOP"

RegistryService = createClass()

RegistryService.invalidIdentifier = ""
RegistryService.entries = {}
RegistryService.entriesByType = {}

function RegistryService:register(credential, serviceOffer)
    if not self.accessControlService:isValid(credential) then
        return self.invalidIdentifier
    end
    local identifier = self:generateIdentifier()
    local entry = {serviceOffer = serviceOffer, credential = credential, time = os.time()}
    self:addEntry(identifier, entry)
    return identifier
end

function RegistryService:addEntry(identifier, entry)
    self.entries[identifier] = entry
    if not self.entriesByType[entry.serviceOffer.type] then
        self.entriesByType[entry.serviceOffer.type] = {}
    end
    table.insert(self.entriesByType[entry.serviceOffer.type], identifier) 
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
    local identifierIndex
    for index, cachedIdentifier in ipairs(self.entriesByType[entry.servieOffer.type]) do
        if identifier == cachedIdentifier then
            identifierIndex = index
            break
        end
    end
    table.remove(self.entriesByType[entry.serviceOffer.type], identifierIndex)
    if #(self.entriesByType[entry.serviceOffer.type]) == 0 then
        self.entriesByType[entry.serviceOffer.type] = nil
    end
    self.entries[identifier] = nil
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

function RegistryService:find(criteria, type)
    if not self.entriesByType[type] then
        return nil
    end
    local identifier = self.entriesByType[type][1]
    if not identifier then
        return nil
    end
    return self.entries[identifier].serviceOffer.metaInterface
end

function RegistryService:credentialWasDeleted(credential)
    for identifier, entry in pairs(self.serviceOffers) do
        if entry.credential == credential then
            self:unregister(identifier)
        end
    end
end
