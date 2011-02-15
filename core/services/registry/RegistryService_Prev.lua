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
  return self.context.IRegistryService:register(serviceOffer)
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

------------------------------------------------------------------------------
-- Faceta IManagement
------------------------------------------------------------------------------

ManagementFacet = oop.class{}

function ManagementFacet:addInterfaceIdentifier(ifaceId)
  return self.context.IManagement:addInterfaceIdentifier(ifaceId)
end

function ManagementFacet:removeInterfaceIdentifier(ifaceId)
  return self.context.IManagement:removeInterfaceIdentifier(ifaceId)
end

function ManagementFacet:getInterfaceIdentifiers()
  return self.context.IManagement:getInterfaceIdentifiers()
end

function ManagementFacet:grant(id, ifaceId, strict)
  return self.context.IManagement:grant(id, ifaceId, strict)
end

function ManagementFacet:revoke(id, ifaceId)
  return self.context.IManagement:revoke(id, ifaceId)
end

function ManagementFacet:removeAuthorization(id)
  return self.context.IManagement:removeAuthorization(id)
end

function ManagementFacet:getAuthorization(id)
  return self.context.IManagement:getAuthorization(id)
end

function ManagementFacet:getAuthorizations()
  return self.context.IManagement:getAuthorizations()
end

function ManagementFacet:getAuthorizationsByInterfaceId(ifaceIds)
  return self.context.IManagement:getAuthorizationsByInterfaceId(ifaceIds)
end

function ManagementFacet:getOfferedInterfaces()
  return self.context.IManagement:getOfferedInterfaces()
end

function ManagementFacet:getOfferedInterfacesByMember(member)
  return self.context.IManagement:getOfferedInterfacesByMember(member)
end

function ManagementFacet:getUnauthorizedInterfaces()
  return self.context.IManagement:getUnauthorizedInterfaces()
end

function ManagementFacet:getUnauthorizedInterfacesByMember(member)
  return self.context.IManagement:getUnauthorizedInterfacesByMember(member)
end

function ManagementFacet:unregister(id)
  return self.context.IManagement:unregister(id)
end


