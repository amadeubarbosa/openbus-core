-- $Id$

local os = os

local loadfile = loadfile
local assert = assert
local pairs = pairs
local ipairs = ipairs
local string = string
local tostring = tostring

local luuid = require "uuid"
local lce = require "lce"
local oil = require "oil"
local orb = oil.orb

local CredentialDB = require "core.services.accesscontrol.CredentialDB"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local LeaseProvider = require "openbus.common.LeaseProvider"

--local LDAPLoginPasswordValidator =
--    require "core.services.accesscontrol.LDAPLoginPasswordValidator"
--local TestLoginPasswordValidator =
--    require "core.services.accesscontrol.TestLoginPasswordValidator"

local Log = require "openbus.common.Log"

local scs = require "scs.core.base"

local oop = require "loop.simple"

---
--Componente responsável pelo Serviço de Controle de Acesso
---
module("core.services.accesscontrol.AccessControlService")

--------------------------------------------------------------------------------
-- Faceta IAccessControlService
--------------------------------------------------------------------------------

local DATA_DIR = os.getenv("OPENBUS_DATADIR")

ACSFacet = oop.class{}

---
--Credencial inválida.
--
--@class table
--@name invalidCredential
--
--@field identifier O identificador da credencial que, neste caso, é vazio.
--@field owner O nome da entidade dona da credencial que, neste caso, é vazio.
--@field delegate O nome da entidade delegada que, neste caso, é vazio.
---
ACSFacet.invalidCredential = {identifier = "", owner = "", delegate = ""}
ACSFacet.invalidLease = -1
ACSFacet.deltaT = 30 -- lease fixo (por enquanto) em segundos

---
--Realiza um login de uma entidade através de usuário e senha.
--
--@param name O nome da entidade.
--@param password A senha da entidade.
--
--@return true, a credencial da entidade e o lease caso o login seja realizado
--com sucesso, ou false e uma credencial e uma lease inválidos, caso contrário.
---
function ACSFacet:loginByPassword(name, password)
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

---
--Realiza um login de um membro através de assinatura digital.
--
--@param name OI nome do membro.
--@param answer A resposta para um desafio previamente obtido.
--
--@return true, a credencial do membro e o lease caso o login seja realizado
--com sucesso, ou false e uma credencial e uma lease inválidos, caso contrário.
--
--@see getChallenge
---
function ACSFacet:loginByCertificate(name, answer)
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
  self.challenges[name] = nil
  local entry = self:addEntry(name, true)
  return true, entry.credential, entry.lease.duration
end

---
--Obtém o desafio para um membro.
--
--@param name O nome do membro.
--
--@return O desafio.
--
--@see loginByCertificate
---
function ACSFacet:getChallenge(name)
  local certificate, errorMessage = self:getCertificate(name)
  if not certificate then
    Log:error("Nao foi encontrado o certificado de "..name)
    Log:error(errorMessage)
    return ""
  end
  return self:generateChallenge(name, certificate)
end

---
--Obtém o certificado de um membro.
--
--@param name O nome do membro.
--
--@return O certificado do membro.
---
function ACSFacet:getCertificate(name)
  local certificatesDirectory
  if (string.sub(self.config.certificatesDirectory,1 , 1) == "/") then
    certificatesDirectory = self.config.certificatesDirectory
  else
    certificatesDirectory = DATA_DIR.."/"..self.config.certificatesDirectory
  end
  local certificateFile = certificatesDirectory.."/"..name..".crt"
  return lce.x509.readfromderfile(certificateFile)
end

---
--Gera um desafio para um membro.
--
--@param name O nome do membro.
--@param certificate O certificado do membro.
--
--@return O desafio.
---
function ACSFacet:generateChallenge(name, certificate)
  local randomSequence = tostring(luuid.new("time"))
  self.challenges[name] = randomSequence
  return lce.cipher.encrypt(certificate:getpublickey(), randomSequence)
end

---
--Faz o logout de uma credencial.
--
--@param credential A credencial.
--
--@return true caso a credencial estivesse logada, ou false caso contrário.
---
function ACSFacet:logout(credential)
  local entry = self.entries[credential.identifier]
  if not entry then
    Log:warn("Tentativa de logout com credencial inexistente: "..
      credential.identifier)
    return false
  end
  self:removeEntry(entry)
  if self.registryService then
    if credential.owner == "RegistryService" and
        credential.identifier == self.registryService.credential.identifier then
      self.registryService = nil
    end
  end
  return true
end

---
--Verifica se uma credencial é válida.
--
--@param credential A credencial.
--
--@return true caso a credencial seja válida, ou false caso contrário.
---
function ACSFacet:isValid(credential)
  local entry = self.entries[credential.identifier]
  if not entry then
    return false
  end
  if entry.credential.delegate ~= "" and not entry.certified then
    return false
  end
  return true
end

---
--Obtém o Serviço de Registro.
--
--@return O Serviço de Registro, ou nil caso não tenha sido definido.
---
function ACSFacet:getRegistryService()
  if self.registryService then
    return self.registryService.component
  end
  return nil
end

---
--Define o componente responsável pelo Serviço de Registro.
--
--@param registryServiceComponent O componente responsável pelo Serviço de
--Registro.
--
--@return true caso o componente seja definido, ou false caso contrário.
---
function ACSFacet:setRegistryService(registryServiceComponent)
  local credential = self.serverInterceptor:getCredential()
  if credential.owner == "RegistryService" then
    self.registryService = {
      credential = credential,
      component = registryServiceComponent,
    }

    local entry = self.entries[credential.identifier]
    entry.component = registryServiceComponent
    local suc, err = self.credentialDB:update(entry)
    if not suc then
      Log:error("Erro persistindo referencia registry service: "..err)
    end
    return true
  end
  return false
end

---
--Adiciona um observador de credenciais.
--
--@param observer O observador.
--@param credentialIdentifiers As credenciais de interesse do observador.
--
--@return O identificador do observador.
---
function ACSFacet:addObserver(observer, credentialIdentifiers)
  local observerId = self:generateObserverIdentifier()
  local observerEntry = {observer = observer, credentials = {}}
  self.observers[observerId] = observerEntry
  for _, credentialId in ipairs(credentialIdentifiers) do
    self.entries[credentialId].observedBy[observerId] = true
    observerEntry.credentials[credentialId] = true
  end
  local credential = self.serverInterceptor:getCredential()
  self.entries[credential.identifier].observers[observerId] = true
  return observerId
end

---
--Adiciona uma credencial à lista de credenciais de um observador.
--
--@param observerIdentifier O identificador do observador.
--@param credentialIdentifier O identificador da credencial.
--
--@return true caso a credencil tenha sido adicionada, ou false caso contrário.
---
function ACSFacet:addCredentialToObserver(observerIdentifier, credentialIdentifier)
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

---
--Remove um observador e retira sua credencial da lista de outros observadores.
--
--@param observerIdentifier O identificador do observador.
--@param credential A credencial.
--
--@return true caso o observador tenha sido removido, ou false caso contrário.
---
function ACSFacet:removeObserver(observerIdentifier, credential)
  local observerEntry = self.observers[observerIdentifier]
  if not observerEntry then
    return false
  end
  for credentialId in pairs(observerEntry.credentials) do
    self.entries[credentialId].observedBy[observerIdentifier] = nil
  end
  self.observers[observerIdentifier] = nil
  credential = credential or self.serverInterceptor:getCredential()
  self.entries[credential.identifier].observers[observerIdentifier] = nil
  return true
end

---
--Remove uma credencial da lista de credenciais de um observador.
--
--@param observerIdentifier O identificador do observador.
--@param credentialIdentifier O identificador da credencial.
--
--@return true caso a credencial seja removida, ou false caso contrário.
---
function ACSFacet:removeCredentialFromObserver(observerIdentifier,
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

---
--Adiciona uma credencial ao banco de dados.
--
--@param name O nome da entidade para a qual a credencial será gerada.
--
--@return A credencial.
---
function ACSFacet:addEntry(name, certified)
  local credential = {
    identifier = self:generateCredentialIdentifier(),
    owner = name,
    delegate = "",
  }
  local duration = self.deltaT
  local lease = { lastUpdate = os.time(), duration = duration }
  local entry = {
    credential = credential,
    certified = certified,
    lease = lease,
    observers = {},
    observedBy = {}
  }
  self.credentialDB:insert(entry)
  self.entries[entry.credential.identifier] = entry
  return entry
end

---
--Gera um identificador de credenciais.
--
--@return O identificador de credenciais.
---
function ACSFacet:generateCredentialIdentifier()
  return luuid.new("time")
end

---
--Gera um identificador de observadores de credenciais.
--
--@return O identificador de observadores de credenciais.
---
function ACSFacet:generateObserverIdentifier()
  return luuid.new("time")
end

---
--Remove uma credencial da base de dados e notifica os observadores sobre tal
--evento.
--
--@param entry A credencial.
---
function ACSFacet:removeEntry(entry)
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

---
--Envia aos observadores a notificação de que um credencial não existe mais.
--
--@param credential A credencial.
---
function ACSFacet:notifyCredentialWasDeleted(credential)
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

--------------------------------------------------------------------------------
-- Faceta ILeaseProvider
--------------------------------------------------------------------------------

LeaseProviderFacet = oop.class{}

---
--@see openbus.common.LeaseProvider#renewLease
---
function LeaseProviderFacet:renewLease(credential)
  self = self.context.IAccessControlService
  Log:lease(credential.owner.. " renovando lease.")
  if not self:isValid(credential) then
    Log:warn(credential.owner.. " credencial inválida.")
    return false, self.invalidLease
  end
  local now = os.time()
  local lease = self.entries[credential.identifier].lease
  lease.lastUpdate = now
  lease.secondChance = false
  -- Por enquanto deixa o lease com tempo fixo
  return true, self.deltaT
end

--------------------------------------------------------------------------------
-- Faceta IComponent
--------------------------------------------------------------------------------

---
--Inicia o componente.
--
--@see scs.core.IComponent#startup
---
function startup(self)
  self = self.context.IAccessControlService
  -- instala o interceptador do serviço
  local iconfig =
    assert(loadfile(DATA_DIR.."/conf/advanced/ACSInterceptorsConfiguration.lua"))()
  self.serverInterceptor = ServerInterceptor(iconfig, self)
  orb:setserverinterceptor(self.serverInterceptor)

  -- inicializa repositorio de credenciais
  local privateKeyFile
  if (string.sub(self.config.privateKeyFile,1 , 1) == "/") then
    privateKeyFile = self.config.privateKeyFile
  else
    privateKeyFile = DATA_DIR.."/"..self.config.privateKeyFile
  end
  self.privateKey = lce.key.readprivatefrompemfile(privateKeyFile)
  local databaseDirectory
  if (string.sub(self.config.databaseDirectory,1 , 1) == "/") then
    databaseDirectory = self.config.databaseDirectory
  else
    databaseDirectory = DATA_DIR.."/"..self.config.databaseDirectory
  end
  self.credentialDB = CredentialDB(databaseDirectory)
  local entriesDB = self.credentialDB:retrieveAll()
  for _, entry in pairs(entriesDB) do
    entry.lease.lastUpdate = os.time()
    self.entries[entry.credential.identifier] = entry -- Deveria fazer cópia?
    if entry.component and entry.credential.owner == "RegistryService" then
      self.registryService = {
        credential = entry.credential,
        component = entry.component,
      }
    end
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
          Log:warn(credential.owner.. " lease expirado: LOGOUT.")
          self:logout(credential) -- you may clear existing fields.
        else
          entry.lease.secondChance = true
        end
      end
    end
  end
  self.leaseProvider = LeaseProvider(self.checkExpiredLeases, self.deltaT)
end


