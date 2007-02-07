require "Member"

require "AccessControlService"

local oop = require "loop.simple"

AccessControlServiceComponent = oop.class({}, Member)

function AccessControlServiceComponent:startup()
    local accessControlService = AccessControlService{
        ldapHost = self.ldapHost,
    }

    local accessControlServiceInterface = "IDL:OpenBus/ACS/AccessControlService:1.0"
    accessControlService = oil.newobject(accessControlService, accessControlServiceInterface)

    self:addFacet("accessControlService", accessControlServiceInterface, accessControlService)
end

function AccessControlServiceComponent:shutdown()
    self:removeFacets()
end
