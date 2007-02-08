local oop = require "loop.base"

require "posix"

local FILE_SUFFIX = ".credential"
local FILE_SEPARATOR = "/"

CredentialDB = oop.class{
  entries = {},
}

function CredentialDB:__init(databaseDirectory)
  local entries = {}
  for _, fileName in posix.dir(databaseDirectory) do
    if string.sub(fileName, -(#FILE_SUFFIX)) == FILE_SUFFIX then
      local file = io.open(self.databaseDirectory..FILE_SEPARATOR..fileName, "r")
      if file then
        local credentialIdentifier = file:read()
        local credentialEntityName = file:read()
        if credentialIdentifier and credentialEntityName then
          local credential = { identifier = credentialIdentifier, entityName = credentialEntityName, }
          entries[credential] = true
        end
      end
    end
  end
  return oop.rawnew(self, { databaseDirectory = databaseDirectory, entries = entries, })
end

function CredentialDB:insert(credential)
  if self.entries[credential] then
    return false, "A credencial especificada já existe."
  end
  local status, errorMessage = self:writeCredential(credential)
  if not status then
    return false, errorMessage
  end
  self.entries[credential] = true
  return true
end

function CredentialDB:update(credential)
  if not self.entries[credential] then
    return false, "A credencial especificada não existe."
  end
  return self:writeCredential(credential)
end

function CredentialDB:delete(credential)
  if not self.entries[credential] then
    return false, "A credencial especificada não existe."
  end
  local status, errorMessage = self:removeCredential(credential)
  if not status then
    return false, errorMessage
  end
  self.entries[credential] = false
  return true
end

function CredentialDB:selectAll()
  -- Vale a pena recarregar tudo aqui?
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
  return os.delete(self.databaseDirectory..FILE_SEPARATOR..credential.identifier..FILE_SUFFIX)
end
