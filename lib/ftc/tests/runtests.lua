--
-- runtests.lua
--

require "config"

-- Define os arquivos de teste.
local files = {
--   { "10b", 10, "TECGRAFCOS" },
--   { "20b", 20 },
--   { "100b", 100 },
--   { "10Mb", 10000000 },
--   { "50Mb", 50000000 },
--   { "100Mb", 100000000 },
--   { "200Mb", 200000000 },
--   { "300Mb", 300000000 },
  { "3Gb", 3000000000 },
}

-- Gera arquivos para testes da lib.
if arg[1] == "genfiles" then
  local fg = require "FileGenerator"
  os.execute("touch "..SERVER_TMP_PATH.."/write")
  os.execute("touch "..SERVER_TMP_PATH.."/1WMb")
  for k, v in ipairs(files) do
    local filename = SERVER_TMP_PATH.."/"..v[1]
    local size = v[2]
    local pattern = v[3]
    print('Gerando arquivo '..filename..' - Tamanho: '..size..'b ...')
    fg(filename, size, pattern)
  end
elseif arg[1] == "diff" then
  os.execute(string.format("diff %s/10Mb %s/10MbRCVED", LOCAL_TMP_PATH, LOCAL_TMP_PATH))
  os.execute(string.format("diff %s/50Mb %s/50MbRCVED", LOCAL_TMP_PATH, LOCAL_TMP_PATH))
  os.execute(string.format("diff %s/100Mb %s/100MbRCVED", LOCAL_TMP_PATH, LOCAL_TMP_PATH))
  os.execute(string.format("diff %s/200Mb %s/200MbRCVED", LOCAL_TMP_PATH, LOCAL_TMP_PATH))
  os.execute(string.format("diff %s/300Mb %s/300MbRCVED", LOCAL_TMP_PATH, LOCAL_TMP_PATH))
elseif arg[1] == "scp" then
  os.execute(string.format("scp rcosme@%s:%s/10Mb %s/10MbRCVED", SERVER_HOST, SERVER_TMP_PATH, LOCAL_TMP_PATH))
  os.execute(string.format("scp rcosme@%s:%s/50Mb %s/50MbRCVED", SERVER_HOST, SERVER_TMP_PATH, LOCAL_TMP_PATH))
  os.execute(string.format("scp rcosme@%s:%s/100Mb %s/100MbRCVED", SERVER_HOST, SERVER_TMP_PATH, LOCAL_TMP_PATH))
  os.execute(string.format("scp rcosme@%s:%s/200Mb %s/200MbRCVED", SERVER_HOST, SERVER_TMP_PATH, LOCAL_TMP_PATH))
  os.execute(string.format("scp rcosme@%s:%s/300Mb %s/300MbRCVED", SERVER_HOST, SERVER_TMP_PATH, LOCAL_TMP_PATH))
-- Executa a base de testes para o cliente C++.
elseif arg[1] == "cpp" then
  os.execute("./runner")
-- Executa a base de testes para o cliente Lua.
elseif arg[1] == "lua" then
  latt = {}
  latt.pcall = pcall

  dofile("tests.lua")
  if not Suite then
    error("Suite not found !!!")
  end

  local TestRunner = require("latt.TestRunner")
  local ConsoleResultViewer = require("latt.ConsoleResultViewer")

  local testRunner = TestRunner(Suite)
  local result = testRunner:run()
  local viewer = ConsoleResultViewer(result)
  viewer:show()
else
  print("Usage: lua5.1 runtests.lua <genfiles|diff|scp|cpp|lua>")
end
