require "lualdap"
require "uuid"

require "OOP"

AccessControlService = createClass()

AccessControlService.invalidCredential = {identifier = "", memberName = ""}
AccessControlService.invalidLoginIdentifier = ""
AccessControlService.entriesByName = {}
AccessControlService.entriesByIdentifier = {}
AccessControlService.observers = {}

function AccessControlService:loginByCertificate(name, answer)
    if name ~= "RegistryService" and name ~= "SessionService" then
        return {credential = self.invalidCredential, loginIdentifier = self.invalidLoginIdentifier}
    end

    local entry = self:addEntry(name)
    local loginIdentifier = self:addLoginIdentifier(entry)
    return {credential = entry.credential, loginIdentifier = loginIdentifier}
end

function AccessControlService:loginByCredential(credential, heart)
    if not self:isValid(credential) then
        return ""
    end
    local entry = self.entriesByName[credential.memberName]
    local loginIdentifier = self:addLoginIdentifier(entry)
    entry.heartsByIdentifier[loginIdentifier] = heart
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

function AccessControlService:logout(identifier)
    local entry = self.entriesByIdentifier[identifier]
    if not entry then
        return false
    end
    self.entriesByIdentifier[identifier] = nil

    local index
    for bufferedIndex, bufferedIdentifier in ipairs(entry.identifiers) do
        if identifier == bufferedIdentifier then
            index = bufferedIndex
            break
        end
    end
    table.remove(entry.identifiers, index)
    if #entry.identifiers == 0 then
        self.entriesByName[entry.credential.memberName] = nil
        return true
    end

    if index == 1 then
        for _, bufferedIdentifier in ipairs(entry.identifiers) do
            local heart = entry.heartsByIdentifier[bufferedIdentifier]
            if heart then
                heart.start(self.beatTime)
                heartsByIdentifier[bufferedIdentifier] = nil
                break
            end
        end
    else
        entry.heartsByIdentifier[identifier] = nil
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

function AccessControlService:setRegistryService(credential, registryService)
    if self:isValid(credential) and credential.memberName == "RegistryService" then
        self.registryService = registryService
        return true
    end
    return false
end

function AccessControlService:getRegistryService(credential)
    if not self:isValid(credential) then
        return nil
    end
    return self.registryService
end

function AccessControlService:beat(credential)
    local entry = self.entriesByName[credential.memberName]
    if not entry then
        return false
    end
    entry.time = os.time()
    return true
end

function AccessControlService:addObserver(observer)
    self.observers[observer] = true
end

function AccessControlService:removeObserver(observer)
    self.observers[observer] = nil
end

function AccessControlService:addEntry(name)
    local credential = {identifier = self:generateCredentialIdentifier(), memberName = name}
    entry = {credential = credential, time = os.time(), identifiers = {}, heartsByIdentifier = {}}
    self.entriesByName[name] = entry
    return entry
end

function AccessControlService:addLoginIdentifier(entry)
    local loginIdentifier = self:generateLoginIdentifier()
    self.entriesByIdentifier[loginIdentifier] = entry
    table.insert(entry.identifiers, loginIdentifier)
    return loginIdentifier
end

function AccessControlService:generateCredentialIdentifier()
    return uuid.new("time")
end

function AccessControlService:generateLoginIdentifier()
    return uuid.new("time")
end

function AccessControlService:removeDeadCredentials()
    for memberName, entry in pairs(self.entriesByName) do
        if (entry.time + beatTime) < os.time() then
            self.entriesByName[memberName] = nil
            for _, identifier in ipairs(entry.identifiers) do
                self.credentialsByIdentifier[identifier] = nil
            end
        end
    end
end

function AccessControlService:notifyCredentialWasDeleted(credential)
    for observer, valid in pairs(self.observers) do
        if valid then
            observer:credentialWasDeleted(credential)
        end
    end
end
