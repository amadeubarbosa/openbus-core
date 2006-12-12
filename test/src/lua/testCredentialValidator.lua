require "oil"

--oil.verbose.level(3)

local idlfile = "../../src/corba_idl/as.idl"

oil.loadidlfile(idlfile)

local ior = arg[1]

local accessControlService = oil.newproxy(ior, "IDL:SCS/AS/AccessControlService:1.0")

local passwordAuthenticator = accessControlService:getFacetByName("passwordAuthenticator")
passwordAuthenticator = oil.narrow(passwordAuthenticator, "IDL:SCS/AS/PasswordAuthenticator:1.0")
local credential = passwordAuthenticator:login(arg[2], arg[3])
if credential.id == -1 then
    print("Erro na autenticacao.")
else
    print("O usuario "..credential.entityName.." foi autenticado com sucesso.")
end

local credentialValidatorInterface = "IDL:SCS/AS/CredentialValidator:1.0"
local credentialValidator = accessControlService:getFacet(credentialValidatorInterface)
credentialValidator = oil.narrow(credentialValidator, credentialValidatorInterface)
local isValid = credentialValidator:validate(credential)
if isValid == true then
    print("A credential e valida")
end

isValid = credentialValidator:validate({id = -1, entityName = "csbase"})
if isValid == true then
    print("A credential e valida")
end

isValid = credentialValidator:validate({id = "1", entityName = "csbase"})
if isValid == true then
    print("A credential e valida")
end

isValid = credentialValidator:validate({id = "1", entityName = "csbase2"})
if isValid == true then
    print("A credential e valida")
end
