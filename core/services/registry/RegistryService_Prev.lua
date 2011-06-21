-- $Id:

local format = string.format
local tostring = tostring

local oop = require "loop.simple"
local oil = require "oil"

local Log = require "openbus.util.Log"
local rgs = require "core.services.registry.RegistryService"
---
-- C�digo respons�vel pelo Servi�o de Registro na versao anterior � atual do barramento.
---
module("core.services.registry.RegistryService_Prev")

------------------------------------------------------------------------------
-- Faceta IRegistryService_Prev
------------------------------------------------------------------------------

-- Indica que o servi�o tentou registrar alguma faceta n�o autorizada
local UnauthorizedFacetsException = "IDL:tecgraf/openbus/core/"..
  Utils.PREV.."/registry_service/UnathorizedFacets:1.0"

-- Indica que Servi�o de Registro n�o possui a oferta de servi�o indicada
local ServiceOfferNonExistentException = "IDL:tecgraf/openbus/core/"..
  Utils.OB_PREV.."/registry_service/ServiceOfferNonExistent:1.0"

RSFacet = oop.class{}

function RSFacet:register(serviceOffer)
  local rs = self.context.IRegistryService
  local succ, offerId = oil.pcall(rs.register, rs, serviceOffer.properties, 
    serviceOffer.member)
  if not succ then
    -- convertendo exce��es desconhecidas da vers�o 1.5
    if offerId[1] == rgs.UnauthorizedFacetsException then
      error(Openbus:getORB():newexcept{ UnauthorizedFacetsException, 
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
  local rs = self.context.IRegistryService
  local succ, err = oil.pcall(rs.unregister, rs, identifier) 
  if not succ then
    -- registra o erro e retorna false
    Log:error(err[1])
    return false
  end
  return true
end

function RSFacet:update(identifier, properties)
  local rs = self.context.IRegistryService
  local succ, err = oil.pcall(rs.setOfferProperties, rs, identifier, properties)
  if not succ then
    if offerId[1] == rgs.ServiceOfferDoesNotExistException then
      error(Openbus:getORB():newexcept{ UnauthorizedFacetsException, 
        facets = offerId.fFacets })
    else
      -- registra o erro e repassa como CORBA::UNKNOWN
      Log:error(err[1])
      error(Openbus:getORB():newexcept{ "CORBA::UNKNOWN" })
    end
  end
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
