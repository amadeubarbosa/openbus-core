local mode = ...

local home = assert(os.getenv("OPENBUS_CORE_HOME"),
  "missing enviroment variable OPENBUS_CORE_HOME")
local path = home.."/bin/busadmin"
if mode=="DEBUG" then
  path = path.." DEBUG"
end
local descscript = home.."/bin/busadmdesc.lua"

require "openbus.test.configs"


local function popen(command, exitval)
  local path = os.tmpname()
  local how, value = select(2, os.execute(command.." > "..path.." 2>&1"))
  local output = assert(io.open(path)):read("*a")
  os.remove(path)
  assert(how == "exit")
  assert(value == exitval or 0)
  return output
end

local function checkreplace(text, replacement, count)
  local result, replaces = string.gsub(text, replacement, "")
  if result == nil or replaces ~= count then
    error("expected "..count.." occurrences, but got only "..replaces.." occurences of '"..replacement.."' in the output below: "..text)
  end
  --assert(result ~= nil and replaces == count, result)
  return result
end

local function testparams(params, expected, ...)
  local output = popen(path.." "..params, ...)
  if expected == nil then
    assert(string.match(output, "^%s*$"), output)
  elseif #expected == 0 then
    for replacement, count in pairs(expected) do
      output = checkreplace(output, replacement, count)
    end
  else
    for _, replacement in ipairs(expected) do
      output = checkreplace(output, replacement, 1)
    end
  end
end

local function testscript(script, ...)
  local params = string.format("-e 'login(%q, %q, %q, %q)' -e '%s'",
                               busref, admin, admpsw, domain, script)
  return testparams(params, ...)
end

-- help
testparams("-help", {
  "Usage:",
  "Options:",
  "%-busref ",
  "%-entity ",
  "%-privatekey ",
  "%-password ",
  "%-domain ",
  "%-sslmode ",
  "%-sslcapath ",
  "%-sslcafile ",
  "%-sslcert ",
  "%-sslkey ",
  "%-loglevel ",
  "%-logfile ",
  "%-oilloglevel ",
  "%-oillogfile ",
  "%-interactive ",
  "%-execute ",
  "%-load ",
  "%-version ",
  "%-configs ",
}, 1)

-- clean up any left over definitions
testscript([[
for _, catid in ipairs({"CTG01", "CTG02"}) do
  local category = getcategory(catid)
  if category ~= nil then
    for _, entity in ipairs(category:entities()) do
      assert(delentity(entity))
    end
    assert(delcategory(category))
  end
end
delcert("ENT02")
delcert("NoReg")
deliface("IDL:script/test:1.0")
deliface("IDL:script/test2:1.0")
]])

-- categoria
testscript([[assert(setcategory("CTG01", "categoria numero 01"))]])
testscript([[assert(setcategory("CTG02", "categoria numero 02"))]])
testscript([[print(categories())]], {
  "CTG01", "categoria numero 01",
  "CTG02", "categoria numero 02",
})
testscript([[print(getcategory("CTG01"))]], {
  "CTG01", "categoria numero 01",
})
testscript([[assert(setcategory("CTG01", "novo nome da categoria 01"))]])
testscript([[assert(delcategory("CTG01"))]])

-- entidade
testscript([[
  local category = assert(getcategory("CTG02"))
  category:addentity("ENT01", "entidade 01")
  category:addentity("ENT02", "entidade 02")
  category:addentity("ENT03", "entidade 03")
  category:addentity("ENT04", "entidade 04")
]])
testscript([[print(entities())]], {
  "ENT01", "entidade 01",
  "ENT02", "entidade 02",
  "ENT03", "entidade 03",
  "ENT04", "entidade 04",
})
testscript([[print(getentity("ENT02"))]], {
  "ENT02", "entidade 02",
})
testscript([[print(assert(getcategory("CTG02")):entities())]], {
  "ENT03", "entidade 03",
  "ENT04", "entidade 04",
})
testscript([[assert(setentity("ENT01", "novo nome da entidade 01"))]])
testscript([[assert(delentity("ENT01"))]])

-- certificado
testscript([[assert(setcert("ENT02", assert(require("oil").readfrom("]]..syscrt..[[", "rb"))))]])
testscript([[assert(setcert("NoReg", assert(require("oil").readfrom("]]..syscrt..[[", "rb"))))]])
testscript([[print(certents())]], {
  "ENT02", "NoReg",
})
testscript([[assert(delcert("NoReg"))]])
testscript([[assert(delcert("ENT02"))]])

-- interface
testscript([[assert(addiface("IDL:script/test:1.0"))]])
testscript([[assert(addiface("IDL:script/test2:1.0"))]])
testscript([[print(ifaces())]], {
  "IDL:script/test:1.0",
  "IDL:script/test2:1.0"
})
testscript([[assert(deliface("IDL:script/test2:1.0"))]])

-- autorização
testscript([[assert(getentity("ENT02")):grant("IDL:script/test:1.0")]])
testscript([[assert(getentity("ENT03")):grant("IDL:script/test:1.0")]])
testscript([[assert(getentity("ENT04")):grant("IDL:script/test:1.0")]])
testscript([[assert(getentity("ENT04")):revoke("IDL:script/test:1.0")]])
testscript([[print(entities("*"))]], {
  "ENT02",
  "ENT03",
})
testscript([[print(assert(getentity("ENT03")):ifaces())]], {
  "IDL:script/test:1.0",
})
testscript([[print(entities("IDL:script/test:1.0"))]], {
  "ENT02",
  "ENT03",
})

-- oferta
testscript([[print(offers())]], {})

-- login
testscript([[print(logins())]], {})

-- removendo tudo o que foi criado
testscript([[
  assert(getentity("ENT02")):revoke("IDL:script/test:1.0")
  assert(getentity("ENT03")):revoke("IDL:script/test:1.0")
  assert(deliface("IDL:script/test:1.0"))
  delentity("ENT02")
  delentity("ENT03")
  delentity("ENT04")
  delcategory("CTG02")
]])
