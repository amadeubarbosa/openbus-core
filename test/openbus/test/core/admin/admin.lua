-------------------------------------------------------------------------------
-- configuração do teste
bushost, busport = ...
require "openbus.test.configs"
local admin = admin
local adminPassword = admpsw
local certfile = syscrt
local script = admscript
local outputfile = admoutput

local bin = "busadmin --host="..bushost.." --port="..busport.." "
local login = "--login="..admin.." "
local password = "--password="..adminPassword.." "
local certificate = "--certificate="..certfile

local installpath = os.getenv("OPENBUS_CORE_HOME")
if installpath then
  bin = installpath.."/bin/"..bin
end
-------------------------------------------------------------------------------

local function finalize()
  os.remove(outputfile)
end

local function readOutput()
  local f = io.open(outputfile)
  local contents = f:read("*a")
  f:close()
  return contents
end

local function execute(...)
  local command = bin..login..password
  local params = table.concat({...}, " ")
  local tofile = " > "..outputfile
  local success = os.execute(command..params..tofile)
  local output = readOutput()
  local errmsg = output:find("[ERRO]",1,true)
  if success and not errmsg then
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

-- reconfiguração dinâmica
assert(execute("--set-max-cachesize=1024"))
assert(execute("--set-max-channels=100"))
assert(execute("--get-max-channels"))
assert(execute("--set-log-level=5"))
assert(execute("--set-oil-log-level=5"))
assert(execute("--add-validator=openbus.test.core.services.BadPasswordValidator"))
assert(not execute("--del-validator=openbus.test.core.services.BadPasswordValidator"))
assert(execute("--add-validator=openbus.test.core.services.BadPasswordValidator"))
assert(not execute("--add-validator=openbus.test.core.services.ErrorTestValidator"))
assert(not execute("--add-validator=openbus.test.core.services.NullValidationValidator"))
assert(execute("--grant-admin-to='peter'"))
login="--login=peter "
password="--password=peter "
assert(execute("--revoke-admin-from='peter'"))
login="--login="..admin.." "
password="--password="..adminPassword.." "
assert(execute("--reload-configs-file"))

finalize()

os.exit()
