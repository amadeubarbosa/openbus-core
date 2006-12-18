require "IComponent"

require "SessionService"

SessionServiceComponent = IComponent:new{
    startup = function(self)
        local sessionService = SessionService:new()
        local sessionServiceInterface = "IDL:OpenBus/SS/SessionService:1.0"
        sessionService = oil.newobject(sessionService, sessionServiceInterface)
        self.facets[sessionServiceInterface] = sessionService
        self.facetsByName["sessionService"] = sessionService

        local accessControlService = self:getAccessControlService()
        self.credentialResource = accessControlService:login()

        local serviceOffer = {
            description = "Serviço de Sessões",
            type = "OpenBus/SS/SessionService",
            iComponent = self,
        }
        local registryService = accessControlService:getRegistryService()
        self.identifierResource = registryService:register(serviceOffer);
    end,

    shutdown = function(self)
        local accessControlService = self:getAccessControlService()
        local registryService = accessControlService:getRegistryService()
        registryService:unregister(self.identifierResource:getIdentifier())

        accessControlService:logout(self.credentialResource:getIdentifier())

        self.facets = {}
        self.facetsByName = {}
    end,

    getAccessControlService = function(self)
    end,
}
