require "IComponent"

require "SessionService"

SessionServiceComponent = IComponent:new{
    startup = function(self)
        self.accessControlService = oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..self.accessControlServerKey, "IDL:OpenBus/AS/AccessControlService:1.0")

        local sessionServiceInterface = "IDL:OpenBus/SS/SessionService:1.0"
        local sessionService = SessionService:new{
            accessControlService = self.accessControlService
        }
        sessionService = oil.newobject(sessionService, sessionServiceInterface)

        self.facets[sessionServiceInterface] = sessionService
        self.facetsByName["sessionService"] = sessionService

        self.credentialLoginIdentifier = self.accessControlService:loginByCertificate("SessionService", "")

        local serviceOffer = {
            description = "Servico de Sessoes",
            type = "OpenBus/SS/SessionService",
            iComponent = self,
        }
        local registryService = self.accessControlService:getRegistryService(self.credentialLoginIdentifier.credential)
        self.identifierIdentifier = registryService:register(serviceOffer);
    end,

    shutdown = function(self)
        local registryService = self.accessControlService:getRegistryService()
        registryService:unregister(self.registryIdentifier)

        self.accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)

        self.facets = {}
        self.facetsByName = {}
    end,
}
