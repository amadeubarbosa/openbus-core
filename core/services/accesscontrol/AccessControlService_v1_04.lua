-- $Id: AccessControlService.lua 103385 2010-03-23 17:13:26Z mgatti $

local Openbus = require "openbus.Openbus" 
local oop = require "loop.simple"
local Utils = require "openbus.util.Utils"

---
--Componente responsável pelo Serviço de Controle de Acesso na versao 1.04.
---
module("core.services.accesscontrol.AccessControlService_v1_04")

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

---
--Metodo existente apenas na API 1.04.
---
function ACSFacet:getRegistryService()
  local ic = self.context.IReceptacles:getConnections("RegistryServiceReceptacle")[1].objref
  local rs = ic:getFacet(Utils.REGISTRY_SERVICE_INTERFACE_V1_04)
  return Openbus:getORB():narrow(rs, Utils.REGISTRY_SERVICE_INTERFACE_V1_04)
end

---
--Metodo existente apenas na API 1.04.
---
function ACSFacet:setRegistryService(rsComponent)
  return false
end

--------------------------------------------------------------------------------
-- Faceta ILeaseProvider
--------------------------------------------------------------------------------

LeaseProviderFacet = oop.class{}

function LeaseProviderFacet:renewLease(credential)
  return self.context.ILeaseProvider:renewLease(credential)
end

