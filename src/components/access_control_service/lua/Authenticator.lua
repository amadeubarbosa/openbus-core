require "lualdap"

require "OOP"

Authenticator = Object:new{
    hostname = "segall.tecgraf.puc-rio.br",

    loginByCredential = function(self, credential)
        if self.credentials[credential.entityName] == nil then
            return false
        end
        return true
    end,

    loginByPassword = function(self, name, password)
        local connection, errorMessage = lualdap.open_simple(self.hostname, name, password, false)
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
    end
}
