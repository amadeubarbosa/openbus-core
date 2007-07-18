-----------------------------------------------------------------------------
-- Componente responsável pelo Serviço de Controle de Acesso
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "lualdap"
require "luuid"
require "lce"
require "oil"

require "openbus.Member"
require "openbus.services.accesscontrol.CredentialDB"

local ServerInterceptor = require "openbus.common.ServerInterceptor"
local PICurrent = require "openbus.common.PICurrent"

local log = require "openbus.common.Log"
local oop = require "loop.base"
local LeaseProvider = require "openbus.common.LeaseProvider"

AccessControlService = oop.class({
  invalidCredential = {identifier = "", entityName = ""},
  invalidLease = -1,
  deltaT = 30, -- lease fixo (por enquanto) em segundos
}, Member)

-- Constrói a implementação do componente
function AccessControlService:__init(name)
  local obj = { name = name,
                config = AccessControlServerConfiguration,
                entries = {},
                observers = {},
                challenges = {},
                picurrent = PICurrent(),
              }
  Member:__init(obj)
  return oop.rawnew(self, obj)
end

-- Inicia o componente
function AccessControlService:startup()

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
      log:lease("Verificando a credencial de "..id)
      local credential = entry.credential
      local lastUpdate = entry.lease.lastUpdate
      local secondChance = entry.lease.secondChance
      local duration = entry.lease.duration
      local now = os.time()
      if (os.difftime (now, lastUpdate) > duration ) then
        if secondChance then
          log:warn(credential.entityName .. " lease expirado: LOGOUT.")
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

function AccessControlService:loginByPassword(name, password)
    local ldapHost = self.config.ldapHostName..":"..self.config.ldapHostPort
    local connection, errorMessage = lualdap.open_simple(ldapHost, name, password, false)
    if not connection then
      log:error("Erro ao conectar com o servidor LDAP.\n"..errorMessage)
      return false, self.invalidCredential, self.invalidLease
    end
    connection:close()
    local entry = self:addEntry(name)
    return true, entry.credential, entry.lease.duration
end

function AccessControlService:loginByCertificate(name, answer)
  local challenge = self.challenges[name]
  if not challenge then
    log:error("Nao existe desafio para "..name)
    return false, self.invalidCredential, self.invalidLease
  end
  local errorMessage
  answer, errorMessage = lce.cipher.decrypt(self.privateKey, answer)
  if answer ~= challenge then
    log:error("Erro ao obter a resposta de "..name)
    log:error(errorMessage)
    return false, self.invalidCredential, self.invalidLease
  end
  local entry = self:addEntry(name)
  return true, entry.credential, entry.lease.duration
end

function AccessControlService:getChallenge(name)
  local certificate, errorMessage = self:getCertificate(name)
  if not certificate then
    log:error("Nao foi encontrado o certificado de "..name)
    log:error(errorMessage)
    return ""
  end
  local challenge = self:generateChallenge(name, certificate)
  return challenge
end

function AccessControlService:getCertificate(name)
  local certificateFile = self.config.certificatesDirectory.."/"..name..".crt"
  return lce.x509.readfromderfile(certificateFile)
end

function AccessControlService:generateChallenge(name, certificate)
  local currentTime = tostring(os.time())
  self.challenges[name] = currentTime
  return lce.cipher.encrypt(certificate:getpublickey(), currentTime)
end

function AccessControlService:renewLease(credential)
  log:lease(credential.entityName .. " renovando lease.")
  if not self:isValid(credential) then
    log:warn(credential.entityName .. " credencial inválida.")
    return false, self.invalidLease
  end
  local now = os.time()
  local lease = self.entries[credential.identifier].lease
  lease.lastUpdate = now
  lease.secondChance = false
  -- Por enquanto deixa o lease com tempo fixo
  return true, self.deltaT
end

function AccessControlService:logout(credential)
  local entry = self.entries[credential.identifier]
  if not entry then
    log:warn("Tentativa de logout com credencial inexistente: "..
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

function AccessControlService:isValid(credential)
  local entry = self.entries[credential.identifier]
  if not entry then
    return false
  end
  if entry.credential.identifier ~= credential.identifier then
    return false
  end
  return true
end

function AccessControlService:getRegistryService()
  if self.registryService then
    return self.registryService.component
  end
  return nil
end

function AccessControlService:setRegistryService(registryServiceComponent)
  local credential = self.picurrent:getValue()
  if credential.entityName == "RegistryService" then
    self.registryService = {
      credential = credential,
      component = registryServiceComponent
    }
    local suc, err = 
      self.credentialDB:writeRegistryService(self.registryService)
    if not suc then
      log:error("Erro persistindo referencia registry service: "..err)
    end
    return true
  end
  return false
end

function AccessControlService:addObserver(observer, credentialIdentifiers)
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

function AccessControlService:addCredentialToObserver(observerIdentifier, credentialIdentifier)
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

function AccessControlService:removeObserver(observerIdentifier, credential)
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

function AccessControlService:removeCredentialFromObserver(observerIdentifier,
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

function AccessControlService:addEntry(name)
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

function AccessControlService:generateCredentialIdentifier()
  return uuid.new("time")
end

function AccessControlService:generateObserverIdentifier()
  return uuid.new("time")
end

function AccessControlService:removeEntry(entry)
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

function AccessControlService:notifyCredentialWasDeleted(credential)
  for observerId in pairs(self.entries[credential.identifier].observedBy) do
    local observerEntry = self.observers[observerId]
    if observerEntry then
      local success, err =
        oil.pcall(observerEntry.observer.credentialWasDeleted, 
                  observerEntry.observer, credential)
      if not success then
        log:warn("Erro ao notificar um observador.")
        log:warn(err)
      end
    end
  end
end

-- Shutdown do componente: ainda a implementar!!!
function AccessControlService:shutdown()
end
