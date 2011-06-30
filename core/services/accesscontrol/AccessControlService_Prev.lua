-- $Id:

local Openbus = require "openbus.Openbus"
local oop = require "loop.simple"
local Utils = require "openbus.util.Utils"

---
--Componente respons�vel pelo Servi�o de Controle de Acesso na versao 1.04.
---
module("core.services.accesscontrol.AccessControlService_Prev")

--------------------------------------------------------------------------------
-- Faceta IAccessControlService
--------------------------------------------------------------------------------

ACSFacet = oop.class{}

function ACSFacet:loginByPassword(name, password)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:loginByPassword(name,
           password)
end

function ACSFacet:loginByCertificate(name, answer)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:loginByCertificate(name,
           answer)
end

function ACSFacet:getChallenge(name)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:getChallenge(name)
end

function ACSFacet:logout(credential)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:logout(credential)
end

function ACSFacet:isValid(credential)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:isValid(credential)
end

function ACSFacet:areValid(credentials)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:areValid(credentials)
end

function ACSFacet:addObserver(observer, credentialIdentifiers)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:addObserver(observer, credentialIdentifiers)
end

function ACSFacet:getEntryCredential(credential)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:getEntryCredential(credential)
end

function ACSFacet:getAllEntryCredential()
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:getAllEntryCredential()
end


function ACSFacet:addCredentialToObserver(observerIdentifier, credentialIdentifier)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:addCredentialToObserver(
           observerIdentifier, credentialIdentifier)
end

function ACSFacet:removeObserver(observerIdentifier, credential)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:removeObserver(
           observerIdentifier, credential)
end

function ACSFacet:removeCredentialFromObserver(observerIdentifier,
    credentialIdentifier)
  return self.context["IAccessControlService_" .. Utils.IDL_VERSION]:removeCredentialFromObserver(
           observerIdentifier, credentialIdentifier)
end

---
--Metodo existente apenas na API 1.04.
---
function ACSFacet:getRegistryService()
  local receptacles = self.context.IReceptacles:getConnections("RegistryServiceReceptacle")
  if #receptacles == 0 then
    return nil
  end
  local ic = receptacles[1].objref
  local rs = ic:getFacet(Utils.REGISTRY_SERVICE_INTERFACE_PREV)
  return Openbus:getORB():narrow(rs, Utils.REGISTRY_SERVICE_INTERFACE_PREV)
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
  return self.context["ILeaseProvider_" .. Utils.IDL_VERSION]:renewLease(credential)
end

