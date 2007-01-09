require "IComponent"

require "RegistryService"

RegistryServiceComponent = createClass(IComponent)

function RegistryServiceComponent:startup()
    
    local accessControlServiceComponent = oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..self.accessControlServerKey, "IDL:OpenBus/AS/AccessControlServiceComponent:1.0")

    local accessControlServiceInterface = "IDL:OpenBus/AS/AccessControlService:1.0"
    self.accessControlService = accessControlServiceComponent:getFacet(accessControlServiceInterface)
    self.accessControlService = oil.narrow(self.accessControlService, accessControlServiceInterface)

    local registryService = RegistryService:new{accessControlService = self.accessControlService}
    local registryServiceInterface = "IDL:OpenBus/RS/RegistryService:1.0"

    registryService = oil.newobject(registryService, registryServiceInterface)

    self.facets[registryServiceInterface] = registryService
    self.facetsByName["registryService"] = registryService

    self.credentialLoginIdentifier = self.accessControlService:loginByCertificate("RegistryService", "")
    self.accessControlService:setRegistryService(self.credentialLoginIdentifier.credential, registryService)
end

function RegistryServiceComponent:shutdown()
    self.accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)

    self.facets = {}
    self.facetsByName = {}
end
