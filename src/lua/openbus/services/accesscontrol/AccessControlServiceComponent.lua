--
-- Componente (membro) responsável pelo Serviço de Controle de Acesso
--
-- $Id$
--
require "openbus.Member"
require "openbus.services.accesscontrol.AccessControlService"

local ServerInterceptor = require "openbus.common.ServerInterceptor"
local PICurrent = require "openbus.common.PICurrent"

local oop = require "loop.simple"

AccessControlServiceComponent = oop.class({}, Member)

function AccessControlServiceComponent:__init(name)
  local obj = { name = name,
                config = AccessControlServerConfiguration,
              }
  Member:__init(obj)
  return oop.rawnew(self, obj)
end

function AccessControlServiceComponent:startup()
  local picurrent = PICurrent()
  local accessControlService = AccessControlService(picurrent)

  -- instala o interceptador do serviço de controle de acesso
  local CONF_DIR = os.getenv("CONF_DIR")
  local config =
    assert(loadfile(CONF_DIR.."/advanced/ACSInterceptorsConfiguration.lua"))()
  oil.setserverinterceptor(ServerInterceptor(config, picurrent, 
                                             accessControlService))

  -- cria e instala a faceta de controle de acesso
  local accessControlServiceInterface = 
    "IDL:openbusidl/acs/IAccessControlService:1.0"
  self:addFacet("accessControlService", accessControlServiceInterface, 
                accessControlService)
end

function AccessControlServiceComponent:shutdown()
  self:removeFacets()
end
