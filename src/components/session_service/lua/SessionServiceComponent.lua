require "Member"

require "SessionService"

local oop = require "loop.simple"

SessionServiceComponent = oop.class({}, Member)

function SessionServiceComponent:startup()
    local accessControlServiceComponent = oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..self.accessControlServerKey, "IDL:OpenBus/ACS/IAccessControlServiceComponent:1.0")
    if accessControlServiceComponent:_non_existent() then
        error{"IDL:SCS/StartupFailed:1.0"}
    end
    local accessControlServiceInterface = "IDL:OpenBus/ACS/IAccessControlService:1.0"
    self.accessControlService = accessControlServiceComponent:getFacet(accessControlServiceInterface)
    self.accessControlService = oil.narrow(self.accessControlService, accessControlServiceInterface)

    local sessionServiceInterface = "IDL:OpenBus/SS/ISessionService:1.0"
    local sessionService = SessionService{
        accessControlService = self.accessControlService
    }
    sessionService = oil.newobject(sessionService, sessionServiceInterface)

    self:addFacet("sessionService", sessionServiceInterface, sessionService)

    _, self.credential = self.accessControlService:loginByCertificate("SessionService", "")
    local serviceOffer = {
        type = "OpenBus/SS/ISessionService",
        description = "Servico de Sessoes",
        properties = {},
        member = self,
    }
    local registryService = self.accessControlService:getRegistryService(self.credential)
    if not registryService then
        error{"IDL:SCS/StartupFailed:1.0"}
    end
    local registryServiceInterface = "IDL:OpenBus/RS/IRegistryService:1.0"
    registryService = registryService:getFacet(registryServiceInterface)
    registryService = oil.narrow(registryService, registryServiceInterface)
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
