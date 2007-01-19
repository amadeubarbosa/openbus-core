require "lualdap"
require "uuid"

require "OOP"

AccessControlService = createClass()

AccessControlService.invalidCredential = {identifier = "", memberName = ""}
AccessControlService.invalidLoginIdentifier = ""

AccessControlService.entriesByName = {}
AccessControlService.entriesByLoginIdentifier = {}

AccessControlService.observersByIdentifier = {}
AccessControlService.observersByCredentialIdentifier = {}

function AccessControlService:loginByCredential(credential)
    if not self:isValid(credential) then
        return self.invalidLoginIdentifier
    end
    local entry = self.entriesByName[credential.memberName]
    local loginIdentifier = self:addLoginIdentifier(entry)
    return loginIdentifier
end

function AccessControlService:loginByPassword(name, password)
    local connection, errorMessage = lualdap.open_simple(self.ldapHost, name, password, false)
    if not connection then
        return {credential = self.invalidCredential, loginIdentifier = self.invalidLoginIdentifier}
    end
    connection:close()
    local entry = self:addEntry(name)
    local loginIdentifier = self:addLoginIdentifier(entry)
    return {credential = entry.credential, loginIdentifier = loginIdentifier}
end

function AccessControlService:loginByCertificate(name, answer)
    if name ~= "RegistryService" and name ~= "SessionService" then
        return {credential = self.invalidCredential, loginIdentifier = self.invalidLoginIdentifier}
    end
    local entry = self:addEntry(name)
    local loginIdentifier = self:addLoginIdentifier(entry)
    return {credential = entry.credential, loginIdentifier = loginIdentifier}
end

function AccessControlService:getToken(name)
    return ""
end

function AccessControlService:logout(loginIdentifier)
    local entry = self.entriesByLoginIdentifier[loginIdentifier]
    if not entry then
        return false
    end
    self.entriesByLoginIdentifier[loginIdentifier] = nil
    local index
    for bufferedIndex, bufferedIdentifier in ipairs(entry.identifiers) do
        if loginIdentifier == bufferedIdentifier then
            index = bufferedIndex
            break
        end
    end
    table.remove(entry.identifiers, index)
    if #entry.identifiers == 0 then
        self:removeEntry(entry)
    end
    return true
end

function AccessControlService:isValid(credential)
    local entry = self.entriesByName[credential.memberName]
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
    if self:isValid(credential) and credential.memberName == "RegistryService" then
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

function AccessControlService:beat(credential)
    local entry = self.entriesByName[credential.memberName]
    if not entry then
        return false
    end
    entry.time = os.time()
    return true
end

function AccessControlService:addEntry(name)
    local credential = {identifier = self:generateCredentialIdentifier(), memberName = name}
    entry = {credential = credential, time = os.time(), identifiers = {}}
    self.entriesByName[name] = entry
    return entry
end

function AccessControlService:addLoginIdentifier(entry)
    local loginIdentifier = self:generateLoginIdentifier()
    self.entriesByLoginIdentifier[loginIdentifier] = entry
    table.insert(entry.identifiers, loginIdentifier)
    return loginIdentifier
end

function AccessControlService:generateCredentialIdentifier()
    return uuid.new("time")
end

function AccessControlService:generateLoginIdentifier()
    return uuid.new("time")
end

function AccessControlService:generateCredentialObserverIdentifier()
    return uuid.new("time")
end

function AccessControlService:removeDeadCredentials()
    for _, entry in pairs(self.entriesByName) do
        if (entry.time + beatTime) < os.time() then
            self:removeEntry(entry)
        end
    end
end

function AccessControlService:removeEntry(entry)
    for _, loginIdentifier in ipairs(entry.identifiers) do
        self.entriesByLoginIdentifiers[loginIdentifier] = nil
    end
    self.entriesByName[entry.credential.memberName] = nil
    self:notifyCredentialWasDeleted(entry.credential)
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
