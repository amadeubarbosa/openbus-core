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
local type = _G.type

local array = require "table"
local insert = array.insert
local unpack = array.unpack
local sort = array.sort

local string = require "string"
local lower = string.lower
local format = string.format
local byte = string.byte
local replace = string.gsub

local io = require "io"
local read = io.read
local stderr = io.stderr
local write = io.write

local oil = require "oil"
local readfrom = oil.readfrom
local writeto = oil.writeto

local hash = require "lce.hash"
local md5 = hash.md5

local Arguments = require "loop.compiler.Arguments"
local Matcher = require "loop.debug.Matcher"
local Viewer = require "loop.debug.Viewer"
local Verbose = require "loop.debug.Verbose"

local argcheck = require "openbus.util.argcheck"
local msg = require "openbus.util.messages"
local log = require "openbus.util.logger"
local sandbox = require "openbus.util.sandbox"
local newsandbox = sandbox.create
local oo = require "openbus.util.oo"
local class = oo.class

local script = require "openbus.core.admin.script"
local addiface = script.addiface
local categories = script.categories
local certents = script.certents
local delcategory = script.delcategory
local delcert = script.delcert
local delentity = script.delentity
local deliface = script.deliface
local getcategory = script.getcategory
local getcert = script.getcert
local getentity = script.getentity
local ifaces = script.ifaces
local setcategory = script.setcategory
local setcert = script.setcert
local setentity = script.setentity

local viewer = Viewer{
  indentation = "",
  linebreak = " ",
  nolabels = true,
  noindices = true,
}


local ask do
  local EveryTime = {
    a = true,
    al = true,
    all = true,
    none = false,
  }
  local OnlyOnce = {
    [""] = true,
    y = true,
    ye = true,
    yes = true,
    no = false,
    n = false,
  }
  
  function ask(self, question, fields)
    local result = self.quiet
    if result == nil then
      result = self.answers[question]
    end
    while result == nil do
      write(question:tag(fields), "? [Yes|No|All|None] ")
      local answer = lower(read() or "")
      result = EveryTime[answer]
      if result ~= nil then
        self.answers[question] = result
      else
        result = OnlyOnce[answer]
      end
    end
    return result
  end
end

local function comparekeys(one, other)
  return (one.id or one) < (other.id or other)
end

local function sortedkeys(map)
  local list = {}
  for key in pairs(map) do
    list[#list+1] = key
  end
  sort(list, comparekeys)
  return list
end

local function isorted(map)
  return ipairs(sortedkeys(map))
end

local function textbox(self, message, default)
  if self.quiet ~= nil then return default end
  local result
  repeat
    write(message,": ")
    result = read()
  until result ~= nil
  return result == "" and default or result
end

local function combobox(self, message, options, default)
  if self.quiet ~= nil then return default end
  write(message,": \n")
  write("  [0]  Other value\n")
  local keys = sortedkeys(options)
  for index, key in ipairs(keys) do
    write("[",index,"]  '",tostring(options[key]),"'\n")
  end
  local result
  repeat
    write("Pick an option: ")
    result = tonumber(read())
  until result ~= nil
  result = options[ keys[result] ]
  if result == nil then
    result = textbox(self, "Other value", default)
  end
  return result
end

local function replacefield(self, tag, id, field, current, replacement)
  if current == nil then
    current = replacement
  elseif current ~= replacement then
    local msgtags = {
      tag = tag,
      id = id,
      current = field ~= "certificate" and current or nil,
      replacement = field ~= "certificate" and replacement or nil,
    }
    local message
    if ask(self, msg.ReplaceTagField, msgtags) then
      message = msg.TagFieldReplaced
      current = replacement
    else
      message = msg.ConflictingTagFieldDiscarded
    end
    desc.log:warning(message:tag(msgtags))
  end
  return current
end

local TagImporter = {}

function TagImporter.Certificate(self, def)
  local path = def.certificate
  local certdata
  while true do
    local errmsg
    certdata, errmsg = readfrom(path, "b")
    if certdata == nil then
      self.log:failure(msg.CertificateFileNotFound:tag{path=path})
      local retry = ask(self, msg.ReplaceMissingCertificate, {
        id = def.id,
        certificate = path,
        error = errmsg,
      })
      if retry then
        local newpath = textbox(self, "Certificate Path", path)
        if newpath ~= path then
          path = newpath
        else
          retry = false
        end
      end
      if not retry then
        self.log:warning(msg.CertificateWithMissingFileDiscarded:tag{
          entity = def.id,
          certificate = def.certificate,
        })
        return false
      end
      self.log:warning(msg.CertificateFileChanged:tag{
        id = def.id,
        original = def.certificate,
        changed = path,
      })
    else
      break
    end
  end
  local current = self.certificates[def.id]
  certdata = replacefield(self,
                          "Certificate",
                          def.id,
                          "certificate",
                          current,
                          certdata)
  self.certificates[def.id] = certdata
  return true
end

function TagImporter.Interface(self, def)
  self.interfaces[def.id] = {}
  return true
end

function TagImporter.Grant(self, def)
  local entities = self.entities
  local entity = entities[def.id]
  if entity == nil then
    if not ask(self, msg.DeclareGrantedEntity, def)
    or not TagImporter.Entity(self, {
      id = def.id,
      name = textbox(self, "Entity Name", def.id),
      category = combobox(self, "Entity Category", self.categories, def.id),
    }) then
      self.log:warning(msg.GrantOfUndeclaredEntityDiscarded:tag{
        entity = def.id,
        interfaces = def.interfaces,
      })
      return false
    end
    entity = entities[def.id]
    self.log:warning(msg.GrantedEntityDeclared:tag{
      entity = entity.id,
      name = entity.name,
      category = entity.category.id,
    })
  end
  local interfaces = self.interfaces
  local grantedinterfaces = def.interfaces
  if grantedinterfaces ~= nil then
    for index, ifaceid in ipairs(grantedinterfaces) do
      local authorized = interfaces[ifaceid]
      if authorized == nil then
        if not ask(self, msg.DeclareGrantedInterface, def)
        or not TagImporter.Interface(self, { id = ifaceid }) then
          self.log:warning(msg.GrantOfUndeclaredInterfaceDiscarded:tag{
            entity = entity.id,
            interface = ifaceid,
          })
          goto nextinterface
        end
        self.log:warning(msg.GrantedInterfaceDeclared:tag{repid=ifaceid})
        authorized = interfaces[ifaceid]
      end
      authorized[entity] = true
      entity.interfaces[ifaceid] = true
      ::nextinterface::
    end
  end
  return true
end

function TagImporter.Entity(self, def)
  local entities = self.entities
  local entity = entities[def.id]
  if entity == nil then
    entity = {
      id = def.id,
      name = def.name,
      category = nil, -- defined below
      interfaces = {},
    }
    entities[def.id] = entity
  else
    entity.name = replacefield(self, "Entity", def.id,
                               "name", entity.name, def.name)
    def.category = replacefield(self, "Entity", def.id,
                                "category", entity.category.id, def.category)
  end
  -- Category
  local categories = self.categories
  local category = categories[def.category]
  if category == nil then
    if not ask(self, msg.DeclareReferencedCategory, def)
    or not TagImporter.Category(self, {
      id = def.category,
      name = textbox(self, "Category Name", def.category),
    }) then
      self.log:warning(msg.EntityOfUndeclaredCategoryDiscarded:tag{
        entity = def.id,
        name = def.name,
        category = def.category,
      })
      return false
    end
    category = categories[def.category]
    self.log:warning(msg.ReferencedCategoryDeclared:tag{
      category = category.id,
      name = category.name,
    })
  end
  entity.category = category
  category.entities[entity] = true
  -- Interfaces
  return TagImporter.Grant(self, def)
end

function TagImporter.Category(self, def)
  local categories = self.categories
  local category = categories[def.id]
  if category == nil then
    category = {
      id = def.id,
      name = def.name,
      entities = {},
    }
    categories[def.id] = category
  else
    category.name = replacefield(self, "Category", def.id,
                                 "name", category.name, def.name)
  end

  local success = true
  local entities = self.entities
  local newentities = def.entities
  if newentities ~= nil then
    for _, entdef in ipairs(newentities) do
      entdef.category = category.id
      success = success and TagImporter.Entity(self, entdef)
    end
  end
  return success
end

local DataFields = {
  "certificates",
  "interfaces",
  "categories",
}

local Description = class()

function Description:__init()
  self.answers = {}
  self.certificates = {}
  self.interfaces = {}
  self.categories = {}
  self.entities = {}
  local log = Verbose{
    timed = true,
    viewer = log.viewer,
    groups = {
      {"failure"},
      {"warning"},
      {"success"},
    },
  }
  log:settimeformat("%d/%m/%Y %H:%M:%S")
  log:flag("print", true)
  log:level(3)
  self.log = log
end

do
  local TagOrder = {
    "Certificate",
    "Interface",
    "Category",
    "Entity",
    "Grant",
  }

  local TagFormat = {
    Certificate = {
      id = "string",
      certificate = "string",
    }, 
    Interface = {
      id = "string",
    },
    Category = {
      id = "string",
      name = "string",
      entities = {
        {
          id = "string",
          name = "string",
          interfaces = {"string"},
        },
      }
    },
    Entity = {
      id = "string",
      name = "string",
      category = "string",
    },
    Grant = {
      id = "string",
      interfaces = {"string"},
    },
  }

  local function extractfields(value, typespec, prefix)
    local valtype = luatype(value)
    if valtype == typespec then
      return value
    elseif luatype(typespec) == "table" and (valtype == "table" or value == nil) then
      local result = {}
      prefix = prefix and prefix.."." or ""
      local itemtype = typespec[1]
      if itemtype == nil then
        for fieldname, typespec in pairs(typespec) do
          result[fieldname] = extractfields(value[fieldname], typespec, prefix..fieldname)
        end
      elseif value ~= nil then
        for index, value in ipairs(value) do
          result[index] = extractfields(value, itemtype, prefix.."["..index.."]")
        end
      end
      return result
    end
    error("field '"..prefix.."' must be '"..tostring(typespec).."', but is '"..valtype.."'")
  end

  function Description:import(path, ...)
    local env = setmetatable(newsandbox(), {__index = _G})
    local loaded = {}
    for index, tag in ipairs(TagOrder) do
      local list = {}
      loaded[tag] = list
      env[tag] = function (fields)
        insert(list, extractfields(fields, TagFormat[tag]))
      end
    end
    local result, errmsg = loadfile(path, "t" , env)
    if result ~= nil then
      result, errmsg = pcall(result, ...)
      if result then
        for _, tag in ipairs(TagOrder) do
          local list = loaded[tag]
          local importer = TagImporter[tag]
          if importer ~= nil then
            for index, def in ipairs(list) do
              importer(self, def)
            end
          end
        end
        return true
      end
    end
    self.log:failure(errmsg)
    return false
  end
end

do
  local function tohexa(char)
    return format("%.2x", byte(char))
  end

  local TagDumper = {}

  function TagDumper:certificates(output, id, certdata, certdir, mode)
    local certid = replace(md5(certdata), ".", tohexa)
    local stored = readfrom(certdir.."/"..certid..".crt", "b")
    if stored ~= certdata then
      if stored ~= nil then
        local i = 0
        repeat
          i = i + 1
          stored = readfrom(certdir.."/"..certid.."-"..i..".crt", "b")
        until stored == certdata
        certid = certid.."-"..i
      end
      self.log:success(msg.CertificateDumped:tag{
        entity = id,
        certificate = certid,
      })
      assert(writeto(certdir.."/"..certid..".crt", certdata, "wb"))
    end
    output:write("Certificate{id=[[",id,"]],certificate=certdir..[[/",certid,".crt]]}\n")
  end

  function TagDumper:interfaces(output, id, entities, certdir, mode)
    if mode == "legacy" or mode ~= "compact" or next(entities) == nil then
      output:write("Interface{id=[[",id,"]]}\n")
    end
  end

  function TagDumper:categories(output, id, category, certdir, mode)
    output:write([=[
Category{
  id=[[]=],id,[=[]],
  name=[[]=],category.name,[=[]],
]=])
    if mode == "legacy" then output:write("}\n") end
    local entities = category.entities
    if next(entities) ~= nil then
      local prefix
      if mode == "legacy" then
        prefix = "  "
      else
        prefix = "      "
        output:write("  entities={\n")
      end
      for _, entity in isorted(entities) do
        if mode == "legacy" then
          output:write("Entity{\n")
        else
          output:write("    {\n")
        end
        output:write(prefix, "id=[[",entity.id,"]],\n")
        output:write(prefix, "name=[[",entity.name,"]],\n")
        if mode == "legacy" then
          output:write(prefix, "category=[[",entity.category.id,"]],\n")
        end
        if mode == "legacy" then output:write("}\n") end
        local interfaces = entity.interfaces
        if next(interfaces) ~= nil then
          if mode == "legacy" then
            output:write("Grant{\n  id=[[",entity.id,"]],\n")
          end
          output:write(prefix, "interfaces={\n")
          for _, ifaceid in isorted(interfaces) do
            output:write(prefix, "  [[", ifaceid, "]],\n")
          end
          output:write(prefix, "},\n")
          if mode == "legacy" then output:write("}\n") end
        end
        if mode ~= "legacy" then output:write("    },\n") end
      end
      if mode ~= "legacy" then output:write("  },\n") end
    end
    if mode ~= "legacy" then output:write("}\n") end
  end

  function Description:export(path, certdir, ...)
    local output = assert(io.open(path, "w"))
    if next(self.certificates) ~= nil then
      output:write(format("local certdir = ... or %q\n", certdir))
    end
    for _, field in ipairs(DataFields) do
      local list = self[field]
      local dumper = TagDumper[field]
      for _, id in isorted(list) do
        dumper(self, output, id, list[id], certdir, ...)
      end
    end
    output:close()
    return true
  end
end

do
  local function logresult(self, success, okmsg, failmsg, msgtags)
    if success then
      self.log:success(okmsg:tag(msgtags))
    else
      self.log:warning(failmsg:tag(msgtags))
    end
  end

  local TagUploader = {}
  function TagUploader:certificates(id, certdata)
    setcert(id, certdata)
    self.log:success(msg.CertificateRegistered:tag{entity=id})
  end
  function TagUploader:interfaces(id)
    addiface(id)
    self.log:success(msg.InterfaceRegistered:tag{repid=id})
  end
  function TagUploader:categories(id, category)
    local newcat = setcategory(id, category.name)
    self.log:success(msg.CategoryRegistered:tag{
      category = id,
      name = category.name,
    })
    local entities = category.entities
    for _, entity in isorted(entities) do
      local newent = getentity(entity.id)
      if newent == nil then
        newent = newcat:addentity(entity.id, entity.name)
        self.log:success(msg.EntityRegistered:tag{
          entity = entity.id,
          name = entity.name,
        })
      else
        local othercat = newent.category:_get_id()
        if othercat ~= id then
          self.log:failure(msg.EntityAlreadyOnOtherCategory:tag{
            entity = entity.id,
            category = othercat,
          })
        else
          setentity(newent, entity.name)
          self.log:success(msg.EntityNameChanged:tag{
            entity = entity.id,
            name = entity.name,
          })
        end
      end
      local interfaces = entity.interfaces
      for _, ifaceid in isorted(interfaces) do
        logresult(self, newent:grant(ifaceid),
                        msg.InterfaceGranted,
                        msg.InterfaceAlreadyGranted,
                        {entity=entity.id,repid=ifaceid})
      end
    end
  end

  local TagReverter = {certificates=delcert,interfaces=deliface}
  function TagReverter:certificates(id, certdata)
    logresult(self, delcert(id, certdata),
                    msg.EntityCertificateRemoved,
                    msg.NoCertificateForEntity,
                    {entity=id})
  end
  function TagReverter:interfaces(id)
    logresult(self, deliface(id),
                    msg.InterfaceRemoved,
                    msg.InterfaceNotFound,
                    {repid=id})
  end
  function TagReverter:categories(id, category)
    local entities = category.entities
    for _, entity in isorted(entities) do
      local newent = getentity(entity.id)
      if newent ~= nil then
        for _, ifaceid in isorted(entity.interfaces) do
          logresult(self, newent:revoke(ifaceid),
                          msg.InterfaceGrantRevoked,
                          msg.InterfaceNotGranted,
                          {entity=entity.id,repid=repid})
        end
      end
      logresult(self, delentity(entity.id),
                      msg.EntityRemoved,
                      msg.EntityNotFound,
                      {entity=entity.id})
    end
    logresult(self, delcategory(id),
                    msg.CategoryRemoved,
                    msg.CategoryNotFound,
                    {category=id})
  end

  local function loadoperation(self, inc, funcs)
    local start, finish = 1, #DataFields
    if inc < 0 then start, finish = finish, start end
    for i = start, finish, inc do
      local field = DataFields[i]
      local list = self[field]
      local func = funcs[field]
      for _, id in isorted(list) do
        func(self, id, list[id])
      end
    end
    return true
  end

  function Description:upload()
    return loadoperation(self, 1, TagUploader)
  end

  function Description:revert()
    return loadoperation(self, -1, TagReverter)
  end
end

do
  function Description:download()
    for _, entity in ipairs(certents()) do
      self.certificates[entity] = assert(getcert(entity))
    end
    for _, interface in ipairs(ifaces()) do
      TagImporter.Interface(self, { id = interface })
    end
    for _, category in ipairs(categories()) do
      local catdef = {
        id = category.id,
        name = category.name,
        entities = {},
      }
      for index, entity in ipairs(category:entities()) do
        catdef.entities[index] = {
          id = entity.id,
          name = entity.name,
          interfaces = entity:ifaces(),
        }
      end
      TagImporter.Category(self, catdef)
    end
    return true
  end
end

argcheck.convertclass(Description, {
  import = { "string" },
  export = { "string", "string" },
  download = {},
  upload = {},
  revert = {},

  --certents = {},
  --getcert = { "string" },
  --setcert = { "string", "string" },
  --delcert = { "string" },
  --
  --categories = {},
  --getcategory = { "string|table" },
  --setcategory = { "string|table", "string" },
  --delcategory = { "string|table" },
  --
  --entities = {},
  --getentity = { "string|table" },
  --setentity = { "string|table", "string" },
  --delentity = { "string|table" },
  --
  --ifaces = {},
  --addiface = { "string" },
  --deliface = { "string" },
})

return Description
