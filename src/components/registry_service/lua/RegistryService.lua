require "uuid"

require "OOP"

RegistryService = Object:new {
    serviceOffers = {},

    start = function(self)
    end,

    register = function(self, serviceOffer)
        local identifier = self:generateIdentifier()
        self.serviceOffers[identifier] = {offer = serviceOffer, time = os.gettime()}
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
    end,

    removeDeadServiceOffers = function(self)
    end,
};
