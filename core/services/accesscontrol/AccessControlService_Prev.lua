-- $Id: 

local Openbus = require "openbus.Openbus" 
local oop = require "loop.simple"
local Utils = require "openbus.util.Utils"
local print = print

---
--Componente responsável pelo Serviço de Controle de Acesso na versao anterior suportada.
---
module("core.services.accesscontrol.AccessControlService_Prev")

--------------------------------------------------------------------------------
-- Faceta IAccessControlService
--------------------------------------------------------------------------------

ACSFacet = oop.class{}

function ACSFacet:loginByPassword(name, password)
  return self.context.IAccessControlService:loginByPassword(name, 
           password)
end

function ACSFacet:loginByCertificate(name, answer)
  return self.context.IAccessControlService:loginByCertificate(name, 
           answer)
end

function ACSFacet:getChallenge(name)
  return self.context.IAccessControlService:getChallenge(name) 
end

function ACSFacet:logout(credential)
  return self.context.IAccessControlService:logout(credential)
end

function ACSFacet:isValid(credential)
  return self.context.IAccessControlService:isValid(credential)
end

function ACSFacet:areValid(credentials)
  return self.context.IAccessControlService:areValid(credentials)
end

function ACSFacet:addObserver(observer, credentialIdentifiers)
  return self.context.IAccessControlService:addObserver(observer, credentialIdentifiers) 
end

function ACSFacet:getEntryCredential(credential)
  return self.context.IAccessControlService:getEntryCredential(credential)
end

function ACSFacet:getAllEntryCredential()
  return self.context.IAccessControlService:getAllEntryCredential()
end


function ACSFacet:addCredentialToObserver(observerIdentifier, credentialIdentifier)
  return self.context.IAccessControlService:addCredentialToObserver(
           observerIdentifier, credentialIdentifier)
end

function ACSFacet:removeObserver(observerIdentifier, credential)
  return self.context.IAccessControlService:removeObserver(
           observerIdentifier, credential)
end

function ACSFacet:removeCredentialFromObserver(observerIdentifier,
    credentialIdentifier)
  return self.context.IAccessControlService:removeCredentialFromObserver(
           observerIdentifier, credentialIdentifier)
end

--------------------------------------------------------------------------------
-- Faceta ILeaseProvider
--------------------------------------------------------------------------------

LeaseProviderFacet = oop.class{}

function LeaseProviderFacet:renewLease(credential)
  return self.context.ILeaseProvider:renewLease(credential)
end

--------------------------------------------------------------------------------
-- Faceta IComponent
--------------------------------------------------------------------------------

ComponentFacet = oop.class{}

function ComponentFacet:startup()
  return self.context.IComponent:startup()
end

function ComponentFacet:shutdown()
  return self.context.IComponent:shutdown()
end

function ComponentFacet:getFacet(interface)
  return self.context.IComponent:getFacet(interface)
end

function ComponentFacet:getFacetByName(facet)
  return self.context.IComponent:getFacetByName(facet)
end

function ComponentFacet:getComponentId()
  return self.context.IComponent:getComponentId()
end

--------------------------------------------------------------------------------
-- Faceta IFaultTolerantService
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Faceta IManagement
--------------------------------------------------------------------------------

ManagementFacet = oop.class{}

function ManagementFacet:addSystem(id, description)
  return self.context.IManagement:addSystem(id, description)
end

function ManagementFacet:removeSystem(id)
  return self.context.IManagement:removeSystem(id)
end

function ManagementFacet:setSystemDescription(id, description)
  return self.context.IManagement:setSystemDescription(id, description)
end

function ManagementFacet:getSystems()
  return self.context.IManagement:getSystems()
end

function ManagementFacet:getSystem(id)
  return self.context.IManagement:getSystem(id)
end

function ManagementFacet:addSystemDeployment(id, systemId, description, certificate)
  return self.context.IManagement:addSystemDeployment(id, systemId, description, certificate)
end

function ManagementFacet:removeSystemDeployment(id)
  return self.context.IManagement:removeSystemDeployment(id)
end

function ManagementFacet:setSystemDeploymentDescription(id, description)
  return self.context.IManagement:setSystemDeploymentDescription(id, description)
end

function ManagementFacet:getSystemDeploymentCertificate(id)
  return self.context.IManagement:getSystemDeploymentCertificate(id)
end

function ManagementFacet:setSystemDeploymentCertificate(id, certificate)
  return self.context.IManagement:setSystemDeploymentCertificate(id, certificate)
end

function ManagementFacet:getSystemDeployments()
  return self.context.IManagement:getSystemDeployments()
end

function ManagementFacet:getSystemDeployment(id)
  return self.context.IManagement:getSystemDeployment(id)
end

function ManagementFacet:getSystemDeploymentBySystemId(systemId)
  return self.context.IManagement:getSystemDeploymentBySystemId(systemId)
end

function ManagementFacet:addUser(id, name)
  return self.context.IManagement:addUser(id, name)
end

function ManagementFacet:removeUser(id)
  return self.context.IManagement:removeUser(id)
end

function ManagementFacet:setUserName(id, name)
  return self.context.IManagement:setUserName(id, name)
end

function ManagementFacet:getUser(id)
  return self.context.IManagement:getUser(id)
end

function ManagementFacet:getUsers()
  return self.context.IManagement:getUsers()
end

