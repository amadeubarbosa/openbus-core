--
-- runtests.lua
--

require "config"

-- Define os arquivos de teste.
local files = {
  { "10b", 10, "RICARDOCOS" },
  { "20b", 20 },
  { "100b", 100 },
  { "10Mb", 10000000 },
  { "50Mb", 50000000 },
  { "100Mb", 100000000 },
  { "200Mb", 200000000 },
  { "300Mb", 300000000 },
}

-- Gera arquivos para testes da lib.
if arg[1] == "genfiles" then
  local fg = require "ftc.tests.FileGenerator"
  os.execute("touch "..SERVER_TMP_PATH.."/write")
  os.execute("touch "..SERVER_TMP_PATH.."/1WMb")
  for k, v in ipairs(files) do
    local filename = SERVER_TMP_PATH.."/"..v[1]
    print('Gerando arquivo '..filename..'...')
    fg(filename, v[2], v[3])
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
else
-- Executa a base de testes.
  os.execute("./runner")
end
