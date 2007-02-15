local oop = require "loop.base"

require "posix"

local FILE_SUFFIX = ".credential"
local FILE_SEPARATOR = "/"

CredentialDB = oop.class{
  entries = {},
}

function CredentialDB:__init(databaseDirectory)
  local credentialFiles = posix.dir(databaseDirectory)
  if credentialFiles == nil then
    print("O diretorio ["..databaseDirectory.."] nao foi encontrado. Criando...")
    local status, errorMessage = posix.mkdir(databaseDirectory)
    if not status then
      print("Nao foi possivel criar o diretorio ["..databaseDirectory.."].")
      error(errorMessage)
    else
      credentialFiles = {}
    end
  end
  self = oop.rawnew(self, {databaseDirectory = databaseDirectory,})
  for _, fileName in ipairs(credentialFiles) do
    if string.sub(fileName, -(#FILE_SUFFIX)) == FILE_SUFFIX then
      local file = io.open(databaseDirectory..FILE_SEPARATOR..fileName, "r")
      if file then
        local credentialIdentifier = file:read()
        local credentialEntityName = file:read()
        if credentialIdentifier and credentialEntityName then
          local credential = { identifier = credentialIdentifier, entityName = credentialEntityName, }
          self.entries[credential.identifier] = {credential = credential,}
        end
      end
    end
  end
  return self
end

function CredentialDB:insert(credential)
  if self.entries[credential.identifier] then
    return false, "A credencial especificada ja existe."
  end
  local status, errorMessage = self:writeCredential(credential)
  if not status then
    return false, errorMessage
  end
  self.entries[credential.identifier] = {credential = credential,}
  return true
end

function CredentialDB:update(credential)
  if not self.entries[credential.identifier] then
    return false, "A credencial especificada nao existe."
  end
  return self:writeCredential(credential)
end

function CredentialDB:delete(credential)
  if not self.entries[credential.identifier] then
    return false, "A credencial especificada não existe."
  end
  local status, errorMessage = self:removeCredential(credential)
  if not status then
    return false, errorMessage
  end
  self.entries[credential.identifier] = nil
  return true
end

function CredentialDB:selectAll()
  return self.entries
end

function CredentialDB:writeCredential(credential)
  local credentialFile, errorMessage = io.open(self.databaseDirectory..FILE_SEPARATOR..credential.identifier..FILE_SUFFIX, "w")
  if not credentialFile then
    return false, errorMessage
  end
  credentialFile:write(credential.identifier)
  credentialFile:write("\n")
  credentialFile:write(credential.entityName)
  credentialFile:write("\n")
  credentialFile:close()
  return true
end

function CredentialDB:removeCredential(credential)
  return os.remove(self.databaseDirectory..FILE_SEPARATOR..credential.identifier..FILE_SUFFIX)
end
