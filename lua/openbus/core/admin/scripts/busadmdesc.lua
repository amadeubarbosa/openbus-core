#!/usr/bin/env busadmin

local _G = require "_G"
local assert = _G.assert
local error = _G.error
local ipairs = _G.ipairs
local loadfile = _G.loadfile
local luatype = _G.type
local pairs = _G.pairs
local pcall = _G.pcall
local select = _G.select
local setmetatable = _G.setmetatable
local tostring = _G.tostring

local array = require "table"
local unpack = array.unpack

local io = require "io"
local stderr = io.stderr

local os = require "os"
local exit = os.exit

local Arguments = require "loop.compiler.Arguments"

local Viewer = require "loop.debug.Viewer"

local msg = require "openbus.util.messages"
local log = require "openbus.util.logger"
local sandbox = require "openbus.util.sandbox"
local newsandbox = sandbox.create

local viewer = Viewer{
  indentation = "",
  linebreak = " ",
  nolabels = true,
  noindices = true,
}

local args = Arguments{
  entity = "admin",
  password = "",
  domain = "",
  verbose = 2,
  unload = false,
  help = false,
}
args._alias = {
  e = "entity",
  p = "password",
  d = "domain",
  v = "verbose",
  u = "unload",
  h = "help",
}


-- parse command line parameters
local argidx, errmsg = args(...)
if argidx == nil or argidx > select("#", ...) then
  if argidx ~= nil then
    errmsg = msg.DescriptorPathMissing
  end
  stderr:write(errmsg,"\n")
  args.help = true
end

if args.help then
  stderr:write([[
Usage:  [options] <caminho do descritor> [argumentos do descritor]
Options:

  -e, -entity <entity name>        entidade de autenticação (default=admin)
  -p, -password <entity password>  senha de autenticação
  -d, -domain <password domain>    domínio da senha de autenticação
  -v, -verbose <log level>         0=nada, 1=erros, 2=tudo (default=2)
  -u, -unload                      desfaz as definições do descritor
  -h, -help                        exibe esta mensagem e encerra a execução

]])
  return 1
end

if args.verbose > 0 then log:flag("  OK  ", true) end
if args.verbose > 1 then log:flag("FAILED", true) end

if args.password == "" then args.password = nil end
if args.domain == "" then args.domain = nil end

local exitcode = 0

local function tryaddentity(entid, name, catid)
  local category = getcategory(catid) or error("category not found", 2)
  local entity = getentity(entid)
  if entity == nil then
    category:addentity(entid, name)
  elseif entity.category:_get_id() ~= category.id then
    error("entity "..entity.id.." already registered on category "..category.id)
  else
    setentity(entity, name)
  end
end

local function addmanyifaces(entid, ifaces)
  local entity = getentity(entid) or error("entity not found", 2)
  for _, iface in ipairs(ifaces) do
    entity:grant(iface)
  end
end

local function delmanyifaces(entid, ifaces)
  local entity = getentity(entid)
  if entity ~= nil then
    for _, iface in ipairs(ifaces) do
      entity:revoke(iface)
    end
  end
end

local Definitions = {
  {
    tag = "Category",
    fields = {
      id = "string",
      name = "string",
    },
    load = {func = setcategory, params = {"id", "name"}},
    unload = {func = delcategory, params = {"id"}},
  }, {
    tag = "Entity",
    fields = {
      id = "string",
      name = "string",
      category = "string",
    },
    load = {func = tryaddentity, params = {"id", "name", "category"}},
    unload = {func = delentity, params = {"id"}},
  }, {
    tag = "Interface",
    fields = {
      id = "string",
    },
    load = {func = addiface, params = {"id"}},
    unload = {func = deliface, params = {"id"}},
  }, {
    tag = "Grant",
    fields = {
      id = "string",
      interfaces = { "string" },
    },
    load = {func = addmanyifaces, params = {"id", "interfaces"}},
    unload = {func = delmanyifaces, params = {"id", "interfaces"}},
  }, {
    tag = "Revoke",
    fields = {
      id = "string",
      interfaces = { "string" },
    },
    load = {func = delmanyifaces, params = {"id", "interfaces"}},
    unload = {func = addmanyifaces, params = {"id", "interfaces"}},
  }, {
    tag = "Certificate",
    fields = {
      id = "string",
      certificate = "string",
    },
    load = {func = setcert, params = {"id", "certificate"}},
    unload = {func = delcert, params = {"id"}},
  },
}

local function checkfields(value, typespec, prefix)
  if luatype(typespec) == "table" then
    prefix = prefix and prefix.."." or ""
    if #typespec == 0 then
      for fieldname, typespec in pairs(typespec) do
        checkfields(value[fieldname], typespec, prefix..fieldname)
      end
    else
      typespec = typespec[1]
      for index, value in ipairs(value) do
        checkfields(value, typespec, prefix.."["..index.."]")
      end
    end
  elseif luatype(value) ~= typespec then
    error("field '"..prefix.."' must be '"..typespec.."', but is '"..luatype(value).."'")
  end
end

local op, start, finish, increment = "load", 1, #Definitions, 1
if args.unload then
  op, start, finish, increment = "unload", finish, start, -1
end

local env = setmetatable(newsandbox(), {__index = _G})
local defs = {}
for index, info in ipairs(Definitions) do
  env[info.tag] = function (fields)
    checkfields(fields, info.fields)
    local list = defs[info.tag]
    if list == nil then
      list = { fields }
      defs[info.tag] = list
    else
      list[#list+1] = fields
    end
  end
end

local path = select(argidx, ...)
local loader, errmsg = loadfile(path, "t" , env)
if loader ~= nil then
  local ok, errmsg = pcall(loader, select(argidx+1, ...))
  if ok then
    local ok, errmsg = pcall(login, args.entity, args.password, args.domain)
    if ok then
      for i = start, finish, increment do
        local info = Definitions[i]
        local list = defs[info.tag]
        if list ~= nil then
          local opinfo = info[op]
          for _, fields in ipairs(list) do
            local params = {}
            for index, fieldname in ipairs(opinfo.params) do
              params[index] = fields[fieldname]
            end
            local ok, result = pcall(opinfo.func, unpack(params))
            local logtag
            if ok then
              logtag = "  OK  "
              result = ""
            else
              logtag = "FAILED"
              result = ": "..result
              exitcode = 5
            end
            log[logtag](log, op," ",info.tag," ",viewer:tostring(params),result)
          end
        end
      end
    else
      log:FAILED(msg.LoginFailure:tag{error=errmsg})
      exitcode = 4
    end
  else
    log:FAILED(errmsg)
    exitcode = 3
  end
else
  log:FAILED(errmsg)
  exitcode = 2
end

return exitcode
