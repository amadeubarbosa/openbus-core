-- $Id$
local io = io
local string = string
local format = string.format
local os = os
local tostring = tostring
local error = error

local lfs = require "lfs"
local oil = require "oil"

local FileStream = require "loop.serial.FileStream"

local Log = require "openbus.util.Log"
local Utils = require "openbus.util.Utils"

local oop = require "loop.base"

---
--Mecanismo de persist�ncia de ofertas de servi�o.
--
module("core.services.registry.OffersDB", oop.class)

FILE_SUFFIX = ".offer"
FILE_SEPARATOR = "/"

---
--Cria um banco de dados de ofertas de servi�o.
--
--@param databaseDirectory O diret�rio que sera utilizado para armazenas as
--ofertas de servi�o.
--
--@return O banco de dados de ofertas de servi�o.
---
function __init(self, databaseDirectory, orb)
  local mode = lfs.attributes(databaseDirectory, "mode")
  if not mode then
    Log:info(format("O diretorio %s n�o foi encontrado. Criando...",
        databaseDirectory))
    local status, errorMessage = lfs.mkdir(databaseDirectory)
    if not status then
      Log:error(format("Nao foi poss�vel criar o diret�rio %s: %s",
          databaseDirectory, tostring(errorMessage)))
      error(errorMessage)
    end
  end
  return oop.rawnew(self, {
    databaseDirectory = databaseDirectory,
    dbOffers = {},
    orb = orb,
  })
end

---
--Obt�m todas as ofertas de servi�o.
--
--@return As ofertas de servi�o.
---
function retrieveAll(self)
  local offerFiles = lfs.dir(self.databaseDirectory)
  local offerEntries = {}
  for fileName in offerFiles do
    if string.sub(fileName, -(#self.FILE_SUFFIX)) == self.FILE_SUFFIX then
      local offerFile = io.open(self.databaseDirectory..self.FILE_SEPARATOR..fileName)
      local stream = FileStream{
        file = offerFile
      }
      local offerEntry = stream:get()
      offerFile:close()

      self.dbOffers[offerEntry.identifier] = true

      -- caso especial para referencias a membros
      local memberIOR = offerEntry.offer.member
      offerEntry.offer.member = self.orb:newproxy(memberIOR, "protected", Utils.COMPONENT_INTERFACE)
      offerEntries[offerEntry.identifier] = offerEntry
    end
  end
  return offerEntries
end

---
--Insere uma entrada no banco de dados.
--
--@param offerEntry A oferta de servi�o.
--
--@return true caso a oferta tenha sido inserida, ou false e uma mensagem
--de erro, caso contr�rio.
---
function insert(self, offerEntry)
  if self.dbOffers[offerEntry.identifier] then
    return false, "A oferta especificada ja existe."
  end
  local status, errorMessage = self:writeOffer(offerEntry)
  if not status then
    return false, errorMessage
  end
  self.dbOffers[offerEntry.identifier] = true
  return true
end

---
--Atualiza uma oferta de servi�o.
--
--@param offerEntry A oferta de servi�o.
--
--@return true caso a oferta seja atualizada, ou false e uma mensagem de erro,
--caso contr�rio.
---
function update(self, offerEntry)
  if not self.dbOffers[offerEntry.identifier] then
    return false, "A oferta especificada n�o existe."
  end
  return self:writeOffer(offerEntry)
end

---
--Remove uma oferta de servi�o.
--
--@param offerEntry A oferta de servi�o.
--
--@return true caso a oferta tenha sido removida, ou false e uma mensagem de
--erro, caso contr�rio.
---
function delete(self, offerEntry)
  local message
  if not self.dbOffers[offerEntry.identifier] then
    message = "[DB] Oferta "..offerEntry.identifier.." n�o existe."
    return false, message
  end
  local status, errorMessage = self:removeOffer(offerEntry)
  if not status then
    message = "[DB] Oferta "..offerEntry.identifier.." - ERRO:" .. errorMessage
    return false, message
  end
  self.dbOffers[offerEntry.identifier] = nil
  message = "[DB] Oferta "..offerEntry.identifier.." REMOVIDA."
  return true, message
end

---
--Escreve a oferta de servi�o em arquivo.
--
--@param offerEntry A oferta de servi�o.
--
--@return true caso o arquivo seja gerado, ou false e uma mensagem de erro,
--caso contr�rio.
---
function writeOffer(self, offerEntry)
  local offerFile, errorMessage =  io.open(self.databaseDirectory..
      self.FILE_SEPARATOR..offerEntry.identifier..self.FILE_SUFFIX, "w")
  if not offerFile then
    return false, errorMessage
  end
  local stream = FileStream{
    file = offerFile,
    getmetatable = false,
  }

  local member =  offerEntry.offer.member
  stream[member] = "'"..self.orb:tostring(member).."'"
  stream:put(offerEntry)
  offerFile:close()

  return true
end

---
--Remove o arquivo da oferta de servi�o.
--
--@param offerEntry A oferta de servi�o.
--
--@return Caso o arquivo n�o seja removido, retorna nil e uma mensagem de erro.
---
function removeOffer(self, offerEntry)
  return os.remove(self.databaseDirectory..self.FILE_SEPARATOR..
      offerEntry.identifier..self.FILE_SUFFIX)
end
