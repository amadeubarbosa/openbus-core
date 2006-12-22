require "lualdap"
require "uuid"

require "OOP"

AccessControlService = Object:new{
    hostname = "segall.tecgraf.puc-rio.br",
    beatTime = 10,
    entriesByName = {},
    credentialsByIdentifier = {},
    observers = {},

    loginByCredential = function(self, credential, heart)
        if self:isValid(credential) == false then
            return nil
        end

        local loginIdentifier = self:generateLoginIdentifier()
        self.credentialsByIdentifier[loginIdentifier] = credential

        local entry = self.entriesByName[credential.entityName]

        table.insert(entry.identifiers, loginIdentifier)
        entry.heartsByIdentifier[loginIdentifier] = heart

        return loginIdentifier
    end,

    generateLoginIdentifier = function(self)
        return uuid.new("time")
    end,

    loginByPassword = function(self, name, password)
        local connection = lualdap.open_simple(self.hostname, name, password, false)
        if connection == nil then
            return {credential = nil, identifier = nil}
        end
        connection:close()

        local entry = self.entriesByName[name]
        local credential = nil
        if entry == nil then
            credential = {id = self:generateCredentialIdentifier(), entityName = name}
            self.entriesByName[name] = {credential = credential, time = os.time(), identifiers = {}, heartsByIdentifier = {}}
        else
            credential = entry.credential
        end

        table.insert()
        local loginIdentifier = self:generateLoginIdentifier()
        self.credentialsByIdentifier[loginIdentifier] = credential

        return {beatTime = self.beatTime, credential = credential, identifier = loginIdentifier}
    end,

    generateCredentialIdentifier = function(self)
        return uuid.new("time")
    end,

    logout = function(self, identifier)
        local credential = self.credentialsByIdentifier[identifier]
        if credential == nil then
            return
        end
        self.credentialsByIdentifier[identifier] = nil
        local entry = self.entriesByName[credential.entityName]
        if entry.identifiers == nil then
            self.entriesByName[credential.entityName] = nil
            self:notifyCredentialWasDeleted(credential)
        end
    end,

    isValid = function(self, credential)
        local entry = self.entries[credential.entityName]
        if entry == nil then
            return false
        end

        if entry.credential.entityName ~= credential.entityName then
            return false
        end
        if entry.credential.id ~= credential.id then
            return false
        end

        return true
    end,

    getRegistryService = function(self, credential)
        if self:isValid(credential) == false then
            return nil
        end
        return self.registryService
    end,

    beat = function(self, credential)
        local entry = self.entriesByName[credential.entityName]
        if entry == nil then
            return false
        entry.time = os.time()
        return true
    end,

    removeDeadCredentials = function(self)
        for _, entry in pairs(self.entriesByName) do
            if (entry.time + beatTime) < os.time() then
                entry.
            end
        end
    end,

    addObserver = function (self, observer)
        self.observers[observer] = true
    end,

    removeObserver = function(self, observer)
        self.observers[observer] = nil
    end,

    notifyCredentialWasDeleted = function(self, credential)
        for observer in pairs(self.observers) do
            observer:credentialWasDeleted(credential)
        end
    end,
}
