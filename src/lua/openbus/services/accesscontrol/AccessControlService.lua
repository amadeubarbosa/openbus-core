-----------------------------------------------------------------------------
-- Componente responsável pelo Serviço de Controle de Acesso
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "lualdap"
require "uuid"
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
                observersByIdentifier = {},
                observersByCredential = {},
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
  local entriesDB = self.credentialDB:selectAll()
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
      else
        entry.lease.secondChance = false
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
  certificate:release()
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
  local lease = self.entries[credential.identifier].lease
  local lastUpdate = lease.lastUpdate
  local duration = lease.duration
  local now = os.time()
  if (os.difftime (now, lastUpdate) > duration ) then
    log:warn(credential.entityName .. " lease expirado: LOGOUT.")
    self:logout(credential)
    return false, self.invalidLease
  end
  self.entries[credential.identifier].lease.lastUpdate = now
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
    return self.registryServiceComponent
end

function AccessControlService:setRegistryService(registryServiceComponent)
    local credential = self.picurrent:getValue()
    if credential.entityName == "RegistryService" then
        self.registryServiceComponent = registryServiceComponent
        return true
    end
    return false
end

function AccessControlService:addObserver(observer, credentialIdentifiers)
    local observerId = self:generateObserverIdentifier()
    local observerEntry = {observer = observer, credentials = {}}
    self.observersByIdentifier[observerId] = observerEntry
    for _, credentialId in ipairs(credentialIdentifiers) do
      observerEntry.credentials[credentialId] = true
      if not self.observersByCredential[credentialId] then
        self.observersByCredential[credentialId] = {}
      end
      self.observersByCredential[credentialId][observerId] = observerEntry
    end
    return observerId
end

function AccessControlService:removeObserver(observerIdentifier)
    local observerEntry = self.observersByIdentifier[observerIdentifier]
    if not observerEntry then
      return false
    end
    for credentialId in pairs(observerEntry.credentials) do
      if self.observersByCredential[credentialId] then
        self.observersByCredential[credentialId][observerIdentifier] = nil
      end
    end
    self.observersByIdentifier[observerIdentifier] = nil
    return true
end

function AccessControlService:addCredentialToObserver(observerIdentifier, credentialIdentifier)
    local observerEntry = self.observersByIdentifier[observerIdentifier]
    if not observerEntry then
      return false
    end
    observerEntry.credentials[credentialIdentifier] = true
    if not self.observersByCredential[credentialIdentifier] then
      self.observersByCredential[credentialIdentifier] = {}
    end
    self.observersByCredential[credentialIdentifier][observerIdentifier] =
      observerEntry
    return true
end

function AccessControlService:removeCredentialFromObserver(observerIdentifier,
    credentialIdentifier)
    local observerEntry = self.observersByIdentifier[observerIdentifier]
    if not observerEntry then
      return false
    end
    observerEntry.credentials[credentialIdentifier] = false
    if self.observersByCredential[credentialIdentifier] then
      self.observersByCredential[credentialIdentifier][observerIdentifier] = nil
    end
    return true
end

function AccessControlService:addEntry(name)
    local credential = {identifier = self:generateCredentialIdentifier(), entityName = name}
    local duration = self.deltaT
    local lease = { lastUpdate = os.time(), duration = duration}
    entry = {credential = credential, lease = lease}
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
    self.entries[entry.credential.identifier] = nil
    log:service("Vai notificar aos observadores...")
    self:notifyCredentialWasDeleted(entry.credential)
    log:service("Observadores notificados...")
    self.credentialDB:delete(entry)
end

function AccessControlService:notifyCredentialWasDeleted(credential)
    local observers = self.observersByCredential[credential.identifier]
    if not observers then
        return
    end
    for _, observerEntry in pairs(observers) do
      local success, err = oil.pcall(observerEntry.observer.credentialWasDeleted, observerEntry.observer, credential)
      if not success then
        log:warn("Erro ao notificar um observador.")
        log:warn(err)
      end
    end
end

-- Shutdown do componente: ainda a implementar!!!
function AccessControlService:shutdown()
end
