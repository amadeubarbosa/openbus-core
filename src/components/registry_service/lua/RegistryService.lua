require "uuid"

require "OOP"

RegistryService = Object:new {
    serviceOffers = {},

    register = function(self, serviceOffer)
        local identifier = self:generateIdentifier()
        self.serviceOffers[identifier] = serviceOffer
        return identifier
    end,

    unregister = function(self, identifier)
        local serviceOffer = self.serviceOffers[identifier]
        if serviceOffer == nil then
            return false
        end
        self.serviceOffers[identifier] = nil
        return true
    end,

    refresh = function(self, identifier, serviceOffer)
        local serviceOffer = self.serviceOffers[identifier]
        if serviceOffer == nil then
            return false
        end
        self.serviceOffers[identifier] = serviceOffer
        return true
    end,

    find = function(self, criteria)
    end,

    generateIdentifier = function(self)
        return uuid.new("time")
    end
};
