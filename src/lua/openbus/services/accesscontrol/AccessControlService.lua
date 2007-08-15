-----------------------------------------------------------------------------
-- Componente responsável pelo Serviço de Controle de Acesso
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local os = os

local loadfile = loadfile
local assert = assert
local pairs = pairs
local ipairs = ipairs
local tostring = tostring

local luuid = require "luuid"
local lce = require "lce"
local oil = require "oil"

local CredentialDB = require "openbus.services.accesscontrol.CredentialDB"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local PICurrent = require "openbus.common.PICurrent"
local LeaseProvider = require "openbus.common.LeaseProvider"

local LDAPLoginPasswordValidator =
    require "openbus.services.accesscontrol.LDAPLoginPasswordValidator"
local TestLoginPasswordValidator =
    require "openbus.services.accesscontrol.TestLoginPasswordValidator"

local Log = require "openbus.common.Log"

local IComponent = require "scs.core.IComponent"

local oop = require "loop.simple"
module("openbus.services.accesscontrol.AccessControlService")
oop.class(_M, IComponent)

invalidCredential = {identifier = "", entityName = ""}
invalidLease = -1
deltaT = 30 -- lease fixo (por enquanto) em segundos

-- Constrói a implementação do componente
function __init(self, name, config)
  local component = IComponent:__init(name, 1)
  component.config = config
  component.entries = {}
  component.observers = {}
  component.challenges = {}
  component.picurrent = PICurrent()
  component.loginPasswordValidators = {
    LDAPLoginPasswordValidator(config.ldapHostName..":"..config.ldapHostPort),
    TestLoginPasswordValidator(),
  }
  return oop.rawnew(self, component)
end

-- Inicia o componente
function startup(self)
  -- instala o interceptador do serviço
  local CONF_DIR = os.getenv("CONF_DIR")
  local iconfig = 
    assert(loadfile(CONF_DIR.."/advanced/ACSInterceptorsConfiguration.lua"))()
  oil.setserverinterceptor(ServerInterceptor(iconfig, self.picurrent, self))
  
  -- inicializa repositorio de credenciais
  self.privateKey = lce.key.readprivatefrompemfile(self.config.privateKeyFile)
  self.credentialDB = CredentialDB(self.config.databaseDirectory)
  self.registryService = self.credentialDB:retrieveRegistryService()
  local entriesDB = self.credentialDB:retrieveAll()
  for _, entry in pairs(entriesDB) do
    entry.lease.lastUpdate = os.time()
    self.entries[entry.credential.identifier] = entry -- Deveria fazer cópia?
  end
  self.checkExpiredLeases = function()
    -- Uma corotina só percorre a tabela de tempos em tempos
    -- ou precisamos acordar na hora "exata" que cada lease expira
    -- pra verificar?
    for id, entry in pairs(self.entries) do
      Log:lease("Verificando a credencial de "..id)
      local credential = entry.credential
      local lastUpdate = entry.lease.lastUpdate
      local secondChance = entry.lease.secondChance
      local duration = entry.lease.duration
      local now = os.time()
      if (os.difftime (now, lastUpdate) > duration ) then
        if secondChance then
          Log:warn(credential.entityName .. " lease expirado: LOGOUT.")
          self:logout(credential) -- you may clear existing fields.
        else
          entry.lease.secondChance = true
        end
      end
    end
  end
  self.leaseProvider = LeaseProvider(self.checkExpiredLeases, self.deltaT)
  return self
end

function loginByPassword(self, name, password)
  for _, validator in ipairs(self.loginPasswordValidators) do
    local result, err = validator:validate(name, password)
    if result then
      local entry = self:addEntry(name)
      return true, entry.credential, entry.lease.duration
    else
      Log:warn("Erro ao validar o usuário "..name..".\n".. err)
    end
  end
  Log:error("Usuário "..name.." não pôde ser validado no sistema.")
  return false, self.invalidCredential, self.invalidLease
end

function loginByCertificate(self, name, answer)
  local challenge = self.challenges[name]
  if not challenge then
    Log:error("Nao existe desafio para "..name)
    return false, self.invalidCredential, self.invalidLease
  end
  local errorMessage
  answer, errorMessage = lce.cipher.decrypt(self.privateKey, answer)
  if answer ~= challenge then
    Log:error("Erro ao obter a resposta de "..name)
    Log:error(errorMessage)
    return false, self.invalidCredential, self.invalidLease
  end
  local entry = self:addEntry(name)
  return true, entry.credential, entry.lease.duration
end

function getChallenge(self, name)
  local certificate, errorMessage = self:getCertificate(name)
  if not certificate then
    Log:error("Nao foi encontrado o certificado de "..name)
    Log:error(errorMessage)
    return ""
  end
  local challenge = self:generateChallenge(name, certificate)
  return challenge
end

function getCertificate(self, name)
  local certificateFile = self.config.certificatesDirectory.."/"..name..".crt"
  return lce.x509.readfromderfile(certificateFile)
end

function generateChallenge(self, name, certificate)
  local currentTime = tostring(os.time())
  self.challenges[name] = currentTime
  return lce.cipher.encrypt(certificate:getpublickey(), currentTime)
end

function renewLease(self, credential)
  Log:lease(credential.entityName .. " renovando lease.")
  if not self:isValid(credential) then
    Log:warn(credential.entityName .. " credencial inválida.")
    return false, self.invalidLease
  end
  local now = os.time()
  local lease = self.entries[credential.identifier].lease
  lease.lastUpdate = now
  lease.secondChance = false
  -- Por enquanto deixa o lease com tempo fixo
  return true, self.deltaT
end

function logout(self, credential)
  local entry = self.entries[credential.identifier]
  if not entry then
    Log:warn("Tentativa de logout com credencial inexistente: "..
      credential.identifier)
    return false
  end
  self:removeEntry(entry)
  if self.registryService then
    if credential.entityName == "RegistryService" and
        credential.identifier == self.registryService.credential.identifier then
      self.registryService = nil
      self.credentialDB:deleteRegistryService()
    end
  end
  return true
end

function isValid(self, credential)
  local entry = self.entries[credential.identifier]
  if not entry then
    return false
  end
  if entry.credential.identifier ~= credential.identifier then
    return false
  end
  return true
end

function getRegistryService(self)
  if self.registryService then
    return self.registryService.component
  end
  return nil
end

function setRegistryService(self, registryServiceComponent)
  local credential = self.picurrent:getValue()
  if credential.entityName == "RegistryService" then
    self.registryService = {
      credential = credential,
      component = registryServiceComponent
    }
    local suc, err = 
      self.credentialDB:writeRegistryService(self.registryService)
    if not suc then
      Log:error("Erro persistindo referencia registry service: "..err)
    end
    return true
  end
  return false
end

function addObserver(self, observer, credentialIdentifiers)
  local observerId = self:generateObserverIdentifier()
  local observerEntry = {observer = observer, credentials = {}}
  self.observers[observerId] = observerEntry
  for _, credentialId in ipairs(credentialIdentifiers) do
    self.entries[credentialId].observedBy[observerId] = true
    observerEntry.credentials[credentialId] = true
  end
  local credential = self.picurrent:getValue()
  self.entries[credential.identifier].observers[observerId] = true
  return observerId
end

function addCredentialToObserver(self, observerIdentifier, credentialIdentifier)
  if not self.entries[credentialIdentifier] then
    return false
  end

  local observerEntry = self.observers[observerIdentifier]
  if not observerEntry then
    return false
  end
  observerEntry.credentials[credentialIdentifier] = true
  self.entries[credentialIdentifier].observedBy[observerIdentifier] = true
  return true
end

function removeObserver(self, observerIdentifier, credential)
  local observerEntry = self.observers[observerIdentifier]
  if not observerEntry then
    return false
  end
  for credentialId in pairs(observerEntry.credentials) do
    self.entries[credentialId].observedBy[observerIdentifier] = nil
  end
  self.observers[observerIdentifier] = nil
  credential = credential or self.picurrent:getValue()
  self.entries[credential.identifier].observers[observerIdentifier] = nil
  return true
end

function removeCredentialFromObserver(self, observerIdentifier,
    credentialIdentifier)
  local observerEntry = self.observers[observerIdentifier]
  if not observerEntry then
    return false
  end
  observerEntry.credentials[credentialIdentifier] = nil
  local entry = self.entries[credentialIdentifier]
  if not entry then
    return false
  end
  entry.observedBy[observerIdentifier] = nil
  return true
end

function addEntry(self, name)
  local credential = {
    identifier = self:generateCredentialIdentifier(), 
    entityName = name
  }
  local duration = self.deltaT
  local lease = { lastUpdate = os.time(), duration = duration }
  entry = { credential = credential,
            lease = lease,
            observers = {},
            observedBy = {}
  }
  self.credentialDB:insert(entry)
  self.entries[entry.credential.identifier] = entry
  return entry
end

function generateCredentialIdentifier()
  return luuid.new("time")
end

function generateObserverIdentifier()
  return luuid.new("time")
end

function removeEntry(self, entry)
  local credential = entry.credential
  self:notifyCredentialWasDeleted(credential)
  for observerId in pairs(self.entries[credential.identifier].observers) do
    self:removeObserver(observerId, credential)
  end
  for observerId in pairs(self.entries[credential.identifier].observedBy) do
    self:removeCredentialFromObserver(observerId, credential.identifier)
  end
  self.entries[credential.identifier] = nil
  self.credentialDB:delete(entry)
end

function notifyCredentialWasDeleted(self, credential)
  for observerId in pairs(self.entries[credential.identifier].observedBy) do
    local observerEntry = self.observers[observerId]
    if observerEntry then
      local success, err =
        oil.pcall(observerEntry.observer.credentialWasDeleted, 
                  observerEntry.observer, credential)
      if not success then
        Log:warn("Erro ao notificar um observador.")
        Log:warn(err)
      end
    end
  end
end

-- Shutdown do componente: ainda a implementar!!!
function shutdown(self)
end
