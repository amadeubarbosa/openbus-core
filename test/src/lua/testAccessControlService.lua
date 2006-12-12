require "oil"

--oil.verbose.level(3)

local idlfile = "../../src/corba_idl/as.idl"

oil.loadidlfile(idlfile)

local ior = arg[1]

local accessControlService = oil.newproxy(ior, "IDL:SCS/AS/AccessControlService:1.0")

local passwordAuthenticatorInterface = "IDL:SCS/AS/PasswordAuthenticator:1.0"
local passwordAuthenticator = accessControlService:getFacet(passwordAuthenticatorInterface)
passwordAuthenticator = oil.narrow(passwordAuthenticator, passwordAuthenticatorInterface)
passwordAuthenticator = accessControlService:getFacetByName("passwordAuthenticator")
passwordAuthenticator = oil.narrow(passwordAuthenticator, passwordAuthenticatorInterface)

local credentialValidatorInterface = "IDL:SCS/AS/CredentialValidator:1.0"
local credentialValidator = accessControlService:getFacet(credentialValidatorInterface)
credentialValidator = oil.narrow(credentialValidator, credentialValidatorInterface)
credentialValidator = accessControlService:getFacetByName("credentialValidator")
credentialValidator = oil.narrow(credentialValidator, credentialValidatorInterface)
