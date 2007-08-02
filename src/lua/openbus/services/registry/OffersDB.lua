-----------------------------------------------------------------------------
-- Mecanismo de persistência de ofertas de serviço
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local io = io
local string = string
local os = os

local ipairs = ipairs
local pairs = pairs
local dofile = dofile
local type = type
local tostring = tostring
local tonumber = tonumber

local lposix = require "lposix"
local oil = require "oil"

local Log = require "openbus.common.Log"

local oop = require "loop.base"
module("openbus.services.registry.OffersDB", oop.class)

FILE_SUFFIX = ".offer"
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
    dbOffers = {},
  })
end

function retrieveAll(self)
  local offerFiles = lposix.dir(self.databaseDirectory)
  local offerEntries = {}
  for _, fileName in ipairs(offerFiles) do
    if string.sub(fileName, -(#self.FILE_SUFFIX)) == self.FILE_SUFFIX then
      local offerEntry = dofile(self.databaseDirectory..self.FILE_SEPARATOR..
          fileName)
      self.dbOffers[offerEntry.identifier] = true

      -- caso especial para referencias a membros
      local memberIOR = offerEntry.offer.member
      offerEntry.offer.member = oil.newproxy(memberIOR)

      offerEntries[offerEntry.identifier] = offerEntry
    end
  end
  return offerEntries
end

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

function update(self, offerEntry)
  if not self.dbOffers[offerEntry.identifier] then
    return false, "A oferta especificada não existe."
  end
  return self:writeOffer(offerEntry)
end

function delete(self, offerEntry)
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

function serialize(self, val)
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

function writeOffer(self, offerEntry)
  local offerFile, errorMessage =  io.open(self.databaseDirectory..
      self.FILE_SEPARATOR..offerEntry.identifier..self.FILE_SUFFIX, "w")
  if not offerFile then
    return false, errorMessage
  end
  offerFile:write("return ".. self:serialize(offerEntry))
  offerFile:close()
  return true
end

function removeOffer(self, offerEntry)
  return os.remove(self.databaseDirectory..self.FILE_SEPARATOR..
      offerEntry.identifier..self.FILE_SUFFIX)
end
