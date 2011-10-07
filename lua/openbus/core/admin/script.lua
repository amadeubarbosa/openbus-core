local _G = require "_G"
local io = _G.io
local stderr = io.stderr
local type = _G.type
local string = _G.string
local loadstring = _G.loadstring
local print = _G.print
local debug = _G.debug
local error = _G.error
local pcall = _G.pcall
local table = _G.table
local ipairs = _G.ipairs

-------------------------------------------------------------------------------
-- Funções auxiliares

---
-- Função auxiliar para imprimir string formatada.
--
-- @param str String a ser formatada e impressa.
-- @param ... Argumentos para formatar a string.
--
local function printf(str, ...)
  print(string.format(str, ...))
end

---
-- Aborta a execução do script reportando um erro nos argumentos.
--
local function argerror()
  printf("[ERRO] Parâmetro inválido (linha %d)",
    debug.getinfo(3, 'l').currentline)
  error("Arquivo de script possui falhas.")
end

-------------------------------------------------------------------------------

-- Tabela de ações contidas no arquivo de script
local scripts = {}

-- Tabela com as funções de execução dos comandos
local handlers

---
-- Reseta a tabela de ações lidas do arquivo de script
--
local function resetScripts()
  scripts = {}
  scripts.Category = {}
  scripts.Entity = {}
  scripts.Certificate = {}
  scripts.Interface = {}
  scripts.Grant = {}
  scripts.Revoke = {}
end

---
-- Lê o arquivo de script e preenche a tabela 'scripts' com os comandos lidos.
--
-- @return Retorna true se leu o arquivo se erros e false caso contrário.
--
local function readScriptFile(cmd)
  resetScripts()
  local f, err, str, func, succ
  f, err = io.open(cmd.params[cmd.name])
  if not f then
    printf("[ERRO] Falha ao abrir arquivo: %s", err)
    return false
  end
  str, err = f:read("*a")
  f:close()
  if not str then
    printf("[ERRO] Falha ao ler conteúdo do arquivo: %s", err)
    return false
  end
  func, err = loadstring(str)
  if not func then
    printf("[ERRO] Falha ao carregar script: %s", err)
    return false
  end
  succ, err = pcall(func)
  if not succ then
    printf("[ERRO] Falha ao executar o script: %s", tostring(err))
    return false
  end
  return true
end

---
-- Cadastra uma categoria
--
-- @param category Tabela com os campos 'id' e 'name'
--
local function doCategory(category)
  local cmd = {}
  cmd.name = "add-category"
  cmd.params = {}
  cmd.params[cmd.name] = category.id
  cmd.params.name = category.name
  handlers[cmd.name](cmd)
end

---
-- Descadastra uma categoria
--
-- @param category Tabela com o campo 'id'
--
local function undoCategory(category)
  local cmd = {}
  cmd.name = "del-category"
  cmd.params = {}
  cmd.params[cmd.name] = category.id
  handlers[cmd.name](cmd)
end

---
-- Cadastra uma entidade
--
-- @param entity Tabela com os campos 'id', 'category' e 'name'
--
local function doEntity(entity)
  local cmd = {}
  cmd.name = "add-entity"
  cmd.params = {}
  cmd.params[cmd.name] = entity.id
  cmd.params.category = entity.category
  cmd.params.name = entity.name
  handlers[cmd.name](cmd)
end

---
-- Descadastra uma entidade
--
-- @param entity Tabela com os campos 'id'
--
local function undoEntity(entity)
  local cmd = {}
  cmd.name = "del-entity"
  cmd.params = {}
  cmd.params[cmd.name] = entity.id
  handlers[cmd.name](cmd)
end

---
-- Cadastra um certificado.
--
-- @param depl Tabela com os campos 'id' e 'certificate'
--
local function doCertificate(cert)
  local cmd = {}
  cmd.name = "add-certificate"
  cmd.params = {}
  cmd.params[cmd.name] = cert.id
  cmd.params.certificate = cert.certificate
  handlers[cmd.name](cmd)
end

---
-- Descadastra um certificado.
--
-- @param cert Tabela com o campo 'id'
--
local function undoCertificate(cert)
  local cmd = {}
  cmd.name = "del-certificate"
  cmd.params = {}
  cmd.params[cmd.name] = cert.id
  handlers[cmd.name](cmd)
end

---
-- Cadastra uma interface.
--
-- @param iface Tabela com um campo 'id' contendo o repID da interface.
--
local function doInterface(iface)
  local cmd = {}
  cmd.name = "add-interface"
  cmd.params = {}
  cmd.params[cmd.name] = iface.id
  handlers[cmd.name](cmd)
end

---
-- Descadastra uma interface.
--
-- @param iface Tabela com um campo 'id' contendo o repID da interface.
--
local function undoInterface(iface)
  local cmd = {}
  cmd.name = "del-interface"
  cmd.params = {}
  cmd.params[cmd.name] = iface.id
  handlers[cmd.name](cmd)
end

---
-- Concede a autorização para um conjunto de interfaces.
--
-- @param auth Tabela com o os campos 'id', identificador do membro,
-- e 'interfaces', array de repID de interfaces para autorizar.
--
local function doGrant(auth)
  local cmd = {}
  cmd.name = "set-authorization"
  cmd.params = {}
  cmd.params[cmd.name] = auth.id
  for n, iface in ipairs(auth.interfaces) do
    cmd.params.grant = iface
    handlers[cmd.name](cmd)
  end
end

---
-- Revoga autorização de um conjunto de interfaces.
--
-- @param auth Tabela com os campos 'id', identificador do membro,
-- e 'interfaces', array de repID de interfaces para revogar.
--
local function doRevoke(auth)
  local cmd = {}
  cmd.name = "set-authorization"
  cmd.params = {}
  cmd.params[cmd.name] = auth.id
  for n, iface in ipairs(auth.interfaces) do
    cmd.params.revoke = iface
    handlers[cmd.name](cmd)
  end
end

-------------------------------------------------------------------------------
-- Funções exportadas para o script Lua carregado pelo comando 'script'
-- A LINGUAGEM DO SCRIPT

---
-- Valida o comando de script 'Category' e insera na tabela 'scripts'
--
-- @param category Tabela com os campos 'id' e 'name'
--
function Category(category)
  if not (type(category) == "table" and type(category.id) == "string" and
     type(category.name) == "string")
  then
    argerror()
  end
  table.insert(scripts.Category, category)
end

---
-- Valida o comando de script 'Entity' e insera na tabela 'scripts'
--
-- @param entity Tabela com os campos 'id', 'name' e 'category'
--
function Entity(entity)
  if not (type(entity) == "table" and type(entity.id) == "string" and
     type(entity.name) == "string" and type(entity.category) == "string")
  then
    argerror()
  end
  table.insert(scripts.Entity, entity)
end

---
-- Valida o comando de script 'Certificate' e insera na tabela 'scripts'
--
-- @param cert Tabela com os campos 'id' e 'certificate'
--
function Certificate(cert)
  if not (type(cert) == "table" and type(cert.id) == "string" and
     type(cert.certificate) == "string")
  then
    argerror()
  end
  table.insert(scripts.Certificate, cert)
end

---
-- Valida o comando de script 'Interface' e insera na tabela 'scripts'
--
-- @param iface Tabela com um campo 'id' contendo o repID da interface.
--
function Interface(iface)
  if not (type(iface) == "table" and type(iface.id) == "string") then
    argerror()
  end
  table.insert(scripts.Interface, iface)
end

---
-- Valida o comando de script 'Grant' e insera na tabela 'scripts'
--
-- @param auth Tabela com o os campos 'id', identificador do membro,
-- e 'interfaces', array de repID de interfaces para autorizar.
--
function Grant(auth)
  if not (type(auth) == "table" and type(auth.id) == "string" and
    type(auth.interfaces) == "table")
  then
    argerror()
  end
  table.insert(scripts.Grant, auth)
end

---
-- Valida o comando de script 'Revoke' e insera na tabela 'scripts'
--
-- @param auth Tabela com os campos 'id', identificador do membro,
-- e 'interfaces', array de repID de interfaces para revogar.
--
function Revoke(auth)
  if not (type(auth) == "table" and type(auth.id) == "string" and
     type(auth.interfaces) == "table")
  then
    argerror()
  end
  table.insert(scripts.Revoke, auth)
end

-------------------------------------------------------------------------------


local module = {}

function module.setup(handler)
  handlers = handler
end

function module.doScript(cmd)
  if not handlers then
    stderr:write("[ERRO] Funções de execução dos comandos não definidas.\n")
    return false
  end
  local succ = readScriptFile(cmd)
  if not succ then
    return false
  end
  for _,v in ipairs(scripts.Category) do
    doCategory(v)
  end
  for _,v in ipairs(scripts.Entity) do
    doEntity(v)
  end
  for _,v in ipairs(scripts.Certificate) do
    doCertificate(v)
  end
  for _,v in ipairs(scripts.Interface) do
    doInterface(v)
  end
  for _,v in ipairs(scripts.Grant) do
    doGrant(v)
  end
  for _,v in ipairs(scripts.Revoke) do
    doRevoke(v)
  end
  return true
end

function module.undoScript(cmd)
  if not handlers then
    stderr:write("[ERRO] Funções de execução dos comandos não definidas.\n")
    return false
  end
  local succ = readScriptFile(cmd)
  if not succ then
    return false
  end
  for _,v in ipairs(scripts.Revoke) do
    doGrant(v)
  end
  for _,v in ipairs(scripts.Grant) do
    doRevoke(v)
  end
  for _,v in ipairs(scripts.Interface) do
    undoInterface(v)
  end
  for _,v in ipairs(scripts.Certificate) do
    undoCertificate(v)
  end
  for _,v in ipairs(scripts.Entity) do
    undoEntity(v)
  end
  for _,v in ipairs(scripts.Category) do
    undoCategory(v)
  end
  return true
end

return module