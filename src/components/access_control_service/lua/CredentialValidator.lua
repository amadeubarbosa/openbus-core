CredentialValidator = Object:new{
    validate = function(self, credential)
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
    end
}
