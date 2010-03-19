--
-- Testa o funcionamento do lualdap.
-- 
-- $Id$
--
require "lualdap"

if #arg < 2 then
    print("Parâmetros inválidos !!!")
    print("Use testLdapAuthentication.lua <host>[:port] <user> [password]")
    os.exit(0)
end

local hostname = arg[1]
local user = arg[2]
local password = arg[3]
if not password or string.match(password, "^%s*$") then
  print("A senha não pode estar em branco")
  os.exit(1)
end

local connection, errorMessage = lualdap.open_simple(hostname, user, password, false)
if connection == nil then
    print(errorMessage)
    os.exit(1)
end
print("Usuário "..user.." autenticado com sucesso.")
connection:close()
