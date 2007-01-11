require "IComponent"
require "IMetaInterface"

require "SessionService"

SessionServiceComponent = createClass(IMetaInterface, IComponent)

function SessionServiceComponent:startup()
    local accessControlServiceComponent = oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..self.accessControlServerKey, "IDL:OpenBus/AS/AccessControlServiceComponent:1.0")
    if accessControlServiceComponent:_non_existent() then
        error{"IDL:SCS/StartupFailed:1.0"}
    end
    self.accessControlService = accessControlServiceComponent:getFacet("IDL:OpenBus/AS/AccessControlService:1.0")
    self.accessControlService = oil.narrow(self.accessControlService, "IDL:OpenBus/AS/AccessControlService:1.0")

    local sessionServiceInterface = "IDL:OpenBus/SS/SessionService:1.0"
    local sessionServiceName = "sessionService"
    local sessionService = SessionService:new{
        accessControlService = self.accessControlService
    }
    sessionService = oil.newobject(sessionService, sessionServiceInterface)

    self.facets[sessionServiceInterface] = sessionService
    self.facetsByName[sessionServiceName] = sessionService
    self.facetDescriptionsByName[sessionServiceName] = {name = sessionServiceName, interface_name = sessionServiceInterface, facet_ref = sessionService}

    self.credentialLoginIdentifier = self.accessControlService:loginByCertificate("SessionService", "")

    local serviceOffer = {
        description = "Servico de Sessoes",
        type = "OpenBus/SS/SessionService",
        metaInterface = self,
    }
    local registryService = self.accessControlService:getRegistryService(self.credentialLoginIdentifier.credential)
    if not registryService then
        error{"IDL:SCS/StartupFailed:1.0"}
    end
    self.identifierIdentifier = registryService:register(self.credentialLoginIdentifier.credential, serviceOffer);
end

function SessionServiceComponent:shutdown()
    if not self.accessControlService then
        error{"IDL:SCS/ShutdownFailed:1.0"}
    end
    local registryService = self.accessControlService:getRegistryService()
    registryService:unregister(self.registryIdentifier)
    self.accessControlService:logout(self.credentialLoginIdentifier.loginIdentifier)
    self.accessControlService = nil
    self.facets = {}
    self.facetsByName = {}
    self.facetDescriptionsByName = {}
end
