-- $Id:

local format = string.format
local tostring = tostring

local oop = require "loop.simple"
local oil = require "oil"

local Log = require "openbus.util.Log"
local rgs = require "core.services.registry.RegistryService"
---
-- Código responsável pelo Serviço de Registro na versao anterior à atual do barramento.
---
module("core.services.registry.RegistryService_Prev")

------------------------------------------------------------------------------
-- Faceta IRegistryService_Prev
------------------------------------------------------------------------------

-- Indica que o serviço tentou registrar alguma faceta não autorizada
local UnauthorizedFacetsException = "IDL:tecgraf/openbus/core/"..
  Utils.PREV.."/registry_service/UnathorizedFacets:1.0"

-- Indica que Serviço de Registro não possui a oferta de serviço indicada
local ServiceOfferNonExistentException = "IDL:tecgraf/openbus/core/"..
  Utils.OB_PREV.."/registry_service/ServiceOfferNonExistent:1.0"

RSFacet = oop.class{}

function RSFacet:register(serviceOffer)
  local rs = self.context.IRegistryService
  local succ, offerId = oil.pcall(rs.register, rs, serviceOffer.properties, 
    serviceOffer.member)
  if not succ then
    -- convertendo exceções desconhecidas da versão 1.5
    if offerId[1] == rgs.UnauthorizedFacetsException then
      error(Openbus:getORB():newexcept{ UnauthorizedFacetsException, 
        facets = offerId.fFacets })
    elseif err[1] == rgs.ServiceFailureException then
      -- registra o erro e repassa como CORBA::UNKNOWN
      Log:error(offerId[1])
      error(Openbus:getORB():newexcept{ "CORBA::UNKNOWN" })
    else
      --repassa o erro
      error(offerId)
    end
  end
  return offerId
end

function RSFacet:unregister(identifier)
  local rs = self.context.IRegistryService
  local succ, err = oil.pcall(rs.unregister, rs, identifier) 
  if not succ then
    if err[1] == rgs.ServiceFailureException then
      Log:error(err[1])
      return false
    else
      -- repassa o erro
      error(list)
    end
  end
  return true
end

function RSFacet:update(identifier, properties)
  local rs = self.context.IRegistryService
  local succ, err = oil.pcall(rs.setOfferProperties, rs, identifier, properties)
  if not succ then
    -- convertendo exceções desconhecidas da versão 1.5
    if err[1] == rgs.ServiceOfferDoesNotExistException then
      error(Openbus:getORB():newexcept{ ServiceOfferNonExistentException })
    elseif err[1] == rgs.ServiceFailureException or 
        err[1] == rgs.InvalidPropertiesException then
      -- registra o erro e repassa como CORBA::UNKNOWN
      Log:error(err[1])
      error(Openbus:getORB():newexcept{ "CORBA::UNKNOWN" })
    else
      -- repassa o erro
      error(err)
    end
  end
end

function RSFacet:find(facets)
  local rs = self.context.IRegistryService
  local succ, list = oil.pcall(rs.find, rs, facets)
  if not succ then
    -- convertendo exceções desconhecidas da versão 1.5
    if list[1] == rgs.ServiceFailureException then
      Log:error(list[1])
      error(Openbus:getORB():newexcept{ "CORBA::UNKNOWN" })
    else
      -- repassa o erro
      error(list)
    end
  end
  return list
end

function RSFacet:findByCriteria(facets, criteria)
  local rs = self.context.IRegistryService
  local succ, list = oil.pcall(rs.findByCriteria, rs, facets, criteria)
  if not succ then
    -- convertendo exceções desconhecidas da versão 1.5
    if list[1] == rgs.ServiceFailureException then
      Log:error(list[1])
      error(Openbus:getORB():newexcept{ "CORBA::UNKNOWN" })
    else
      -- repassa o erro
      error(list)
    end
  end
  return list
end

function RSFacet:localFind(facets, criteria)
  local rs = self.context.IRegistryService
  local succ, list = oil.pcall(rs.localFind, rs, facets, criteria)
  if not succ then
    -- convertendo exceções desconhecidas da versão 1.5
    if list[1] == rgs.ServiceFailureException then
      Log:error(list[1])
      error(Openbus:getORB():newexcept{ "CORBA::UNKNOWN" })
    else
      -- repassa o erro
      error(list)
    end
  end
  return list
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
