require "IComponent"

require "RegistryService"

RegistryServiceComponent = IComponent:new{
    startup = function(self)
        local registryService = RegistryService:new()
        local registryServiceInterface = "IDL:OpenBus/RS/RegistryService:1.0"
        registryService = oil.newobject(registryService, registryServiceInterface)
        self.facets[registryServiceInterface] = registryService
        self.facetsByName["registryService"] = registryService

        local accessControlService = self:getAccessControlService()

        self.credentialResource = accessControlService:login()
    end,

    shutdown = function(self)
        local accessControlService = self:getAccessControlService()
        accessControlService:logout(self.credentialResource:getIdentifier())

        self.facets = {}
        self.facetsByName = {}
    end,

    getAccessControlService = function(self)
    end,
}
