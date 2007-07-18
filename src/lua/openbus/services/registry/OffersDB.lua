-----------------------------------------------------------------------------
-- Mecanismo de persistência de ofertas de serviço
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local oop = require "loop.base"
local log = require "openbus.common.Log"

require "lposix"
require "oil"

local FILE_SUFFIX = ".offer"
local FILE_SEPARATOR = "/"

OffersDB = oop.class{
  dbOffers = {},
}

function OffersDB:__init(databaseDirectory)
  self = oop.rawnew(self, {databaseDirectory = databaseDirectory,})
  if not posix.dir(databaseDirectory) then
    log:service("O diretorio ["..databaseDirectory..
                "] nao foi encontrado. Criando...")
    local status, errorMessage = posix.mkdir(databaseDirectory)
    if not status then
      log:error("Nao foi possivel criar o diretorio ["..databaseDirectory.."].")
      error(errorMessage)
    end
  end
  return self
end

function OffersDB:retrieveAll()
  local offerFiles = posix.dir(self.databaseDirectory)
  local offerEntries = {}
  for _, fileName in ipairs(offerFiles) do
    if string.sub(fileName, -(#FILE_SUFFIX)) == FILE_SUFFIX then
      local offerEntry = 
        dofile(self.databaseDirectory..FILE_SEPARATOR..fileName)
      self.dbOffers[offerEntry.identifier] = true

      -- caso especial para referencias a membros
      local memberIOR = offerEntry.offer.member
      offerEntry.offer.member = oil.newproxy(memberIOR)

      offerEntries[offerEntry.identifier] = offerEntry
    end
  end
  return offerEntries
end

function OffersDB:insert(offerEntry)
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

function OffersDB:update(offerEntry)
  if not self.dbOffers[offerEntry.identifier] then
    return false, "A oferta especificada não existe."
  end
  return self:writeOffer(offerEntry)
end

function OffersDB:delete(offerEntry)
  if not self.dbOffers[offerEntry.identifier] then
    return false, "A oferta especificada não existe."
  end
  local status, errorMessage = self:removeOffer(offerEntry)
  if not status then
    return false, errorMessage
  end
  self.dbOffers[offerEntry.identifier] = nil
  return true
end

---------------------------------------------------------------------
-- Serializa as ofertas de serviço
---------------------------------------------------------------------
function OffersDB:serialize(val)
  local t = type(val)
  if t == "table" then
    local str = '{'
    for f, s in pairs(val) do

      -- caso especial para referencias a membros (persiste o IOR)
      if type(f) == "string"  and f == "member" then
        str = str .. f .. "=[[" .. oil.tostring(s) .. "]],"
      else
        if not tonumber(f) then
          str = str .. f .. "="
        end
        str = str .. self:serialize(s) .. ","
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

function OffersDB:writeOffer(offerEntry)
  local offerFile, errorMessage = 
    io.open(self.databaseDirectory..FILE_SEPARATOR..offerEntry.identifier..
            FILE_SUFFIX, "w")
  if not offerFile then
    return false, errorMessage
  end
  offerFile:write("return ".. self:serialize(offerEntry))
  offerFile:close()
  return true
end

function OffersDB:removeOffer(offerEntry)
  return os.remove(self.databaseDirectory..FILE_SEPARATOR..
                   offerEntry.identifier..FILE_SUFFIX)
end
