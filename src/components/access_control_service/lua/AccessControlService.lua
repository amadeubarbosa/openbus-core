require "OOP"

require "Authenticator"
require "CredentialValidator"

AccessControlService = Object:new{
    credentials = {},

    facets = {},

    facetsByName = {},

    startup = function(self)
        local authenticator = Authenticator:new{credentials = self.credentials}
        local authenticatorInterface = "IDL:SCS/AS/Authenticator:1.0"
        authenticator = oil.newobject(authenticator, authenticatorInterface)
        self.facets[authenticatorInterface] = authenticator
        self.facetsByName["authenticator"] = authenticator

        local credentialValidator = CredentialValidator:new{credentials = self.credentials}
        local credentialValidatorInterface = "IDL:SCS/AS/CredentialValidator:1.0"
        credentialValidator = oil.newobject(credentialValidator, credentialValidatorInterface)
        self.facets[credentialValidatorInterface] = credentialValidator
        self.facetsByName["credentialValidator"] = credentialValidator

        local registryManager = RegistryManager:new{credentialValidator = self.facets[credentialValidatorInterface]}
        local registryManagerInterface = "IDL:SCS/AS/RegistryManager:1.0"
        registryManager = oil.newobject(registryManager, registryManagerInterface)
        self.facets[registryManagerInterface] = registryManager
        self.facetsByName["registryManager"] = registryManager
    end,

    shutdown = function(self)
        self.facets = {}
        self.facetsByName = {}
    end,

    getFacet = function(self, facet_interface)
        return self.facets[facet_interface]
    end,

    getFacetByName = function(self, facet)
        return self.facetsByName[facet]
    end,

    beat = function(self, resource)
    end,
}
