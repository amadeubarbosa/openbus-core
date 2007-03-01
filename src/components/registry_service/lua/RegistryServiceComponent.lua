require "Member"

require "RegistryService"

local oop = require "loop.simple"

RegistryServiceComponent = oop.class({}, Member)

function RegistryServiceComponent:startup()
    local accessControlServiceComponent = oil.newproxy("corbaloc::"..self.accessControlServerHost.."/"..self.accessControlServerKey, "IDL:OpenBus/ACS/IAccessControlServiceComponent:1.0")
    if accessControlServiceComponent:_non_existent() then
        print("Servico de controle de acesso nao encontrado.")
        error{"IDL:SCS/StartupFailed:1.0"}
    end
    local accessControlServiceInterface = "IDL:OpenBus/ACS/IAccessControlService:1.0"
    self.accessControlService = accessControlServiceComponent:getFacet(accessControlServiceInterface)
    self.accessControlService = oil.narrow(self.accessControlService, accessControlServiceInterface)

    local success
    success, self.credential = self.accessControlService:loginByCertificate("RegistryService", "")
    if not success then
        print("Nao foi possivel logar no servico de controle de acesso.")
        error{"IDL:SCS/StartupFailed:1.0"}
    end

    local registryService = RegistryService{accessControlService = self.accessControlService}
    local registryServiceInterface = "IDL:OpenBus/RS/IRegistryService:1.0"
    registryService = oil.newobject(registryService, registryServiceInterface)

    self:addFacet("registryService", registryServiceInterface, registryService)

    self.accessControlService:setRegistryService(self.credential, self)

    local credentialObserver = {registryService = registryService}
    function credentialObserver:credentialWasDeleted(credential)
        self.registryService:deleteOffersFromCredential(credential)
    end
    credentialObserver = oil.newobject(credentialObserver, "IDL:OpenBus/ACS/ICredentialObserver:1.0")
    self.observerIdentifier = self.accessControlService:addObserver(credentialObserver, {})
end

function RegistryServiceComponent:shutdown()
    if not self.accessControlService then
        print("Servico ja foi finalizado.")
        error{"IDL:SCS/ShutdownFailed:1.0"}
    end

    self.accessControlService:removeObserver(self.observerIdentifier)
    self.accessControlService:logout(self.credential)

    self.observerIdentifier = nil
    self.credential = nil
    self.accessControlService = nil

    self:removeFacets()
end
