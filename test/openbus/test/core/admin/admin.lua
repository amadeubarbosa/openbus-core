-------------------------------------------------------------------------------
-- configuração do teste
bushost, busport = ...
require "openbus.test.configs"
local adminPassword = admpsw
local certfile = syscrt
local script = admscript
local outputfile = admoutput

local bin = "busadmin --host="..bushost.." --port="..busport.." "
local login = "--login="..admin.." "
local password = "--password="..adminPassword.." "
local domain = "--domain="..domain.." "
local certificate = "--certificate="..certfile

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
if OPENBUS_HOME then
  bin = OPENBUS_HOME.."/bin/"..bin
end
-------------------------------------------------------------------------------

local function finalize()
  os.execute("rm -f " ..outputfile)
end

local function readOutput()
  local f = io.open(outputfile)
  local err = f:read("*a")
  f:close()
  return err
end

local function execute(...)
  local command = bin..login..password..domain
  local params = table.concat({...}, " ")
  local tofile = " > "..outputfile
  local ok, errmsg = os.execute(command..params..tofile)
  local output = readOutput()
  if not ok then
    return false, output
  end
  local failed = output:find("[ERRO]",1,true)
  if not failed then
    return true
  else
    finalize()
    return false, output
  end
end

-- help
assert(execute("--help"))

-- categoria
assert(execute("--add-category=CTG01","--name='categoria numero 01'"))
assert(execute("--add-category=CTG02","--name='categoria numero 02'"))
assert(execute("--list-category"))
assert(execute("--list-category=CTG01"))
assert(execute("--set-category=CTG01","--name='novo nome da categoria 01'"))
assert(execute("--del-category=CTG01"))

-- entidade
assert(execute("--add-entity=ENT01","--category=CTG02","--name='entidade 01'"))
assert(execute("--add-entity=ENT02","--category=CTG02", "--name='entidade 02'"))
assert(execute("--add-certificate=ENT02", certificate))
assert(execute("--add-entity=ENT03","--category=CTG02","--name='entidade 03'"))
assert(execute("--add-entity=ENT04","--category=CTG02","--name='entidade 04'"))
assert(execute("--list-entity"))
assert(execute("--list-entity=ENT02"))
assert(execute("--list-entity","--category=CTG02"))
assert(execute("--set-entity=ENT01","--name='novo nome da entidade 01'"))
assert(execute("--del-entity=ENT01"))

-- certificado
assert(execute("--add-certificate=NoReg",certificate))
assert(execute("--del-certificate=NoReg"))
assert(execute("--del-certificate=ENT02"))
assert(execute("--list-certificate"))

-- interface
assert(execute("--add-interface=IDL:script/test:1.0"))
assert(execute("--add-interface=IDL:script/test2:1.0"))
assert(execute("--list-interface"))
assert(execute("--del-interface=IDL:script/test2:1.0"))

-- autorização
assert(execute("--set-authorization=ENT02","--grant=IDL:script/test:1.0"))
assert(execute("--set-authorization=ENT03","--grant=IDL:script/test:1.0"))
assert(execute("--set-authorization=ENT04","--grant=IDL:script/test:1.0"))
assert(execute("--set-authorization=ENT04","--revoke=IDL:script/test:1.0"))
assert(execute("--list-authorization"))
assert(execute("--list-authorization=ENT03"))
assert(execute("--list-authorization","--interface=IDL:script/test:1.0"))

-- oferta
assert(execute("--list-offer"))

-- login
assert(execute("--list-login"))

-- script
assert(execute("--script="..script))
assert(execute("--undo-script="..script))

-- removendo tudo o que foi criado
assert(execute("--set-authorization=ENT02","--revoke=IDL:script/test:1.0"))
assert(execute("--set-authorization=ENT03","--revoke=IDL:script/test:1.0"))
assert(execute("--del-interface=IDL:script/test:1.0"))
assert(execute("--del-entity=ENT02"))
assert(execute("--del-entity=ENT03"))
assert(execute("--del-entity=ENT04"))
assert(execute("--del-category=CTG02"))

finalize()
print("[OK] Script de testes executado por completo!")

os.exit()
