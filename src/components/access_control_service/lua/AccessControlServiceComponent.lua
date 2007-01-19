require "OOP"

require "Member"

require "AccessControlService"

AccessControlServiceComponent = createClass(Member)

function AccessControlServiceComponent:startup()
    local accessControlService = AccessControlService:new{
        ldapHost = self.ldapHost,
    }

    local accessControlServiceInterface = "IDL:OpenBus/AS/AccessControlService:1.0"
    accessControlService = oil.newobject(accessControlService, accessControlServiceInterface)

    self:addFacet("accessControlService", accessControlServiceInterface, accessControlService)
end

function AccessControlServiceComponent:shutdown()
    self:removeFacets()
end
