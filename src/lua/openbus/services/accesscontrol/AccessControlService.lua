-----------------------------------------------------------------------------
-- Faceta que disponibiliza a funcionalidade básica do serviço de controle
-- de acesso
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "lualdap"
require "uuid"
require "lce"

require "openbus.services.accesscontrol.CredentialDB"

local log = require "openbus.common.Log"

local oop = require "loop.base"

AccessControlService = oop.class{
  invalidCredential = {identifier = "", entityName = ""},
}

function AccessControlService:__init(picurrent)
  self = oop.rawnew(self, {
    entries = {},
    observersByIdentifier = {},
    observersByCredential = {},
    challenges = {},
    config = AccessControlServerConfiguration,
    picurrent = picurrent,
  })
  self.privateKey = lce.key.readprivatefrompemfile(self.config.privateKeyFile)
  self.credentialDB = CredentialDB(self.config.databaseDirectory)
  local entriesDB = self.credentialDB:selectAll()
  for _, entry in pairs(entriesDB) do
    self.entries[entry.credential.identifier] = {credential = entry.credential,}
  end
  return self
end

function AccessControlService:loginByPassword(name, password)
    local ldapHost = self.config.ldapHostName..":"..self.config.ldapHostPort
    local connection, errorMessage = lualdap.open_simple(ldapHost, name, password, false)
    if not connection then
      log:error("Erro ao conectar com o servidor LDAP.\n"..errorMessage)
      return false, self.invalidCredential
    end
    connection:close()
    local entry = self:addEntry(name)
    return true, entry.credential
end

function AccessControlService:loginByCertificate(name, answer)
  local challenge = self.challenges[name]
  if not challenge then
    log:error("Nao existe desafio para "..name)
    return false, self.invalidCredential
  end
  local errorMessage
  answer, errorMessage = lce.cipher.decrypt(self.privateKey, answer)
  if answer ~= challenge then
    log:error("Erro ao obter a resposta de "..name)
    log:error(errorMessage)
    return false, self.invalidCredential
  end
  local entry = self:addEntry(name)
  return true, entry.credential
end

function AccessControlService:getChallenge(name)
  local certificate, errorMessage = self:getCertificate(name)
  if not certificate then
    log:error("Nao foi encontrado o certificado de "..name)
    log:error(errorMessage)
    return ""
  end
  local challenge = self:generateChallenge(name, certificate)
  certificate:release()
  return challenge
end

function AccessControlService:getCertificate(name)
  local certificateFile = self.config.certificatesDirectory.."/"..name..".crt"
  return lce.x509.readfromderfile(certificateFile)
end

function AccessControlService:generateChallenge(name, certificate)
  local currentTime = tostring(os.time())
  self.challenges[name] = currentTime
  return lce.cipher.encrypt(certificate:getpublickey(), currentTime)
end

function AccessControlService:logout(credential)
    local entry = self.entries[credential.identifier]
    if not entry then
      log:warn("Tentativa de logout com credencial inexistente: "..
        credential.identifier)
      return false
    end
    self:removeEntry(entry)
    return true
end

function AccessControlService:isValid(credential)
    local entry = self.entries[credential.identifier]
    if not entry then
        return false
    end
    if entry.credential.identifier ~= credential.identifier then
        return false
    end
    return true
end

function AccessControlService:getRegistryService()
    return self.registryService
end

function AccessControlService:setRegistryService(member)
    local credential = self.picurrent:getValue()
    if credential.entityName == "RegistryService" then
        self.registryService = member
        return true
    end
    return false
end

function AccessControlService:addObserver(observer, credentialIdentifiers)
    local observerId = self:generateObserverIdentifier()
    local observerEntry = {observer = observer, credentials = {}}
    self.observersByIdentifier[observerId] = observerEntry
    for _, credentialId in ipairs(credentialIdentifiers) do
      observerEntry.credentials[credentialId] = true
      if not self.observersByCredential[credentialId] then
        self.observersByCredential[credentialId] = {}
      end
      self.observersByCredential[credentialId][observerId] = observerEntry
    end
    return observerId
end

function AccessControlService:removeObserver(observerIdentifier)
    local observerEntry = self.observersByIdentifier[observerIdentifier]
    if not observerEntry then
      return false
    end
    for credentialId in pairs(observerEntry.credentials) do
      if self.observersByCredential[credentialId] then
        self.observersByCredential[credentialId][observerIdentifier] = nil
      end
    end
    self.observersByIdentifier[observerIdentifier] = nil
    return true
end

function AccessControlService:addCredentialToObserver(observerIdentifier, credentialIdentifier)
    local observerEntry = self.observersByIdentifier[observerIdentifier]
    if not observerEntry then
      return false
    end
    observerEntry.credentials[credentialIdentifier] = true
    if not self.observersByCredential[credentialIdentifier] then
      self.observersByCredential[credentialIdentifier] = {}
    end
    self.observersByCredential[credentialIdentifier][observerIdentifier] =
      observerEntry
    return true
end

function AccessControlService:removeCredentialFromObserver(observerIdentifier,
    credentialIdentifier)
    local observerEntry = self.observersByIdentifier[observerIdentifier]
    if not observerEntry then
      return false
    end
    observerEntry.credentials[credentialIdentifier] = false
    if self.observersByCredential[credentialIdentifier] then
      self.observersByCredential[credentialIdentifier][observerIdentifier] = nil
    end
    return true
end

function AccessControlService:addEntry(name)
    local credential = {identifier = self:generateCredentialIdentifier(), entityName = name}
    entry = {credential = credential, time = os.time()}
    self.credentialDB:insert(entry.credential, entry.time)
    self.entries[entry.credential.identifier] = entry
    return entry
end

function AccessControlService:generateCredentialIdentifier()
    return uuid.new("time")
end

function AccessControlService:generateObserverIdentifier()
    return uuid.new("time")
end

function AccessControlService:removeEntry(entry)
    self.entries[entry.credential.identifier] = nil
    log:service("Vai notificar aos observadores...")
    self:notifyCredentialWasDeleted(entry.credential)
    log:service("Observadores notificados...")
    self.credentialDB:delete(entry.credential)
end

function AccessControlService:notifyCredentialWasDeleted(credential)
    local observers = self.observersByCredential[credential.identifier]
    if not observers then
        return
    end
    for _, observerEntry in pairs(observers) do
      local success, err = oil.pcall(observerEntry.observer.credentialWasDeleted, observerEntry.observer, credential)
      if not success then
        log:warn("Erro ao notificar um observador.")
        log:warn(err)
      end
    end
end
