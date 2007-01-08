require "lualdap"

if #arg ~= 3 then
    print("Parametros invalidos !!!")
    print("Use testLdapAuthentication.lua <host>[:port] <user> <password>")
    os.exit(0)
end

local hostname = arg[1]
local user = arg[2]
local password = arg[3]

local connection, errorMessage = lualdap.open_simple(hostname, user, password, false)
if connection == nil then
    print(errorMessage)
    os.exit(1)
end
print("Usuario "..user.." autenticado com sucesso.")
connection:close()
