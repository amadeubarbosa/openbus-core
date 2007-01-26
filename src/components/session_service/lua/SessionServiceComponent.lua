require "OOP"

require "Member"

require "SessionService"

SessionServiceComponent = createClass(Member)

function SessionServiceComponent:startup()
    local accessControlServiceComponent = oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..self.accessControlServerKey, "IDL:OpenBus/ACS/AccessControlServiceComponent:1.0")
    if accessControlServiceComponent:_non_existent() then
        error{"IDL:SCS/StartupFailed:1.0"}
    end
    local accessControlServiceInterface = "IDL:OpenBus/ACS/AccessControlService:1.0"
    self.accessControlService = accessControlServiceComponent:getFacet(accessControlServiceInterface)
    self.accessControlService = oil.narrow(self.accessControlService, accessControlServiceInterface)

    local sessionServiceInterface = "IDL:OpenBus/SS/SessionService:1.0"
    local sessionService = SessionService:new{
        accessControlService = self.accessControlService
    }
    sessionService = oil.newobject(sessionService, sessionServiceInterface)

    self:addFacet("sessionService", sessionServiceInterface, sessionService)

    self.credential = self.accessControlService:loginByCertificate("SessionService", "")
    local serviceOffer = {
        description = "Servico de Sessoes",
        type = "OpenBus/SS/SessionService",
        member = self,
    }
    local registryService = self.accessControlService:getRegistryService(self.credential)
    if not registryService then
        error{"IDL:SCS/StartupFailed:1.0"}
    end
    self.registryIdentifier = registryService:register(self.credential, serviceOffer);
end

function SessionServiceComponent:shutdown()
    if not self.accessControlService then
        error{"IDL:SCS/ShutdownFailed:1.0"}
    end
    local registryService = self.accessControlService:getRegistryService(self.credential)
    registryService:unregister(self.registryIdentifier)
    self.accessControlService:logout(self.credential)
    self.accessControlService = nil

    self:removeFacets()
end
