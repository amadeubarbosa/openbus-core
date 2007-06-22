-----------------------------------------------------------------------------
-- Mecanismo de persistência de credenciais
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local oop = require "loop.base"
local log = require "openbus.common.Log"

require "posix"
require "oil"

local FILE_SUFFIX = ".credential"
local FILE_SEPARATOR = "/"

CredentialDB = oop.class{
  credentials = {},
}

function CredentialDB:__init(databaseDirectory)
  self = oop.rawnew(self, {databaseDirectory = databaseDirectory,})
  if not posix.dir(databaseDirectory) then
    log:service("O diretorio ["..databaseDirectory.."] nao foi encontrado. Criando...")
    local status, errorMessage = posix.mkdir(databaseDirectory)
    if not status then
      log:error("Nao foi possivel criar o diretorio ["..databaseDirectory.."].")
      error(errorMessage)
    end
  end
  return self
end

function CredentialDB:retrieveAll()
  local credentialFiles = posix.dir(self.databaseDirectory)
  local entries = {}
  for _, fileName in ipairs(credentialFiles) do
    if string.sub(fileName, -(#FILE_SUFFIX)) == FILE_SUFFIX then
      local entry = dofile(self.databaseDirectory..FILE_SEPARATOR..fileName)
      local credential = entry.credential
      self.credentials[credential.identifier] = true
      entries[credential.identifier] = entry
    end
  end
  return entries
end

function CredentialDB:insert(entry)
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

function CredentialDB:update(entry)
  local credential = entry.credential
  if not self.credentials[credential.identifier] then
    return false, "A credencial especificada não existe."
  end
  return self:writeCredential(entry)
end

function CredentialDB:delete(entry)
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
function CredentialDB:toString(val)
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

function CredentialDB:retrieveRegistryService()
  local regFileName = self.databaseDirectory..FILE_SEPARATOR.."registryservice"
  local f = io.open(regFileName)
  if not f then
    log:service("Referencia ao RegistryService não persistida")
    return nil
  end
  f:close()
  local registryEntry = dofile(self.databaseDirectory..FILE_SEPARATOR..
                               "registryservice")
  -- recupera referência ao componente
  local regIOR = registryEntry.component
  registryEntry.component = oil.newproxy(regIOR)
  log:service("Referencia ao RegistryService recuperada")
  return registryEntry
end

function CredentialDB:writeRegistryService(registryEntry)
  local regFile, errorMessage = 
    io.open(self.databaseDirectory..FILE_SEPARATOR.."registryservice","w")
  if not regFile then
    return false, errorMessage
  end
  regFile:write("return ".. self:toString(registryEntry))
  regFile:close()
  return true
end

function CredentialDB:deleteRegistryService()
  return os.remove(self.databaseDirectory..FILE_SEPARATOR.."registryservice")
end
