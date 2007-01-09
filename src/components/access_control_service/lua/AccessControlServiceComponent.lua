require "IComponent"

require "AccessControlService"

AccessControlServiceComponent = createClass(IComponent)

function AccessControlServiceComponent:startup()
    local accessControlService = AccessControlService:new{
        ldapHost = self.ldapHost,
    }
    local accessControlServiceInterface = "IDL:OpenBus/AS/AccessControlService:1.0"

    accessControlService = oil.newobject(accessControlService, accessControlServiceInterface)

    self.facets[accessControlServiceInterface] = accessControlService
    self.facetsByName["accessControlService"] = accessControlService
end

function AccessControlServiceComponent:shutdown()
    self.facets = {}
    self.facetsByName = {}
end
