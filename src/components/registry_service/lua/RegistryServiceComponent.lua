require "OOP"

require "Member"

require "RegistryService"

RegistryServiceComponent = createClass(Member)

function RegistryServiceComponent:startup()
    local accessControlServiceComponent = oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..self.accessControlServerKey, "IDL:OpenBus/ACS/AccessControlServiceComponent:1.0")
    if accessControlServiceComponent:_non_existent() then
        error{"IDL:SCS/StartupFailed:1.0"}
    end
    local accessControlServiceInterface = "IDL:OpenBus/ACS/AccessControlService:1.0"
    self.accessControlService = accessControlServiceComponent:getFacet(accessControlServiceInterface)
    self.accessControlService = oil.narrow(self.accessControlService, accessControlServiceInterface)

    self.credential = self.accessControlService:loginByCertificate("RegistryService", "")

    local registryService = RegistryService:new{accessControlService = self.accessControlService}
    local registryServiceInterface = "IDL:OpenBus/RS/RegistryService:1.0"
    registryService = oil.newobject(registryService, registryServiceInterface)

    self:addFacet("registryService", registryServiceInterface, registryService)

    local credentialObserver = {registryService = registryService}
    function credentialObserver:credentialWasDeleted(credential)
        self.registryService:deleteOffersFromCredential(credential)
    end
    credentialObserver = oil.newobject(credentialObserver, "IDL:OpenBus/ACS/CredentialObserver:1.0")
    self.observerIdentifier = self.accessControlService:addObserver(credentialObserver, {})

    self.accessControlService:setRegistryService(self.credential, registryService)
end

function RegistryServiceComponent:shutdown()
    if not self.accessControlService then
        error{"IDL:SCS/ShutdownFailed:1.0"}
    end

    self.accessControlService:removeObserver(self.observerIdentifier)
    self.accessControlService:logout(self.credential)

    self.observerIdentifier = nil
    self.credential = nil
    self.accessControlService = nil

    self:removeFacets()
end
