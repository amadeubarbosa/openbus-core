-- $Id$

local io = io
local string = string
local os = os

local ipairs = ipairs
local type = type
local dofile = dofile
local pairs = pairs
local tostring = tostring
local tonumber = tonumber

local lposix = require "lposix"
local oil = require "oil"

local Log = require "openbus.common.Log"

local oop = require "loop.base"

---
--Mecanismo de persistência de credenciais
---
module("openbus.services.accesscontrol.CredentialDB", oop.class)

FILE_SUFFIX = ".credential"
FILE_SEPARATOR = "/"

function __init(self, databaseDirectory)
  if not lposix.dir(databaseDirectory) then
    Log:service("O diretorio ["..databaseDirectory.."] nao foi encontrado. "..
        "Criando...")
    local status, errorMessage = lposix.mkdir(databaseDirectory)
    if not status then
      Log:error("Nao foi possivel criar o diretorio ["..databaseDirectory.."].")
      error(errorMessage)
    end
  end
  return oop.rawnew(self, {
    databaseDirectory = databaseDirectory,
    credentials = {},
  })
end

function retrieveAll(self)
  local credentialFiles = lposix.dir(self.databaseDirectory)
  local entries = {}
  for _, fileName in ipairs(credentialFiles) do
    if string.sub(fileName, -(#self.FILE_SUFFIX)) == self.FILE_SUFFIX then
      local entry = dofile(self.databaseDirectory..self.FILE_SEPARATOR..
          fileName)
      local credential = entry.credential
      self.credentials[credential.identifier] = true
      entries[credential.identifier] = entry
    end
  end
  return entries
end

function insert(self, entry)
  local credential = entry.credential
  if self.credentials[credential.identifier] then
    return false, "A credencial especificada ja existe."
  end
  local status, errorMessage = self:writeCredential(entry)
  if not status then
    return false, errorMessage
  end
  self.credentials[credential.identifier] = true
  return true
end

function update(self, entry)
  local credential = entry.credential
  if not self.credentials[credential.identifier] then
    return false, "A credencial especificada não existe."
  end
  return self:writeCredential(entry)
end

function delete(self, entry)
  local credential = entry.credential
  if not self.credentials[credential.identifier] then
    return false, "A credencial especificada não existe."
  end
  local status, errorMessage = self:removeCredential(entry)
  if not status then
    return false, errorMessage
  end
  self.credentials[credential.identifier] = nil
  return true
end

---------------------------------------------------------------------
-- Serializa os elementos de Lua em uma string
-- XXX Não tem nada pronto pra usar?!
---------------------------------------------------------------------
function toString(self, val)
  local t = type(val)
  if t == "table" then
    local str = '{'
    for f, s in pairs(val) do
      -- caso especial para referencia a componente
      if type(f) == "string" and f == "component" then
        str = str .. f .. "=[[" .. oil.tostring(s) .. "]],"
      else
        if not tonumber(f) then
          str = str .. f .. "="
        end
        str = str .. self:toString(s) .. ","
      end
    end
    return str .. '}'
  elseif t == "string" then
    return "[[" .. val .. "]]"
  elseif t == "number" then
    return val
  elseif t == "boolean" then
    return tostring(val)
  else -- if not tab then
    return "nil"
  end
end

function writeCredential(self, entry)
  local credential = entry.credential
  local credentialFile, errorMessage = io.open(self.databaseDirectory..
      self.FILE_SEPARATOR..credential.identifier..self.FILE_SUFFIX, "w")
  if not credentialFile then
    return false, errorMessage
  end
  credentialFile:write("return "..self:toString(entry))
  credentialFile:close()
  return true
end

function removeCredential(self, entry)
  local credential = entry.credential
  return os.remove(self.databaseDirectory..self.FILE_SEPARATOR..
      credential.identifier..self.FILE_SUFFIX)
end

function retrieveRegistryService(self)
  local regFileName = self.databaseDirectory..self.FILE_SEPARATOR..
      "registryservice"
  local f = io.open(regFileName)
  if not f then
    Log:service("Referencia ao RegistryService não persistida")
    return nil
  end
  f:close()
  local registryEntry = dofile(self.databaseDirectory..self.FILE_SEPARATOR..
      "registryservice")
  -- recupera referência ao componente
  local regIOR = registryEntry.component
  registryEntry.component = oil.newproxy(regIOR)
  Log:service("Referencia ao RegistryService recuperada")
  return registryEntry
end

function writeRegistryService(self, registryEntry)
  local regFile, errorMessage = io.open(self.databaseDirectory..
      self.FILE_SEPARATOR.."registryservice","w")
  if not regFile then
    return false, errorMessage
  end
  regFile:write("return ".. self:toString(registryEntry))
  regFile:close()
  return true
end

function deleteRegistryService(self)
  return os.remove(self.databaseDirectory..self.FILE_SEPARATOR..
      "registryservice")
end
