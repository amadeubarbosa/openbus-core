-- $Id:

local format = string.format
local tostring = tostring

local oop = require "loop.simple"
local oil = require "oil"

local Log = require "openbus.util.Log"
---
-- Código responsável pelo Serviço de Registro na versao anterior à atual do barramento.
---
module("core.services.registry.RegistryService_Prev")

------------------------------------------------------------------------------
-- Faceta IRegistryService
------------------------------------------------------------------------------

RSFacet = oop.class{}

function RSFacet:register(serviceOffer)
  local rs = self.context.IRegistryService
  local succ, offerId = oil.pcall(rs.register, rs, serviceOffer.properties, 
    serviceOffer.member)
  if not succ then
    -- convertendo exceções desconhecidas da versão 1.5
    if offerId[1] == "IDL:tecgraf/openbus/core/"..Utils.OB_VERSION..
        "/registry_service/UnauthorizedFacets:1.0" then
      error(Openbus:getORB():newexcept{ "IDL:tecgraf/openbus/core/"..
        Utils.OB_PREV.."/registry_service/UnauthorizedFacets:1.0", 
        facets = offerId.fFacets })
    else
      -- registra o erro e repassa como CORBA::UNKNOWN
      Log:error(offerId[1])
      error(Openbus:getORB():newexcept{ "CORBA::UNKNOWN" })
    end
  end
  return offerId
end

function RSFacet:unregister(identifier)
  return self.context.IRegistryService:unregister(identifier) 
end

function RSFacet:update(identifier, properties)
  return self.context.IRegistryService:update(identifier, properties)
end

function RSFacet:find(facets)
  return self.context.IRegistryService:find(facets)
end

function RSFacet:findByCriteria(facets, criteria)
  return self.context.IRegistryService:findByCriteria(facets, criteria)
end

function RSFacet:localFind(facets, criteria)
  return self.context.IRegistryService:localFind(facets, criteria)
end

------------------------------------------------------------------------------
-- Faceta IFaultTolerantService
------------------------------------------------------------------------------

FaultToleranceFacet = oop.class{}

function FaultToleranceFacet:init()
  return self.context.IFaultTolerantService:init()
end

function FaultToleranceFacet:isAlive()
  return self.context.IFaultTolerantService:isAlive()
end

function FaultToleranceFacet:setStatus(isAlive)
  return self.context.IFaultTolerantService:setStatus(isAlive)
end

function FaultToleranceFacet:kill()
  return self.context.IFaultTolerantService:kill()
end

function FaultToleranceFacet:updateStatus(param)
  return self.context.IFaultTolerantService:updateStatus(param)
end
