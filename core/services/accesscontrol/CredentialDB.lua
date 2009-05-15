-- $Id$

local io = io
local string = string
local os = os

local error = error

local lfs = require "lfs"
local oil = require "oil"
local orb = oil.orb

local FileStream = require "loop.serial.FileStream"

local Log = require "openbus.common.Log"

local oop = require "loop.base"

---
--Mecanismo de persistência de credenciais
---
module("core.services.accesscontrol.CredentialDB", oop.class)

FILE_SUFFIX = ".credential"
FILE_SEPARATOR = "/"

---
--Cria um banco de dados de credenciais.
--
--@param databaseDirectory O diretório que será utilizado para armazenar as
--credenciais.
--
--@return O banco de dados de credenciais.
---
function __init(self, databaseDirectory)
  local mode = lfs.attributes(databaseDirectory, "mode")
  if not mode then
    Log:service("O diretorio ["..databaseDirectory.."] nao foi encontrado. "..
        "Criando...")
    local status, errorMessage = lfs.mkdir(databaseDirectory)
    if not status then
      Log:error("Nao foi possivel criar o diretorio ["..databaseDirectory.."]: "..errorMessage)
      error(errorMessage)
    end
  end
  return oop.rawnew(self, {
    databaseDirectory = databaseDirectory,
    credentials = {},
  })
end

---
--Obtém todas as credenciais.
--
--@return As credenciais.
---
function retrieveAll(self)
  local credentialFiles = lfs.dir(self.databaseDirectory)
  local entries = {}
  for fileName in credentialFiles do
    if string.sub(fileName, -(#self.FILE_SUFFIX)) == self.FILE_SUFFIX then
      local credentialFile = io.open(self.databaseDirectory..self.FILE_SEPARATOR..fileName)
      local stream = FileStream{
        file = credentialFile,
      }
      local entry = stream:get()
      credentialFile:close()

      local credential = entry.credential
      self.credentials[credential.identifier] = true

      -- caso especial para referencias a membros
      if entry.component then
        entry.component = orb:newproxy(entry.component) 
      end

      entries[credential.identifier] = entry
    end
  end
  return entries
end

---
--Insere uma entrada no banco de dados.
--
--@param entry A credencial.
--
--@return true caso a credencial tenha sido inserida, ou false e uma mensagem
--de erro, caso contrário.
---
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

---
--Atualiza uma credencial.
--
--@param entry A credencial.
--
--@return true caso a credencial seja atualizada, ou false e uma mensagem de
--erro, caso contrário.
---
function update(self, entry)
  local credential = entry.credential
  if not self.credentials[credential.identifier] then
    return false, "A credencial especificada não existe."
  end
  return self:writeCredential(entry)
end

---
--Remove uma credencial.
--
--@param entry A credencial.
--
--@return true caso a credencial tenha sido removida, ou false e uma mensagem de
--erro, caso contrário.
---
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

---
--Escreve a credencial em arquivo.
--
--@param registryEntry A credencial.
--
--@return true caso o arquivo seja gerado, ou false e uma mensagem de erro,
---
function writeCredential(self, entry)
  local credential = entry.credential
  local credentialFile, errorMessage = io.open(self.databaseDirectory..
      self.FILE_SEPARATOR..credential.identifier..self.FILE_SUFFIX, "w")
  if not credentialFile then
    return false, errorMessage
  end

  local stream = FileStream{
    file = credentialFile,
    getmetatable = false,
  }
  local component = entry.component
  if component then
    stream[component] = "'"..orb:tostring(component).."'"
  end
  stream:put(entry)
  
  credentialFile:close()

  return true
end

---
--Remove o arquivo da credencial.
--
--@param entry A credencial.
--
--@return Caso o arquivo tenha sido removido, retorna nil e uma mensagem de erro.
---
function removeCredential(self, entry)
  local credential = entry.credential
  return os.remove(self.databaseDirectory..self.FILE_SEPARATOR..
      credential.identifier..self.FILE_SUFFIX)
end

