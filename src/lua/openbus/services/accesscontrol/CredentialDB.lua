-----------------------------------------------------------------------------
-- Mecanismo de persistência de credenciais
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local oop = require "loop.base"
local log = require "openbus.common.Log"

require "posix"

local FILE_SUFFIX = ".credential"
local FILE_SEPARATOR = "/"

CredentialDB = oop.class{
  entries = {},
}

function CredentialDB:__init(databaseDirectory)
  local credentialFiles = posix.dir(databaseDirectory)
  if credentialFiles == nil then
    log:service("O diretorio ["..databaseDirectory.."] nao foi encontrado. Criando...")
    local status, errorMessage = posix.mkdir(databaseDirectory)
    if not status then
      log:error("Nao foi possivel criar o diretorio ["..databaseDirectory.."].")
      error(errorMessage)
    else
      credentialFiles = {}
    end
  end
  self = oop.rawnew(self, {databaseDirectory = databaseDirectory,})
  for _, fileName in ipairs(credentialFiles) do
    if string.sub(fileName, -(#FILE_SUFFIX)) == FILE_SUFFIX then
      local entry = dofile(databaseDirectory..FILE_SEPARATOR..fileName)
      local credential = entry.credential
      self.entries[credential.identifier] = entry
    end
  end
  return self
end

function CredentialDB:insert(entry)
  local credential = entry.credential
  if self.entries[credential.identifier] then
    return false, "A credencial especificada ja existe."
  end
  local status, errorMessage = self:writeCredential(entry)
  if not status then
    return false, errorMessage
  end
  self.entries[credential.identifier] = self:dupEntry(entry)
  return true
end

function CredentialDB:update(entry)
  local credential = entry.credential
  if not self.entries[credential.identifier] then
    return false, "A credencial especificada nao existe."
  end
  return self:writeCredential(entry)
end

function CredentialDB:delete(entry)
  local credential = entry.credential
  if not self.entries[credential.identifier] then
    return false, "A credencial especificada nÃ£o existe."
  end
  local status, errorMessage = self:removeCredential(entry)
  if not status then
    return false, errorMessage
  end
  self.entries[credential.identifier] = nil
  return true
end

function CredentialDB:selectAll()
  return self.entries
end

---------------------------------------------------------------------
-- Serializa os elementos de Lua em uma string
-- XXX Não tem nada pronto pra usar?!
---------------------------------------------------------------------
function CredentialDB:toString(val)
  local t = type(val)
  if t == "table" then
    local str = '{'
    for f, s in pairs(val) do
      if not tonumber(f) then
        str = str .. "[\"" .. f .. "\"]="
      else
        str = str .. "["   .. f .. "]="
      end
      str = str .. self:toString(s) .. ","
    end
    return str .. '}'
  elseif t == "string" then
    return "[[" .. val .. "]]"
  elseif t == "number" then
    return val
  else -- if not tab then
    return "nil"
  end
end

---------------------------------------------------------------------
-- Duplica uma entrada
---------------------------------------------------------------------
function CredentialDB:dupEntry(entry)
  if type(entry) ~= "table" then
    return entry
  end
  local new_entry = {}
  for i, v in pairs(entry) do
    new_entry[i] = self:dupEntry(v)
  end
  return new_entry
end

function CredentialDB:writeCredential(entry)
  local credential = entry.credential
  local credentialFile, errorMessage = io.open(self.databaseDirectory..FILE_SEPARATOR..credential.identifier..FILE_SUFFIX, "w")
  if not credentialFile then
    return false, errorMessage
  end
  credentialFile:write("return ".. self:toString(entry))
  credentialFile:close()
  return true
end

function CredentialDB:removeCredential(entry)
  local credential = entry.credential
  return os.remove(self.databaseDirectory..FILE_SEPARATOR..credential.identifier..FILE_SUFFIX)
end
