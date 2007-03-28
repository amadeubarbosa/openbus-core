--
-- Componente (membro) responsável pelo Serviço de Controle de Acesso
--
-- $Id$
--
require "Member"
require "AccessControlService"

require "ServerInterceptor"
require "PICurrent"

local oop = require "loop.simple"

AccessControlServiceComponent = oop.class({}, Member)

function AccessControlServiceComponent:startup(ldapHost, databaseDirectory)
  local picurrent = PICurrent()
  local accessControlService = 
    AccessControlService(ldapHost, databaseDirectory, picurrent)

  -- instala o interceptador do serviço de controle de acesso
  local CONF_DIR = os.getenv("CONF_DIR")
  local config =
    assert(loadfile(CONF_DIR.."/advanced/ACSInterceptorsConfiguration.lua"))()
  oil.setserverinterceptor(ServerInterceptor(config, picurrent, 
                                             accessControlService))

  -- cria e instala a faceta de controle de acesso
  local accessControlServiceInterface = 
    "IDL:OpenBus/ACS/IAccessControlService:1.0"
  self:addFacet("accessControlService", accessControlServiceInterface, 
                accessControlService)
end

function AccessControlServiceComponent:shutdown()
    self:removeFacets()
end
