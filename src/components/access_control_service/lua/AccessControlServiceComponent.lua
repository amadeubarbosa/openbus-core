require "Member"
require "AccessControlService"

local oop = require "loop.simple"
local ServerInterceptor = require "ServerInterceptor"

AccessControlServiceComponent = oop.class({}, Member)

function AccessControlServiceComponent:startup()
    local accessControlService = AccessControlService()

    -- instala o interceptador do serviço de controle de acesso
    local CONF_DIR = os.getenv("CONF_DIR")
    local config =
      assert(loadfile(CONF_DIR.."/advanced/ACSInterceptorsConfiguration.lua"))()
    oil.setserverinterceptor(ServerInterceptor(config, accessControlService))

    -- cria e instala a faceta de controle de acesso
    local accessControlServiceInterface = "IDL:OpenBus/ACS/IAccessControlService:1.0"
    accessControlService = oil.newobject(accessControlService, accessControlServiceInterface)

    self:addFacet("accessControlService", accessControlServiceInterface, accessControlService)
end

function AccessControlServiceComponent:shutdown()
    self:removeFacets()
end
