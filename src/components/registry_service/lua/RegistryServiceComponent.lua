require "IComponent"

require "RegistryService"

RegistryServiceComponent = IComponent:new{
    startup = function(self)
        self.accessControlService = oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..self.accessControlServerKey, "IDL:OpenBus/AS/AccessControlService:1.0")

        local registryService = RegistryService:new{accessControlService = self.accessControlService}
        local registryServiceInterface = "IDL:OpenBus/RS/RegistryService:1.0"

        registryService = oil.newobject(registryService, registryServiceInterface)

        self.facets[registryServiceInterface] = registryService
        self.facetsByName["registryService"] = registryService

        self.credentialLoginIdentifier = self.accessControlService:loginByCertificate("RegistryService", "")
        self.accessControlService:setRegistryService(self.credentialLoginIdentifier.credential, self)
    end,

    shutdown = function(self)
        self.accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)

        self.facets = {}
        self.facetsByName = {}
    end,
}
