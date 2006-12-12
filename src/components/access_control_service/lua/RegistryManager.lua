require "OOP"

RegistryManager = Object:new{
    getRegistryService = function(self, credential)
        if self.credentialValidator:validate(credential) == false then
            return nil
        end
        return self.registryService
    end,
}
