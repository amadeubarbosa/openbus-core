local _G = require "_G"
local string = _G.string
local os = _G.os
local io = _G.io
local print = _G.print

local login = " --login=admin"
local password = " --password=admin"

local launcher = "$OPENBUS_HOME/bin/servicelauncher.bin $OPENBUS_SRC/core/trunk/run.lua"
local outputfile = "output.txt"
local script = "test.adm"
local certificate = "openbus.crt"
local header = launcher.." module openbus.core.admin.main"..login..password
local tail = "> "..outputfile

local function finalize()
  os.execute("rm -f output.txt")
end

local function showError()
  local f = io.open(outputfile)
  local err = f:read("*a")
  f:close()
  finalize()
  return err
end

local function execute(command)
  local cmd = string.format("%s %s %s", header, command, tail)
  return os.execute(cmd)
end

-- help
assert(execute("--help") == 0, showError())

-- categoria
assert(execute("--add-category=CTG01 --name='categoria numero 01'") == 0,
      showError())
assert(execute("--add-category=CTG02 --name='categoria numero 02'") == 0,
      showError())
assert(execute("--list-category") == 0, showError())
assert(execute("--list-category=CTG01") == 0, showError())
assert(execute("--set-category=CTG01 --name='novo nome da categoria 01'") == 0, 
      showError())
assert(execute("--del-category=CTG01") == 0, showError())

-- entidade
assert(execute("--add-entity=ENT01 --category=CTG02 --name='entidade 01'") == 0, 
      showError())
assert(execute("--add-entity=ENT02 --category=CTG02 "..
              "--name='entidade 02' --certificado="..certificate) == 0, 
      showError())
assert(execute("--add-entity=ENT03 --category=CTG02 --name='entidade 03'") == 0, 
      showError())
assert(execute("--add-entity=ENT04 --category=CTG02 --name='entidade 04'") == 0, 
      showError())
assert(execute("--list-entity") == 0, showError())
assert(execute("--list-entity=ENT02") == 0, showError())
assert(execute("--list-entity --category=CTG02") == 0, showError())
assert(execute("--set-entity=ENT01 --name='novo nome da entidade 01'") == 0,
      showError())
assert(execute("--del-entity=ENT01") == 0, showError())

-- certificado
assert(execute("--add-certificate=NoReg --certificate="..certificate) == 0, 
      showError())
assert(execute("--del-certificate=NoReg") == 0, showError())
assert(execute("--del-certificate=ENT02") == 0, showError())

-- interface
assert(execute("--add-interface=IDL:script/test:1.0") == 0, showError())
assert(execute("--add-interface=IDL:script/test2:1.0") == 0, showError())
assert(execute("--list-interface") == 0, showError())
assert(execute("--del-interface=IDL:script/test2:1.0") == 0, showError())

-- autorização
assert(execute("--set-authorization=ENT02 --grant=IDL:script/test:1.0") == 0,
      showError())
assert(execute("--set-authorization=ENT03 --grant=IDL:script/test:1.0") == 0,
      showError())
assert(execute("--set-authorization=ENT04 --grant=IDL:script/test:1.0") == 0,
      showError())
assert(execute("--set-authorization=ENT04 --revoke=IDL:script/test:1.0") == 0,
      showError())
assert(execute("--list-authorization") == 0, showError())
assert(execute("--list-authorization=ENT03") == 0, showError())
--assert(execute("--list-authorization --interface=IDL:script/test:1.0") == 0, 
--      showError())

-- oferta
assert(execute("--list-offer") == 0, showError())

-- login
assert(execute("--list-login") == 0, showError())

-- script
assert(execute("--script="..script) == 0, showError())
assert(execute("--undo-script="..script) == 0, showError())

-- removendo tudo o que foi criado
assert(execute("--set-authorization=ENT02 --revoke=IDL:script/test:1.0") == 0,
      showError())
assert(execute("--set-authorization=ENT03 --revoke=IDL:script/test:1.0") == 0,
      showError())
assert(execute("--del-interface=IDL:script/test:1.0") == 0, showError())
assert(execute("--del-entity=ENT02") == 0, showError())
assert(execute("--del-entity=ENT03") == 0, showError())
assert(execute("--del-entity=ENT04") == 0, showError())
assert(execute("--del-category=CTG02") == 0, showError())

finalize()
print("[OK] Script de testes executado por completo!")
