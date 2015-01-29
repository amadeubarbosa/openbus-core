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

local Arguments = require "loop.compiler.Arguments"

local Viewer = require "loop.debug.Viewer"

local msg = require "openbus.util.messages"
local log = require "openbus.util.logger"
local server = require "openbus.util.server"
local readfrom = server.readfrom
local sandbox = require "openbus.util.sandbox"
local newsandbox = sandbox.create

local viewer = Viewer{
  indentation = "",
  linebreak = " ",
  nolabels = true,
  noindices = true,
}

local args = Arguments{
  verbose = 2,
  unload = false,
  help = false,
}
args._alias = {
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

  -v, -verbose <log level>         0=nada, 1=erros, 2=tudo (default=2)
  -u, -unload                      desfaz as definições do descritor
  -h, -help                        exibe esta mensagem e encerra a execução

]])
  return 1
end

if args.verbose > 0 then log:flag("  OK  ", true) end
if args.verbose > 1 then log:flag("FAILED", true) end

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
      {name = "id", type = "string"},
      {name = "name", type = "string"},
    },
    load = setcategory,
    unload = delcategory,
  }, {
    tag = "Entity",
    fields = {
      {name = "id", type = "string"},
      {name = "name", type = "string"},
      {name = "category", type = "string"},
    },
    load = tryaddentity,
    unload = delentity,
  }, {
    tag = "Interface",
    fields = {
      {name = "id", type = "string"},
    },
    load = addiface,
    unload = deliface,
  }, {
    tag = "Grant",
    fields = {
      {name = "id", type = "string"},
      {name = "interfaces", type = {"string"}},
    },
    load = addmanyifaces,
    unload = delmanyifaces,
  }, {
    tag = "Revoke",
    fields = {
      {name = "id", type = "string"},
      {name = "interfaces", type = {"string"}},
    },
    load = delmanyifaces,
    unload = addmanyifaces,
  }, {
    tag = "Certificate",
    fields = {
      {name = "id", type = "string"},
      {name = "certificate", type = "string"},
    },
    load = function(id, path) return setcert(id, assert(readfrom(path))) end,
    unload = delcert,
  },
}

local function checkfields(value, typespec, prefix)
  if luatype(typespec) == "table" then
    prefix = prefix and prefix.."." or ""
    if type(typespec[1]) == "table" then
      for _, field in pairs(typespec) do
        local fieldname, typespec = field.name, field.type
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

local op, start, finish, increment = "load", 1, #Definitions, 1
if args.unload then
  op, start, finish, increment = "unload", finish, start, -1
end

local path = select(argidx, ...)
local loader, errmsg = loadfile(path, "t" , env)
if loader ~= nil then
  local ok, errmsg = pcall(loader, select(argidx+1, ...))
  if ok then
    local ok, errmsg = whoami()
    if not ok then
      io.write("Bus Ref.: ")
      local busref = assert(io.read())
      io.write("Entity: ")
      local entity = assert(io.read())
      ok, errmsg = pcall(login, busref, entity)
    end
    if ok then
      for i = start, finish, increment do
        local info = Definitions[i]
        local list = defs[info.tag]
        if list ~= nil then
          for _, fields in ipairs(list) do
            local params = {}
            for index, field in ipairs(info.fields) do
              params[index] = fields[field.name]
            end
            local ok, result = pcall(info[op], unpack(params))
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
