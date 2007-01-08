require "lualdap"
require "uuid"

require "OOP"

AccessControlService = Object:new{
    entriesByName = {},
    entriesByIdentifier = {},
    observers = {},

    getToken = function(self, name)
        return ""
    end,

    loginByCertificate = function(self, name, answer)
        if name ~= "RegistryService" and name ~= "SessionService" then
            return {credential = {identifier = "", entityName = ""}, loginIdentifier = ""}
        end

        local entry = self.entriesByName[name]
        if not entry then
            entry = self:addEntry(name)
        end
        local loginIdentifier = self:addLoginIdentifier(entry)
        return {credential = entry.credential, loginIdentifier = loginIdentifier}
    end,

    loginByCredential = function(self, credential, heart)
        if not self:isValid(credential) then
            return ""
        end
        local entry = self.entriesByName[credential.entityName]
        local loginIdentifier = self:addLoginIdentifier(entry)
        entry.heartsByIdentifier[loginIdentifier] = heart
        return loginIdentifier
    end,

    loginByPassword = function(self, name, password)
        local connection, errorMessage = lualdap.open_simple(self.ldapHost, name, password, false)
        if not connection then
            return {credential = {identifier = "", entityName = ""}, loginIdentifier = ""}
        end
        connection:close()
        local entry = self.entriesByName[name]
        if not entry then
            entry = self:addEntry(name)
        end
        local loginIdentifier = self:addLoginIdentifier(entry)
        return {credential = entry.credential, loginIdentifier = loginIdentifier}
    end,

    logout = function(self, identifier)
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
            self.entriesByName[entry.credential.entityName] = nil
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
    end,

    isValid = function(self, credential)
        local entry = self.entriesByName[credential.entityName]
        if not entry then
            return false
        end
        if entry.credential.identifier ~= credential.identifier then
            return false
        end
        return true
    end,

    setRegistryService = function(self, credential, registryService)
        if self:isValid(credential) and credential.entityName == "RegistryService" then
            self.registryService = registryService
            return true
        end
        return false
    end,

    getRegistryService = function(self, credential)
        if not self:isValid(credential) then
            return nil
        end
        return self.registryService
    end,

    beat = function(self, credential)
        local entry = self.entriesByName[credential.entityName]
        if not entry then
            return false
        end
        entry.time = os.time()
        return true
    end,

    addObserver = function (self, observer)
        self.observers[observer] = true
    end,

    removeObserver = function(self, observer)
        self.observers[observer] = nil
    end,

    addEntry = function(self, name)
        local credential = {identifier = self:generateCredentialIdentifier(), entityName = name}
        entry = {credential = credential, time = os.time(), identifiers = {}, heartsByIdentifier = {}}
        self.entriesByName[name] = entry
        return entry
    end,

    addLoginIdentifier = function(self, entry)
        local loginIdentifier = self:generateLoginIdentifier()
        self.entriesByIdentifier[loginIdentifier] = entry
        table.insert(entry.identifiers, loginIdentifier)
        return loginIdentifier
    end,

    generateCredentialIdentifier = function(self)
        return uuid.new("time")
    end,

    generateLoginIdentifier = function(self)
        return uuid.new("time")
    end,

    removeDeadCredentials = function(self)
        for entityName, entry in pairs(self.entriesByName) do
            if (entry.time + beatTime) < os.time() then
                self.entriesByName[entityName] = nil
                for _, identifier in ipairs(entry.identifiers) do
                    self.credentialsByIdentifier[identifier] = nil
                end
            end
        end
    end,

    notifyCredentialWasDeleted = function(self, credential)
        for observer, valid in pairs(self.observers) do
            if valid then
                observer:credentialWasDeleted(credential)
            end
        end
    end,
}
