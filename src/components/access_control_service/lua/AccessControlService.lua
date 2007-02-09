require "lualdap"
require "uuid"

require "CredentialDB"

local oop = require "loop.base"

AccessControlService = oop.class{
  invalidCredential = {identifier = "", entityName = ""},
  observersByIdentifier = {},
  observersByCredentialIdentifier = {},
}

function AccessControlService:__init(object)
  object = object or {}
  local credentialDB = CredentialDB(ServerConfiguration.databaseDirectory)
  local entriesByName = {}
  local entries = credentialDB:selectAll()
  for _, entry in ipairs(entries) do
    entriesByName[entry.credential.entityName] = entry
  end
  object.entriesByName = entriesByName
  object.ldapHost = ServerConfiguration.ldapHost
  object.credentialDB = credentialDB
  return oop.rawnew(self, object)
end

function AccessControlService:loginByPassword(name, password)
    local connection, errorMessage = lualdap.open_simple(self.ldapHost, name, password, false)
    if not connection then
        return self.invalidCredential
    end
    connection:close()
    local entry = self:addEntry(name)
    return entry.credential
end

function AccessControlService:loginByCertificate(name, answer)
    if name ~= "RegistryService" and name ~= "SessionService" then
        return self.invalidCredential
    end
    local entry = self:addEntry(name)
    return entry.credential
end

function AccessControlService:getToken(name)
    return ""
end

function AccessControlService:logout(credential)
    local entry = self.entriesByName[credential.entityName]
    if not entry then
        return false
    end
    self:removeEntry(entry)
    return true
end

function AccessControlService:isValid(credential)
    local entry = self.entriesByName[credential.entityName]
    if not entry then
        return false
    end
    if entry.credential.identifier ~= credential.identifier then
        return false
    end
    return true
end

function AccessControlService:getRegistryService(credential)
    if not self:isValid(credential) then
        return nil
    end
    return self.registryService
end

function AccessControlService:setRegistryService(credential, registryService)
    if self:isValid(credential) and credential.entityName == "RegistryService" then
        self.registryService = registryService
        return true
    end
    return false
end

function AccessControlService:addObserver(observer, credentialIdentifiers)
    local observerIdentifier = self:generateCredentialObserverIdentifier()
    self.observersByIdentifier[observerIdentifier] = {observer = observer, identifier = observerIdentifier, credentialIdentifiers = {}}
    for _, credentialIdentifier in ipairs(credentialIdentifiers) do
        self:addCredentialToObserver(observerIdentifier, credentialIdentifier)
    end
    return observerIdentifier
end

function AccessControlService:removeObserver(observerIdentifier)
    local observerEntry = self.observersByIdentifier[observerIdentifier]
    if not observerEntry then
        return false
    end
    for _, credentialIdentifier in ipairs(observerEntry.credentialIdentifiers) do
        self:removeCredentialFromObserver(observerIdentifier, credentialIdentifier)
    end
    self.observersByIdentifier[observerIdentifier] = nil
    return true
end

function AccessControlService:addCredentialToObserver(observerIdentifier, credentialIdentifier)
    local observerEntry = self.observersByIdentifier[observerIdentifier]
    if not observerEntry then
        return false
    end
    table.insert(observerEntry.credentialIdentifiers, credentialIdentifier)
    if not self.observersByCredentialIdentifier[credentialIdentifier] then
        self.observersByCredentialIdentifier[credentialIdentifier] = {}
    end
    table.insert(self.observersByCredentialIdentifier[credentialIdentifier], observer)
    return true
end

function AccessControlService:removeCredentialFromObserver(observerIdentifier, credentialIdentifier)
    local observerEntry = self.observersByIdentifier[observerIdentifier]
    if not observerEntry then
        return false
    end
    local credentialIdentifierIndex
    for i, bufferedCredentialIdentifier in ipairs(observerEntry.credentialIdentifiers) do
        if bufferedCredentialIdentifier == credentialIdentifier then
            credentialIdentifierIndex = i
            break
        end
    end
    table.remove(observerEntry.credentialIdentifiers, credentialIdentifierIndex)
    local observerIndex
    for i, observer in ipairs(self.observersByCredentialIdentifier[credentialIdentifier]) do
        if observer.identifier == observerIdentifier then
            observerIndex = i
        end
    end
    table.remove(self.observersByCredentialIdentifier[credentialIdentifier], observerIndex)
    return true
end

function AccessControlService:addEntry(name)
    local credential = {identifier = self:generateCredentialIdentifier(), entityName = name}
    entry = {credential = credential, time = os.time()}
    self.entriesByName[name] = entry
    self.credentialDB:insert(entry.credential, entry.time)
    return entry
end

function AccessControlService:generateCredentialIdentifier()
    return uuid.new("time")
end

function AccessControlService:generateCredentialObserverIdentifier()
    return uuid.new("time")
end

function AccessControlService:removeEntry(entry)
    self.entriesByName[entry.credential.entityName] = nil
    self:notifyCredentialWasDeleted(entry.credential)
    self.credentialDB:delete(entry.credential)
end

function AccessControlService:notifyCredentialWasDeleted(credential)
    local observers = self.observersByCredentialIdentifier[credential.identifier]
    if not observers then
        return
    end
    for observer in pairs(observers) do
        observer:credentialWasDeleted(credential)
    end
end
