require "OOP"
require "lualdap"

AccessControlService = Object:new{
    hostname = "segall.tecgraf.puc-rio.br",
    credentials = {},

    loginByCredential = function(self, credential)
        if self.credentials[credential.entityName] == nil then
            return false
        end
        return true
    end,

    loginByPassword = function(self, name, password)
        local connection = lualdap.open_simple(self.hostname, name, password, false)
        if connection == nil then
            return {id = -1, entityName = name}
        end
        connection:close()
        local credential = {id = 1, entityName = name}
        self.credentials[name] = credential
        return credential
    end,

    logout = function(self, credential)
        self.credentials[credential.entityName] = nil
    end,

    isValid = function(self, credential)
        local bufferedCredential = self.credentials[credential.entityName]
        if bufferedCredential == nil then
            return false
        end

        if bufferedCredential.entityName ~= credential.entityName then
            return false
        end
        if bufferedCredential.id ~= credential.id then
            return false
        end

        return true
    end,

    getRegistryService = function(self, credential)
        if self.credentialValidator:validate(credential) == false then
            return nil
        end
        return self.registryService
    end,

    addObserver = function (self, observer)
    end,

    removeObserver = function(self, observer)
    end,

    beat = function(self, resource)
    end,
}
