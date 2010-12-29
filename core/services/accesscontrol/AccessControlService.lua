-- $Id$

local os     = os
local table  = table
local math   = math
local type = type

local loadfile = loadfile
local assert = assert
local pairs = pairs
local ipairs = ipairs
local string = string
local tostring = tostring
local print = print
local error = error
local format = string.format
local setfenv = setfenv

local luuid = require "uuid"
local lce = require "lce"
local oil = require "oil"
local Utils = require "openbus.util.Utils"
local Openbus = require "openbus.Openbus"
local SmartComponent = require "openbus.faulttolerance.SmartComponent"
local OilUtilities = require "openbus.util.OilUtilities"
local FaultTolerantService =
  require "core.services.faulttolerance.FaultTolerantService"
local PersistentReceptacle = require "scs.adaptation.PersistentReceptacle"

local LeaseProvider = require "openbus.lease.LeaseProvider"

local TableDB       = require "openbus.util.TableDB"
local CredentialDB  = require "core.services.accesscontrol.CredentialDB"
local CertificateDB = require "core.services.accesscontrol.CertificateDB"

local Log = require "openbus.util.Log"
local Audit = require "openbus.util.Audit"

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
ACSFacet.faultDescription = {_isAlive = false, _errorMsg = "" }
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
  if #self.loginPasswordValidators == 0 then
    Log:error("Não há validadores de senha cadastrados")
    return false, self.invalidCredential, self.invalidLease
  end

  for _, validator in ipairs(self.loginPasswordValidators) do
    local result, err = validator:validate(name, password)
    if result then
      local entry = self:addEntry(name)
      Audit:login_password(format("O usuário {%s, %s} executou um login",
          entry.credential.identifier, entry.credential.owner))
      return true, entry.credential, entry.lease.duration
    else
      Log:debug(format("Ocorreu um erro ao validar o usuário %s: %s", name, err))
    end
  end

  Log:warn(format("O usuário %s não pôde ser validado", name))
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
    Log:warn(format("Nao existe desafio para a entidade %s", name))
    return false, self.invalidCredential, self.invalidLease
  end

  local errorMessage
  answer, errorMessage = lce.cipher.decrypt(self.privateKey, answer)
  if not answer then
    Log:error(format("Ocorreu um erro ao descriptografas a resposta de %s: %s",
        name, errorMessage))
  end
  if answer ~= challenge then
    Log:warn(format("A resposta de %s está incorreta", name))
    return false, self.invalidCredential, self.invalidLease
  end
  self.challenges[name] = nil

  --Outra réplica tentando inserir sua credencial
  local interceptedCredential = Openbus:getInterceptedCredential()
  if interceptedCredential then
    if interceptedCredential.owner == "AccessControlService" or
      interceptedCredential.delegate == "AccessControlService" then
      local entry = self.entries[interceptedCredential.identifier]
      if not entry then
        local ftFacet = self.context.IFaultTolerantService
        if #ftFacet.ftconfig.hosts.ACS > 1 then
          local i = 1
          local stop = false
          repeat
            if ftFacet.ftconfig.hosts.ACS[i] ~= ftFacet.acsReference then
              local ret, succ, remoteACSFacet = oil.pcall(Utils.fetchService,
                Openbus:getORB(), ftFacet.ftconfig.hosts.ACS[i],
                Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
              if ret and succ then
                --encontrou outra replica
                -- Verificando credencial na replica
                stop = remoteACSFacet:isValid(interceptedCredential)
              end -- fim succ
            end -- fim , nao eh a mesma replica
            i = i + 1
          until stop or i > #ftFacet.ftconfig.hosts.ACS
          if stop then
            local entry = self:addEntryWithCredential(name, interceptedCredential, true)
            -- Credencial validada e inserida
            return true, entry.credential, entry.lease.duration
          else
            Log:error(format("A credencial {%s, %s, %s} de uma réplica não pôde ser validada no sistema",
                interceptedCredential.identifier, interceptedCredential.owner, interceptedCredential.delegate))
            return false, self.invalidCredential, self.invalidLease
          end--fim stop
        end --fim, if qt de replicas > 1
      else --ja tem entrada
        return true, entry.credential, entry.lease.duration
      end
    end -- fim, eh o ACS
  end --fim tem credencial

  --se chegou aqui, nao tem credencial ou tem mas nao eh o ACS, loga normalmente
  local entry = self:addEntry(name, true)
  Log:debug(format("A entidade %s foi autenticada com sucesso", name))

  Audit:login_certificate(format("O sistema {%s, %s, %s} executou um login",
      entry.credential.identifier, entry.credential.owner,
      entry.credential.delegate))
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
  local mgm = self.context.IManagement
  local succ, cert = oil.pcall(mgm.getSystemDeploymentCertificate, mgm, name)
  if succ then
    Log:debug(format("O certificado da entidade %s foi encontrado", name))
    return self:generateChallenge(name, lce.x509.readfromderstring(cert))
  else
    Log:warn(format("Não foi possível obter o certificado da entidade %s", name))
    return ""
  end
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
  local key = certificate:getpublickey()
  if not key then
    Log:error(format("Não foi possível obter a chave pública da entidade %s",
        name))
    return ""
  end
  local ret, erroMsg = lce.cipher.encrypt(key, randomSequence)
  if not ret then
    Log:error(erroMsg)
  end
  return ret, erroMsg
end

---
--Faz o logout de uma credencial, local e remotamente se existirem réplicas.
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
  Audit:logout(format("A credencial {%s, %s, %s} executou um logout",
      credential.identifier, credential.owner, credential.delegate))

  local interceptedCredential = Openbus:getInterceptedCredential()
  if interceptedCredential then
    if interceptedCredential.owner == "AccessControlService" or
      interceptedCredential.delegate == "AccessControlService" then
      --nao faz nada
      return true
    end
  end

  local ftFacet = self.context.IFaultTolerantService
  if not ftFacet:isFTInited() then
    return true
  end

  if #ftFacet.ftconfig.hosts.ACS <= 1 then
    Log:debug(format("Não existem réplicas cadastradas para deslogar a credencial {%s, %s, %s}",
        credential.identifier, credential.owner, credential.delegate))
    return true
  end

  local i = 1
  repeat
    if ftFacet.ftconfig.hosts.ACS[i] ~= ftFacet.acsReference then
      local ret, succ, remoteACSFacet = oil.pcall(Utils.fetchService,
        Openbus:getORB(), ftFacet.ftconfig.hosts.ACS[i],
        Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
      if ret and succ then
        --encontrou outra replica
        Log:debug(format("Requisitou logout na replica %s",
            ftFacet.ftconfig.hosts.ACS[i]))
            oil.newthread(function()
                local succ, ret = oil.pcall(
                  remoteACSFacet.logout, remoteACSFacet,
                  credential)
                end)
      else
        Log:warn(format("A réplica %s não foi encontrada", ftFacet.ftconfig.hosts.ACS[i]))
      end -- fim succ, encontrou replica
    end -- fim , nao eh a mesma replica
    i = i + 1
  until i > #ftFacet.ftconfig.hosts.ACS

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
    --VAI BUSCAR NAS REPLICAS
    --troca credenciais para verificacao de permissao na faceta FT
    local intCredential = Openbus:getInterceptedCredential()
    Openbus.serverInterceptor.picurrent:setValue(Openbus:getCredential())
    local ftFacet = self.context.IFaultTolerantService
    local gotEntry = ftFacet:updateStatus(credential)
    --desfaz a troca
    Openbus.serverInterceptor.picurrent:setValue(intCredential)

    if gotEntry then
      --tenta de novo
      entry = self.entries[credential.identifier]
    end

    if not entry then
    --realmente não encontrou
      Log:debug(format("A credencial {%s, %s, %s} não é válida",
          credential.identifier, credential.owner, credential.delegate))
      return false
    end
  end

  if credential.owner ~= entry.credential.owner then
    Log:debug(format("A credencial {%s, %s, %s} não é válida",
        credential.identifier, credential.owner, credential.delegate))
    return false
  end
  if credential.delegate ~= "" and not entry.certified then
    Log:debug(format("A credencial {%s, %s, %s} não é válida",
        credential.identifier, credential.owner, credential.delegate))
    return false
  end

  Log:debug(format("A credencial {%s, %s, %s} é válida",
      credential.identifier, credential.owner, credential.delegate))
  return true
end

---
--Verifica a validade de um array de credenciais.
--
--@param credentials O array de credenciais.
--
--@return Um array de booleanos indicando para cada credencial recebida se a
--mesma é válida ou não.
---
function ACSFacet:areValid(credentials)
  local areValid = {}
  for _, credential in ipairs(credentials) do
    local result = self:isValid(credential)
    if result then
      Log:debug(format("A credencial {%s, %s, %s} é válida",
          credential.identifier, credential.owner, credential.delegate))
    else
      Log:debug(format("A credencial {%s, %s, %s} não é válida",
          credential.identifier, credential.owner, credential.delegate))
    end
    table.insert(areValid, result)
  end
  return areValid
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

  local credential = Openbus:getInterceptedCredential()
  self.entries[credential.identifier].observers[observerId] = true

  for _, credentialId in ipairs(credentialIdentifiers) do
    local entry = self.entries[credentialId]
    if entry then
      entry.observedBy[observerId] = true
      observerEntry.credentials[credentialId] = true
    end
  end

  return observerId
end


---
--Verifica se uma credencial é válida e retorna sua entrada completa.
--
--@param credential A credencial.
--
--@return a credencial caso exista, ou uma entrada vazia caso contrário.
---
function ACSFacet:getEntryCredential(credential)
  self.context.IManagement:checkPermission()

  local emptyEntry = {
                aCredential = {  identifier = "",
                                owner = "",
                                delegate = "" },
                certified = false,
                observers = {},
                observedBy = {}
            }
  local entry = self.entries[credential.identifier]

  if not entry then
    Log:debug(format("A credencial {%s, %s, %s} não foi encontrada",
        credential.identifier, credential.owner, credential.delegate))
    return emptyEntry
  end
  Log:debug(format("A credencial {%s, %s, %s} foi encontrada",
      entry.credential.identifier, entry.credential.owner,
      entry.credential.delegate))
  local retEntry = {  aCredential = entry.credential,
                      certified = entry.certified or false,
                      observers = entry.observers or {},
                      observedBy = entry.observedBy or {}
                   }
  return retEntry
end

function ACSFacet:getAllEntryCredential()
  self.context.IManagement:checkPermission()

  local retEntries = {}
  local i = 0
  for _,entry in pairs(self.entries) do
    if entry.credential then
      i = i + 1
      retEntries[i] = {}
      retEntries[i].aCredential = entry.credential
      if entry.certified ~= nil then
       retEntries[i].certified = entry.certified
      else
       retEntries[i].certified = false
      end
      local j = 1
      retEntries[i].observers = {}
      for observerId, flag in pairs(entry.observers) do
        if flag then
          retEntries[i].observers[j] = tostring(observerId)
          j = j + 1
        end
      end
      j = 1
      retEntries[i].observedBy = {}
      for observerId, flag in pairs(entry.observedBy) do
        if flag then
          retEntries[i].observedBy[j] = tostring(observerId)
          j = j + 1
        end
      end
    end
  end
  Log:debug("Obtendo todas as %d credenciais", i)
  return retEntries
end


---
--Adiciona uma credencial à lista de credenciais de um observador.
--
--@param observerIdentifier O identificador do observador.
--@param credentialIdentifier O identificador da credencial.
--
--@return true caso a credencial tenha sido adicionada, ou false caso contrário.
---
function ACSFacet:addCredentialToObserver(observerIdentifier, credentialIdentifier)
  local entry = self.entries[credentialIdentifier]
  if not entry then
    Log:warn("Não foi possível adicionar a credential %s ao observador %s, pois a referida credencial não existe",
        credentialIdentifier, observerIdentifier)
    return false
  end

  local observerEntry = self.observers[observerIdentifier]
  if not observerEntry then
    Log:warn("Não foi possível adicionar a credential %s ao observador %s, pois o referido observador não existe",
        credentialIdentifier, observerIdentifier)
    return false
  end

  entry.observedBy[observerIdentifier] = true
  observerEntry.credentials[credentialIdentifier] = true

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
  credential = credential or Openbus:getInterceptedCredential()
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
  local duration = self.lease
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
  Log:debug(format("A credencial {%s, %s, %s} foi adicionada",
      credential.identifier, credential.owner, credential.delegate))
  return entry
end

---
-- Adiciona uma credencial cuja lease não expira.
-- Foi criado para login entre ACSs.
--
--@param name O nome da entidade para a qual a credencial será inserida.
--@param credential A credencial que será inserida.
--@param certified Boolean se credencial é certificada.
--
--@return A entrada da credencial.
---
function ACSFacet:addEntryWithCredential(name, credential, certified)
  local duration = self.lease
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
  Log:debug(format(
      "A credencial {%s, %s, %s} foi adicionada e será válida por %d segundos",
      entry.credential.identifier, entry.credential.owner,
      entry.credential.delegate, entry.lease.duration))
  return entry
end

---
--Adiciona uma credencial ao banco de dados.
--
--@param name O nome da entidade para a qual a credencial será gerada.
--
--@return A credencial.
---
function ACSFacet:addEntryCredential(entry)
  local duration = self.lease
  entry.lease = { lastUpdate = os.time(), duration = duration }
  self.credentialDB:insert(entry)
  self.entries[entry.credential.identifier] = entry
  Log:debug(format(
      "A credencial {%s, %s, %s} foi adicionada e será válida por %d segundos",
      entry.credential.identifier, entry.credential.owner,
      entry.credential.delegate, entry.lease.duration))
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

--
-- Invalida uma credential de um dado membro.
--
-- @param name OI do membro.
--
function ACSFacet:removeEntryById(name)
  local found
  for _, entry in pairs(self.entries) do
    if entry.credential.owner == name then
      found = entry
      break
    end
  end
  if found then
    self:removeEntry(found)
  end
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
  if not self:isValid(credential) then
    return false, self.invalidLease
  end
  local now = os.time()
  local lease = self.entries[credential.identifier].lease
  lease.lastUpdate = now
  lease.secondChance = false
  -- Por enquanto deixa o lease com tempo fixo
  return true, self.lease
end

--------------------------------------------------------------------------------
-- Faceta IManagement
--------------------------------------------------------------------------------

--
-- Aliases
--
local SystemInUseException = "IDL:tecgraf/openbus/core/"..Utils.OB_VERSION..
    "/access_control_service/SystemInUse:1.0"
local SystemNonExistentException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/access_control_service/SystemNonExistent:1.0"
local SystemAlreadyExistsException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/access_control_service/SystemAlreadyExists:1.0"
--
local InvalidCertificateException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/access_control_service/InvalidCertificate:1.0"
local SystemDeploymentNonExistentException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/access_control_service/SystemDeploymentNonExistent:1.0"
local SystemDeploymentAlreadyExistsException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/access_control_service/SystemDeploymentAlreadyExists:1.0"
--
local UserAlreadyExistsException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/access_control_service/UserAlreadyExists:1.0"
local UserNonExistentException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/access_control_service/UserNonExistent:1.0"


ManagementFacet = oop.class{}

---
-- Verifica se o usuário tem permissão para executar o método.
--
function ManagementFacet:checkPermission()
  local credential = Openbus:getInterceptedCredential()
  local admin = self.admins[credential.owner] or
                self.admins[credential.delegate]
  if not admin then
    error(Openbus:getORB():newexcept {
      "IDL:omg.org/CORBA/NO_PERMISSION:1.0",
      minor_code_value = 0,
      completion_status = 1,
    })
  end
end

---
-- Carrega os objetos das bases de dados.
--
function ManagementFacet:loadData()
  -- Cache de objetos
  self.systems = {}
  self.deployments = {}
  self.users = {}
  -- Carrega os usuário
  local data = assert(self.userDB:getValues())
  for _, info in ipairs(data) do
    self.users[info.id] = true
  end
  -- Carrega os sistemas
  local data = assert(self.systemDB:getValues())
  for _, info in ipairs(data) do
    self.systems[info.id] = true
  end
  -- Carrega os dados e cria as implantações dos sistemas
  data = assert(self.deploymentDB:getValues())
  for _, info in ipairs(data) do
    self.deployments[info.id] = true
  end
end

---
-- Cadastra um novo sistema.
--
-- @param id Identificador único do sistema.
-- @param description Descrição do sistema.
--
function ManagementFacet:addSystem(id, description)
  self:checkPermission()
  if self.systems[id] then
    Log:error(format("Sistema '%s' já cadastrado.", id))
    error{SystemAlreadyExistsException}
  end
  local succ, msg = self.systemDB:save(id, {
    id = id,
    description = description
  })
  if not succ then
    Log:error(format("Falha ao salvar sistema '%s': %s", id, msg))
  else
    self.systems[id] = true
    self:updateManagementStatus("addSystem",
      { id = id, description = description})
  end
end

---
-- Remove o sistema do barramento. Um sistema só poderá ser removido
-- se não possuir nenhuma implantação cadastrada que o referencia.
--
-- @param id Identificador do sistema.
--
function ManagementFacet:removeSystem(id)
  self:checkPermission()
  if not self.systems[id] then
    Log:error(format("Sistema '%s' não cadastrado.", id))
    error{SystemNonExistentException}
  end
  local depls = self.deploymentDB:getValues()
  for _, depl in ipairs(depls) do
    if depl.systemId == id then
      Log:error(format("Sistema '%s' em uso.", id))
      error{SystemInUseException}
    end
  end
  self.systems[id] = nil
  local succ, msg = self.systemDB:remove(id)
  if not succ then
    Log:error(format("Falha ao remover sistema '%s': %s", id, msg))
  else
    self:updateManagementStatus("removeSystem", { id = id})
  end
end

---
-- Atualiza a descrição do sistema.
--
-- @param id Identificador do sistema.
-- @param description Nova descrição para o sistema.
--
function ManagementFacet:setSystemDescription(id, description)
  self:checkPermission()
  if not self.systems[id] then
    Log:error(format("Sistema '%s' não cadastrado.", id))
    error{SystemNonExistentException}
  end
  local system, msg = self.systemDB:get(id)
  if system then
    local succ
    system.description = description
    succ, msg = self.systemDB:save(id, system)
    if not succ then
      Log:error(format("Falha ao salvar sistema '%s': %s", id, msg))
    else
      self:updateManagementStatus("setSystemDescription",
                         { id = id, description = description})
    end
  else
    Log:error(format("Falha ao recuperar sistema '%s': %s", id, msg))
  end
end

---
-- Recupera todos os sistemas cadastrados.
--
-- @return Uma sequência de sistemas.
--
function ManagementFacet:getSystems()
  local systems, msg = self.systemDB:getValues()
  if not systems then
    Log:error(format("Falha ao recuperar os sistemas: %s", msg))
  end
  return systems
end

---
-- Recupera um sistema dado o seu identificador.
--
-- @param id Identificador do sistema.
--
-- @return Sistema referente ao identificador.
--
function ManagementFacet:getSystem(id)
  if not self.systems[id] then
    Log:error(format("Sistema '%s' não cadastrado.", id))
    error{SystemNonExistentException}
  end
  local system, msg = self.systemDB:get(id)
  if not system then
    Log:error(format("Falha ao recuperar os sistemas: %s", msg))
  end
  return system
end

-------------------------------------------------------------------------------

---
-- Cadastra uma nova implantação para um sistema.
--
-- @param id Identificador único da implantação (estilo login UNIX).
-- @param systeId Identificador do sistema a que esta implantação pertence.
-- @param description Descrição da implantação.
--
function ManagementFacet:addSystemDeployment(id, systemId, description,
                                             certificate)
  self:checkPermission()
  if self.deployments[id] then
    Log:error(format("implantação '%s' já cadastrada.", id))
    error{SystemDeploymentAlreadyExistsException}
  end
  if not self.systems[systemId] then
    Log:error(format("Falha ao criar implantação '%s': sistema %s "..
                     "não cadastrado.", id, systemId))
    error{SystemNonExistentException}
  end
  local succ, msg = lce.x509.readfromderstring(certificate)
  if not succ then
    Log:error(format("Falha ao criar implantação '%s': certificado inválido.",
      id))
    error{InvalidCertificateException}
  end
  self.deployments[id] = true
  succ, msg = self.deploymentDB:save(id, {
    id = id,
    systemId = systemId,
    description = description,
  })
  if not succ then
    Log:error(format("Falha ao salvar implantação %s na base de dados: %s",
      id, msg))
  else
    self:updateManagementStatus("addSystemDeployment",
                                { id = id,
                                  systemId = systemId,
                                  description = description,
                                  certificate = certificate})

    succ, msg = self.certificateDB:save(id, certificate)
    if not succ then
      Log:error(format("Falha ao salvar certificado de '%s': %s", id, msg))
    end

  end

end

---
-- Remove uma implantação de sistema.
--
-- @param id Identificador da implantação.
--
function ManagementFacet:removeSystemDeployment(id)
  self:checkPermission()
  if not self.deployments[id] then
    Log:error(format("implantação '%s' não cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  self.deployments[id] = nil
  local succ, msg = self.deploymentDB:remove(id)
  if not succ then
    Log:error(format("Falha ao remover implantação '%s' da base de dados: %s",
      id, msg))
  else
    self:updateManagementStatus("removeSystemDeployment", { id = id})

    succ, msg = self.certificateDB:remove(id)
    if not succ and msg ~= "not found" then
      Log:error(format("Falha ao remover certificado da implantação '%s': %s",
        id, msg))
    end

    -- Invalida a credencial do membro que está sendo removido
    local acs = self.context.IAccessControlService
    acs:removeEntryById(id)
    -- Remove todas as autorizações do membro
    local succ, rs =  oil.pcall(Utils.getReplicaFacetByReceptacle,
      Openbus:getORB(),
      self.context.IComponent,
      "RegistryServiceReceptacle",
      "IManagement_" .. Utils.OB_VERSION,
      Utils.MANAGEMENT_RS_INTERFACE)
    if succ and rs then
      local orb = Openbus:getORB()
      rs = orb:newproxy(rs, "protected")
      rs:removeAuthorization(id)
    end
  end
end

---
-- Altera a descrição da implantação.
--
-- @param id Identificador da implantação.
-- @param description Nova descrição da implantação.
--
function ManagementFacet:setSystemDeploymentDescription(id, description)
  self:checkPermission()
  if not self.deployments[id] then
    Log:error(format("implantação '%s' não cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  local depl, msg = self.deploymentDB:get(id)
  if not depl then
    Log:error(format("Falha ao recuperar implantação '%s': %s", id, msg))
  else
    local succ
    depl.description = description
    succ, msg = self.deploymentDB:save(id, depl)
    if not succ then
      Log:error(format("Falha ao salvar implantação '%s' na base de dados: %s",
        id, msg))
    else
      self:updateManagementStatus("setSystemDeploymentDescription",
                         { id = id, description = description})
    end
  end
end

---
-- Recupera o certificado da implantação.
--
-- @param id Identificador da implantação.
--
-- @return Certificado da implantação.
--
function ManagementFacet:getSystemDeploymentCertificate(id)
  if not self.deployments[id] then
    Log:error(format("implantação '%s' não cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  local cert, msg = self.certificateDB:get(id)
  if not cert then
    Log:error(format("Falha ao recuperar certificado de '%s': %s", id, msg))
  end
  return cert
end

---
-- Altera o certificado da implantação.
--
-- @param id Identificador da implantação.
-- @param certificate Novo certificado da implantação.
--
function ManagementFacet:setSystemDeploymentCertificate(id, certificate)
  self:checkPermission()
  if not self.deployments[id] then
    Log:error(format("implantação '%s' não cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  local tmp, msg = lce.x509.readfromderstring(certificate)
  if not tmp then
    Log:error(format("%s: certificado inválido.", id, msg))
    error{InvalidCertificateException}
  end
  local succ, msg = self.certificateDB:save(id, certificate)
  if not succ then
    Log:error(format("Falha ao salvar certificado de '%s': %s", id, msg))
  else
    self:updateManagementStatus("setSystemDeploymentCertificate",
                         { id = id, certificate = certificate})
  end
end

---
-- Recupera todas implantações cadastradas.
--
-- @return Uma sequência com as implantações cadastradas.
--
function ManagementFacet:getSystemDeployments()
  local depls, msg = self.deploymentDB:getValues()
  if not depls then
    Log:error(format("Falha ao recuperar implantações: %s", msg))
  end
  return depls
end

---
-- Recupera a implantação dado o seu identificador.
--
-- @return Retorna a implantação referente ao identificador.
--
function ManagementFacet:getSystemDeployment(id)
  if not self.deployments[id] then
    Log:error(format("implantação '%s' não cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  local depl, msg = self.deploymentDB:get(id)
  if not depl then
    Log:error(format("Falha ao recuperar implantação '%s': %s", id, msg))
  end
  return depl
end

---
-- Recupera todas as implantações de um dado sistema.
--
-- @param systemId Identificador do sistema
--
-- @return sequência com as implantações referentes ao sistema informado.
--
function ManagementFacet:getSystemDeploymentsBySystemId(systemId)
  local array = {}
  local depls, msg = self.deploymentDB:getValues()
  if not depls then
    Log:error(format("Falha ao recuperar implantações: %s", msg))
  else
    for _, depl in pairs(depls) do
      if depl.systemId == systemId then
        array[#array+1] = depl
      end
    end
  end
  return array
end

-------------------------------------------------------------------------------

---
-- Cadastra um novo usuário.
--
-- @param id Identificador único do usuário.
-- @param name Nome do usuário.
--
function ManagementFacet:addUser(id, name)
  self:checkPermission()
  if self.users[id] then
    Log:error(format("usuário '%s' já cadastrado.", id))
    error{UserAlreadyExistsException}
  end
  self.users[id] = true
  succ, msg = self.userDB:save(id, {
    id = id,
    name = name
  })
  if not succ then
    Log:error(format("Falha ao salvar usuário '%s' na base de dados: %s",
      id, msg))
  else
    self:updateManagementStatus("addUser", { id = id, name = name})
  end
end

---
-- Remove um usuário do barramento.
--
-- @param id Identificador do usuário.
--
function ManagementFacet:removeUser(id)
  self:checkPermission()
  if not self.users[id] then
    Log:error(format("usuário '%s' não cadastrado.", id))
    error{UserNonExistentException}
  end
  self.users[id] = nil
  local succ, msg = self.userDB:remove(id)
  if not succ then
    Log:error(format("Falha ao remover usuário '%s' da base de dados: %s",
      id, msg))
  else
    self:updateManagementStatus("removeUser", { id = id})

    -- Remove todas as autorizações do membro
    local succ, rs =  oil.pcall(Utils.getReplicaFacetByReceptacle,
                            Openbus:getORB(),
                            self.context.IComponent,
                            "RegistryServiceReceptacle",
                            "IManagement_" .. Utils.OB_VERSION,
                            Utils.MANAGEMENT_RS_INTERFACE)
    if succ and rs then
      local orb = Openbus:getORB()
      rs = orb:newproxy(rs, "protected")
      rs:removeAuthorization(id)
    end
  end
end

---
-- Altera o nome do usuário.
--
-- @param id Identificador do usuário.
-- @param name Novo nome do usuário.
--
function ManagementFacet:setUserName(id, name)
  self:checkPermission()
  if not self.users[id] then
    Log:error(format("usuário '%s' não cadastrado.", id))
    error{UserNonExistentException}
  end
  local user, msg = self.userDB:get(id)
  if not user then
    Log:error(format("Falha ao recuperar usuário '%s': %s", id, msg))
  else
    local succ
    user.name = name
    succ, msg = self.userDB:save(id, user)
    if not succ then
      Log:error(format("Falha ao salvar usuário '%s' na base de dados: %s",
        id, msg))
    else
      self:updateManagementStatus("setUserName", { id = id, name = name})
    end
  end
end

---
-- Recupera a implantação dado o seu identificador.
--
-- @return Retorna a implantação referente ao identificador.
--
function ManagementFacet:getUser(id)
  if not self.users[id] then
    Log:error(format("usuário '%s' não cadastrado.", id))
    error{UserNonExistentException}
  end
  local user, msg = self.userDB:get(id)
  if not user then
    Log:error(format("Falha ao recuperar usuário '%s': %s", id, msg))
  end
  return user
end

---
-- Recupera todos usuários cadastrados
--
-- @return Uma sequência com os usuários.
--
function ManagementFacet:getUsers()
  local users, msg = self.userDB:getValues()
  if not users then
    Log:error(format("Falha ao recuperar usuários: %s", msg))
  end
  return users
end

function ManagementFacet:updateManagementStatus(command, data)
  local credential = Openbus:getInterceptedCredential()
  if credential.owner == "AccessControlService" or
    credential.delegate == "AccessControlService" then
    --para nao entrar em loop
    return
  end

  local ftFacet = self.context.IFaultTolerantService
  if not ftFacet:isFTInited() then
    return
  end

  if #ftFacet.ftconfig.hosts.ACS <= 1 then
    Log:debug(format(
        "Não existem réplicas cadastradas para atualizar o estado da gerência para o comando %s",
        command))
    return
  end

  local orb = Openbus:getORB()
  local i = 1
  repeat
    if ftFacet.ftconfig.hosts.ACS[i] ~= ftFacet.acsReference then
      local ret, succ, remoteACSIC = oil.pcall(Utils.fetchService,
                                               Openbus:getORB(),
                                               ftFacet.ftconfig.hosts.ACSIC[i],
                                               Utils.COMPONENT_INTERFACE)

      if ret and succ then
        --encontrou outra replica
        Log:debug(format("Requisitou comando %s na réplica %s", command,
            ftFacet.ftconfig.hosts.ACSIC[i]))
        -- Recupera faceta IManagement da replica remota
        local ok, remoteMgmFacet =  oil.pcall(remoteACSIC.getFacetByName, remoteACSIC, "IManagement_"..Utils.OB_VERSION)
        if ok then
          remoteMgmFacet = orb:narrow(remoteMgmFacet,
                           Utils.MANAGEMENT_ACS_INTERFACE)
          --*** System operations***
          if command == "addSystem" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.addSystem, remoteMgmFacet, data.id, data.description)
              end)
          elseif command == "setSystemDescription" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.setSystemDescription, remoteMgmFacet,
                                          data.id, data.description)
              end)
          elseif command == "removeSystem" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.removeSystem, remoteMgmFacet, data.id)
              end)
          --*** System Deployment operations***
          elseif command == "addSystemDeployment" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.addSystemDeployment,remoteMgmFacet,
                                          data.id,
                                          data.systemId,
                                          data.description,
                                          data.certificate)
              end)
          elseif command == "setSystemDeploymentDescription" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.setSystemDeploymentDescription, remoteMgmFacet,
                                          data.id,
                                           data.description)
              end)
          elseif command == "setSystemDeploymentCertificate" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.setSystemDeploymentCertificate, remoteMgmFacet,
                                          data.id,
                                          data.certificate)
              end)
          elseif command == "removeSystemDeployment" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.removeSystemDeployment, remoteMgmFacet, data.id)
              end)
          --*** User operations***
          elseif command == "addUser" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.addUser,remoteMgmFacet,
                                          data.id, data.name)
              end)
          elseif command == "removeUser" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.removeUser,remoteMgmFacet,
                                          data.id)
              end)
          elseif command == "setUserName" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.setUserName,remoteMgmFacet,
                                          data.id, data.name)
              end)
          end
        end -- fim ok facet IManagement
      else
        Log:error(format(
            "A réplica %s não está disponível para ser atualizada quanto ao estado da gerência para o comando %s",
            ftFacet.ftconfig.hosts.ACSIC[i], command))
      end
    end
    i = i + 1
  until i > # ftFacet.ftconfig.hosts.ACSIC
end

--------------------------------------------------------------------------------
-- Faceta IReceptacle
--------------------------------------------------------------------------------

ACSReceptacleFacet = oop.class({}, PersistentReceptacle.PersistentReceptacleFacet)

function ACSReceptacleFacet:getConnections(receptacle)
  --TODO: Generalizar esse método para o ACS e RGS porem dentro do Openbus (Maira)
  --troca credenciais para verificacao de permissao no disconnect
  local intCredential = Openbus:getInterceptedCredential()
  Openbus.serverInterceptor.picurrent:setValue(Openbus:getCredential())
  local conns = PersistentReceptacle.PersistentReceptacleFacet.getConnections(self, receptacle)
  if #conns == 0 then
    Log:warn(format("Não foi encontrada nenhuma faceta no receptáculo %s",
        receptacle))
  end
  --desfaz a troca
  Openbus.serverInterceptor.picurrent:setValue(intCredential)
  return conns
end

function ACSReceptacleFacet:connect(receptacle, object)
 self.context.IManagement:checkPermission()
 local connId = PersistentReceptacle.PersistentReceptacleFacet.connect(self,
                          receptacle,
                          object) -- calling inherited method
  local orb = Openbus:getORB()
  if connId then
    --Se for o RGS, faz a conexão de volta: [RS]--( 0--[ACS]
    if receptacle == "RegistryServiceReceptacle" then
      object = orb:narrow(object, "IDL:scs/core/IComponent:1.0")
      local rsIRecep =  object:getFacetByName("IReceptacles")
      rsIRecep = orb:narrow(rsIRecep, "IDL:scs/core/IReceptacles:1.0")
      --Verifica se ja nao esta conectado
      local acsFacet =  Utils.getReplicaFacetByReceptacle(orb,
                                                          object,
                                               "AccessControlServiceReceptacle",
                                               "IAccessControlService_" .. Utils.OB_VERSION,
                                               Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
      if not acsFacet then
        --Nao esta, vai conectar
        local status, conn = oil.pcall(rsIRecep.connect, rsIRecep,
               "AccessControlServiceReceptacle", self.context.IComponent )
        if not status then
          Log:error("Falha ao conectar o ACS no receptáculo do RGS: " ..
                    conn[1])
          PersistentReceptacle.PersistentReceptacleFacet.disconnect(self, connId)
          Log:error("Não foi possível conectar RGS ao ACS.")
          error ( orb:newexcept{"IDL:scs/core/InvalidConnection:1.0"} )
        end
      end
    end

    --SINCRONIZA COM AS REPLICAS SOMENTE SE CONECTOU COM SUCESSO
    self:updateConnectionState("connect", { receptacle = receptacle, object = object })
  end
  return connId
end

-- Disconnect nao faz a desconexao de volta: [RS]--( 0--[ACS] porque nao tem a
-- referencia para o serviço que está se desconectando
function ACSReceptacleFacet:disconnect(connId)
  self.context.IManagement:checkPermission()
  -- calling inherited method
  local status = oil.pcall(PersistentReceptacle.PersistentReceptacleFacet.disconnect, self, connId)
  if status then
    self:updateConnectionState("disconnect", { connId = connId })
  else
    Log:error("[disconnect] Não foi possível desconectar receptaculo.")
  end
end

function ACSReceptacleFacet:updateConnectionState(command, data)
  local credential = Openbus:getInterceptedCredential()
  if credential.owner == "AccessControlService" or
    credential.delegate == "AccessControlService" then
    --para nao entrar em loop
    return
  end

  local ftFacet = self.context.IFaultTolerantService
  if not ftFacet:isFTInited() then
    return
  end

  if # ftFacet.ftconfig.hosts.ACS <= 1 then
    Log:debug(format(
        "Não existem réplicas cadastradas para atualizar o estado do receptáculo para o comando %s",
        command))
    return
  end

  local orb = Openbus:getORB()
  local i = 1
  repeat
    if ftFacet.ftconfig.hosts.ACS[i] ~= ftFacet.acsReference then
      local ret, succ, remoteACSIC = oil.pcall(Utils.fetchService,
                                               orb,
                                               ftFacet.ftconfig.hosts.ACSIC[i],
                                               Utils.COMPONENT_INTERFACE)

      if ret and succ then
        --encontrou outra replica
        Log:debug(format("Requisitou comando %s no receptáculo da réplica %s",
            command, ftFacet.ftconfig.hosts.ACSIC[i]))
        -- Recupera faceta IReceptacles da replica remota
        local ok, remoteACSRecepFacet =  oil.pcall(remoteACSIC.getFacetByName, remoteACSIC, "IReceptacles")
        if ok then
          remoteACSRecepFacet = orb:narrow(remoteACSRecepFacet,
                                           "IDL:scs/core/IReceptacles:1.0")
          if command == "connect" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteACSRecepFacet.connect, remoteACSRecepFacet, data.receptacle, data.object)
              end)
          elseif command == "disconnect" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteACSRecepFacet.disconnect, remoteACSRecepFacet, data.connId)
              end)
          end
        end
      else
        Log:error(format(
            "A réplica %s não está disponível para ser atualizada quanto ao estado do receptáculo para o comando %s",
            ftFacet.ftconfig.hosts.ACSIC[i], command))
      end
    end
    i = i + 1
  until i > # ftFacet.ftconfig.hosts.ACSIC
end

--------------------------------------------------------------------------------
-- Faceta IFaultTolerantService
--------------------------------------------------------------------------------

FaultToleranceFacet = FaultTolerantService.FaultToleranceFacet
FaultToleranceFacet.ftconfig = {}

function FaultToleranceFacet:init()
  local loadConfig, err = loadfile(DATA_DIR .."/conf/ACSFaultToleranceConfiguration.lua")
  if not loadConfig then
    Log:error("O arquivo 'ACSFaultToleranceConfiguration' não pode ser " ..
        "carregado ou não existe.",err)
    os.exit(1)
  end
  setfenv(loadConfig,self)
  loadConfig()

  local acs = self.context.IAccessControlService

  local notInHostAdd = acs.config.hostName..":"
                   ..tostring(acs.config.hostPort)

  self.acsReference = "corbaloc::" .. notInHostAdd .. "/" .. Utils.ACCESS_CONTROL_SERVICE_KEY
end

function FaultToleranceFacet:updateStatus(params)
  --  O atributo _anyval so retorna em chamadas remotas, em chamadas locais (mesmo processo)
  --  deve-se acessar o parametro diretamente, além disso ,
  --  passar uma tabela no any tbm so funciona porque eh local
  -- se fosse uma chamada remota teria q ter uma struct pois senao da problema de marshall
  local input
  if not params._anyval then
    input = params
  else
    --chamada remota
    input = params._anyval
    --a permissão só é verificada em chamadas remotas
    self.context.IManagement:checkPermission()
  end

  --Atualiza estado das credenciais
  if not self:isFTInited() then
    return false
  end

  if # self.ftconfig.hosts.ACS <= 1 then
    Log:debug("Não existem réplicas cadastradas para atualizar o estado das credenciais")
    return false
  end

  if input == "all" then
    --sincroniza todas as credenciais a mais das outras replicas
    --com esta e os dados de gerencia
    Log:debug(format(
        "Sincronizando a base de credenciais com as replicas exceto %s",
        self.acsReference))
    local updated = false
    local i = 1
    local count = 0
    repeat
      if self.ftconfig.hosts.ACS[i] ~= self.acsReference then
        local ret, succ, acs = oil.pcall(Utils.fetchService,
                                         Openbus:getORB(),
                                         self.ftconfig.hosts.ACS[i],
                                         Utils.ACCESS_CONTROL_SERVICE_INTERFACE)

        if ret and succ then
          --encontrou outra replica
          local acsFacet = self.context.IAccessControlService

          local repEntries = acs:getAllEntryCredential()
          if # repEntries > 0 then
            local localEntries = acsFacet.entries
            if localEntries == nil then
              localEntries = {}
            end
            --SINCRONIZA
            for _,repEntry in pairs(repEntries) do
              if type(repEntry) ~= "number" then
                if repEntry.aCredential.identifier ~= "" then
                  local add = true
                  for _,locEntry in pairs(localEntries) do
                    if locEntry.credential.identifier ==
                      repEntry.aCredential.identifier then
                      add = false
                      break
                    end
                  end

                  if add then
                    local addEntry = {}
                    addEntry.credential = repEntry.aCredential
                    addEntry.certified = repEntry.certified
                    addEntry.observers = {}
                    for _, observerId in pairs(repEntry.observers) do
                      if type(observerId) == "string" then
                        addEntry.observers[observerId] = true
                      end
                    end
                    addEntry.observedBy = {}
                    for _, observerId in pairs(repEntry.observedBy) do
                      if type(observerId) == "string" then
                        addEntry.observedBy[observerId] = true
                      end
                    end
                    acsFacet:addEntryCredential(addEntry)
                    updated = true
                    count = count + 1
                  end -- fim if add
                end -- fim if repEntry
              end -- fim if type
            end -- fim for repEntry
          end
        end
      end
      i = i + 1
    until i > # self.ftconfig.hosts.ACS
    if updated then
      Log:debug(format("Foram obtidas %d credenciais", count))
    end
    return updated
  else
    --procura por uma credencial específica
    local credential = input
    local entryCredential = nil
    local i = 1

    repeat
      if self.ftconfig.hosts.ACS[i] ~= self.acsReference then
        Log:debug(format("Buscando a credencial {%s, %s, %s} na replica %s", credential.identifier,
            credential.owner, credential.delegate, self.ftconfig.hosts.ACS[i]))

        local ret, succ, acs = oil.pcall(Utils.fetchService,
                                         Openbus:getORB(),
                                         self.ftconfig.hosts.ACS[i],
                                         Utils.ACCESS_CONTROL_SERVICE_INTERFACE)

        if ret and succ then
          entryCredential = acs:getEntryCredential(credential)
        end
      end
      i = i + 1
    until entryCredential or i > # self.ftconfig.hosts.ACS

    local updated = false
    if entryCredential then
      if entryCredential.aCredential.identifier ~= "" then
        --ADICIONA LOCALMENTE
        local acsFacet = self.context.IAccessControlService
        local addEntry = {}
        addEntry.credential = entryCredential.aCredential
        addEntry.certified = entryCredential.certified
        addEntry.observers = {}
        for _, observerId in pairs(entryCredential.observers) do
          addEntry.observers[observerId] = true
        end
        addEntry.observedBy = {}
        for _, observerId in pairs(entryCredential.observedBy) do
          addEntry.observedBy[observerId] = true
        end
        acsFacet:addEntryCredential(addEntry)
        updated = true
      end
    end
    if not updated then
      Log:warn(format("A credencial {%s, %s, %s} não foi encontrada", credential.identifier, credential.owner,
          credential.delegate))
    end
    return updated
  end

  return false
end

function FaultToleranceFacet:isFTInited()
  if not self.ftconfig then
    Log:error("A faceta de tolerência a falhas não foi inicializada corretamente")
    return false
  end
  return true
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
  local path
  local mgm = self.context.IManagement
  local acs = self.context.IAccessControlService
  local config = acs.config

  -- O ACS precisa configurar os interceptadores manualmente
  -- pois não realiza conexão.
  Openbus.acs = acs
  Openbus:_setInterceptors()

  -- Administradores dos Serviços
  mgm.admins = {}
  for _, name in ipairs(config.administrators) do
     mgm.admins[name] = true
  end
  -- ACS, seu monitor, RGS e SS são sempre administradores
  mgm.admins.AccessControlService = true
  mgm.admins.ACSMonitor = true
  mgm.admins.RegistryService = true
  mgm.admins.SessionService = true

  acs.lease = config.lease

  local timeOut = assert(loadfile(DATA_DIR .."/conf/FTTimeOutConfiguration.lua"))()
  local minLease = timeOut.fetch.MAX_TIMES * ( timeOut.fetch.sleep +
          (timeOut.non_existent.MAX_TIMES * timeOut.non_existent.sleep) )
  if (acs.lease < minLease) then
     Log:warn(format(
         "O valor (%d segundos) definido para a duração do lease deveria ser maior que o tempo total de falha (%d segundos)", acs.lease, minLease))
  end

  -- Inicializa as base de dados de gerenciamento
  mgm.userDB = TableDB(DATA_DIR .. "/acs_user.db")
  mgm.systemDB = TableDB(DATA_DIR .. "/acs_system.db")
  mgm.deploymentDB = TableDB(DATA_DIR .. "/acs_deployment.db")
  -- Carrega a cache
  mgm:loadData()

  -- Inicializa a gerência de certificados
  if string.match(config.certificatesDirectory, "^/") then
    path = config.certificatesDirectory
  else
    path = DATA_DIR .. "/" .. config.certificatesDirectory
  end
  mgm.certificateDB = CertificateDB(path)

  -- Carrega chave privada
  if string.match(config.privateKeyFile, "^/") then
    path = config.privateKeyFile
  else
    path = DATA_DIR .. "/" .. config.privateKeyFile
  end
  acs.privateKey = lce.key.readprivatefrompemfile(path)

  -- Inicializa repositorio de credenciais
  local acsEntry
  if string.match(config.databaseDirectory, "^/") then
    path = config.databaseDirectory
  else
    path = DATA_DIR .. "/" .. config.databaseDirectory
  end
  acs.credentialDB = CredentialDB(path)
  local entriesDB = acs.credentialDB:retrieveAll()
  for _, entry in pairs(entriesDB) do
    entry.lease.lastUpdate = os.time()
    acs.entries[entry.credential.identifier] = entry -- Deveria fazer cópia?
    if entry.credential.owner == "AccessControlService" then
      acsEntry = entry
    end
  end

  -- Se a credencial do ACS não existir (primeira execução), criar uma nova
  acsEntry = acsEntry or acs:addEntry("AccessControlService", true)
  -- Credencial não expira
  acsEntry.lease.duration = math.huge
  Openbus:setCredential(acsEntry.credential)

  -- Controle de leasing
  acs.checkExpiredLeases = function()
    -- Uma corotina só percorre a tabela de tempos em tempos
    -- ou precisamos acordar na hora "exata" que cada lease expira
    -- pra verificar?
    for id, entry in pairs(acs.entries) do
      local credential = entry.credential
      Log:debug(format(
          "Verificando a validade do lease da credencial {%s, %s, %s}",
          id, credential.owner, credential.delegate))
      local lastUpdate = entry.lease.lastUpdate
      local secondChance = entry.lease.secondChance
      local duration = entry.lease.duration
      if entry.credential.owner ~= "AccessControlService" then
        local now = os.time()
        if (os.difftime (now, lastUpdate) > duration ) then
          if secondChance then
            Log:info(format("O lease da credencial {%s, %s, %s} expirou",
                credential.identifier, credential.owner, credential.delegate))
            acs:logout(credential) -- you may clear existing fields.
          else
            entry.lease.secondChance = true
          end
        end
      end
    end
  end
  acs.leaseProvider = LeaseProvider(acs.checkExpiredLeases, acs.lease)
  Log:info("Recuperando os receptáculos salvos em disco...")
  local acsRecepFacet = self.context.IReceptacles
  -- recupera conexoes salvas em disco, se existirem.
  local recoveredConns = acsRecepFacet:getConnections("RegistryServiceReceptacle")
  Log:info(format("Foram recuperados %d receptáculos para o serviço de registro",
      #recoveredConns))

  local ftFacet = self.context.IFaultTolerantService
  ftFacet:init()

  if # ftFacet.ftconfig.hosts.ACS <= 1 then
    Log:warn("Nenhuma replica para buscar conexões com Serviço de Registro")
    return
  end

  local orb = Openbus:getORB()
  local i = 1
  repeat
    if ftFacet.ftconfig.hosts.ACS[i] ~= ftFacet.acsReference then
      local ret, succ, remoteACSIC = oil.pcall(Utils.fetchService,
                                               orb,
                                               ftFacet.ftconfig.hosts.ACSIC[i],
                                               Utils.COMPONENT_INTERFACE)

      if ret and succ then
        --encontrou outra replica
        Log:debug(format(
            "Buscando conexões com o Serviço de Registro na replica %s", ftFacet.ftconfig.hosts.ACSIC[i]))
        -- Recupera faceta IAccessControlService da replica remota
        local ok, remoteACSFacet =  oil.pcall(remoteACSIC.getFacet, remoteACSIC, Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
        remoteACSFacet = orb:narrow(remoteACSFacet,
                                    Utils.ACCESS_CONTROL_SERVICE_INTERFACE)

        local acsChallenge = remoteACSFacet:getChallenge("AccessControlService")
        if acsChallenge and #acsChallenge > 0 then
          if acs.privateKey then
            local succ, err
            succ, acsChallenge, err = oil.pcall(lce.cipher.decrypt, acs.privateKey, acsChallenge)
            if acsChallenge then
              local certificate, err = lce.x509.readfromderfile(DATA_DIR .. "/" .. config.accessControlServiceCertificateFile)
              if certificate then
                local answer, err = lce.cipher.encrypt(certificate:getpublickey(), acsChallenge)
                if answer then
                  local succ, remoteACSCredential, lease =
                    remoteACSFacet:loginByCertificate("AccessControlService", answer)
                  if succ then
                    -- Recupera faceta IReceptacles da replica remota
                    local ok, remoteACSRecepFacet =  oil.pcall(remoteACSIC.getFacetByName, remoteACSIC, "IReceptacles")
                    if ok then
                      remoteACSRecepFacet = orb:narrow(remoteACSRecepFacet,
                                                       "IDL:scs/core/IReceptacles:1.0")
                      --Recupera conexoes do Servico de Registro
                      local status, conns = oil.pcall(remoteACSRecepFacet.getConnections,
                                                      remoteACSRecepFacet,
                                                      "RegistryServiceReceptacle")
                      if not status then
                        Log:warn("Nao foi possivel obter o Serviço [IRegistryService_" .. Utils.OB_VERSION .. "]: " .. conns[1])
                        return
                      elseif conns[1] then
                        for connId,conn in pairs(conns) do
                          if type (conn) == "table" then
                            local recepIC = conn.objref
                            recepIC = orb:narrow(recepIC, "IDL:scs/core/IComponent:1.0")
                            if recepIC then
                              --Connecta localmente direto na PersistentReceptacle
                              --para nao ativar atualizacao nas replicas
                              local cid = PersistentReceptacle.PersistentReceptacleFacet.connect(acsRecepFacet, "RegistryServiceReceptacle", recepIC)
                              Log:debug(format(
                                  "Conexão com o Serviço de Registro recuperada e identificada por %s", cid))
                            end
                          end
                        end -- fim for
                      end --fim elseif
                    end -- fim ok
                  else
                    Log:error(format("Não foi possível se autenticar na replica %s",
                        ftFacet.ftconfig.hosts.ACSIC[i]))
                  end -- fim succ, conseguiu logar
                else
                  Log:error(format(
                      "Não foi possível gerar a resposta para o desafio: %s", err))
                end --fim answer
              else
                Log:error(format("Erro na leitura do certificado: %s", err))
              end -- fim certificate
            else
              Log:error(format("Erro ao abrir o desafio: %s", err))
            end --fim challenge
          else --fim privatekey
            Log:error(format("Erro na leitura da chave privada."))
          end
        else
          Log:error("Não foi possível obter desafio para deploymentId: AccessControlService.")
        end -- fim challenge
      elseif not ret then
        Log:error(format("Não foi possível obter a faceta %s: %s", ftFacet.ftconfig.hosts.ACSIC[i], succ))
      else
        Log:error(format("Não foi possível obter a faceta %s: %s", ftFacet.ftconfig.hosts.ACSIC[i],
            tostring(remoteACSIC)))
      end -- fim succ
    end -- fim se nao eh a mesma replica
    i = i + 1
  until i > # ftFacet.ftconfig.hosts.ACSIC
end

---
--Finaliza o Serviço.
--
--@see scs.core.IComponent#shutdown
---
function shutdown(self)
  local acs = self.context.IAccessControlService
  acs.leaseProvider:stopCheck()
  local orb = Openbus:getORB()
  orb:deactivate(acs)
  orb:deactivate(self.context.IManagement)
  orb:deactivate(self.context.ILeaseProvider)
  orb:deactivate(self.context.IFaultTolerantService)
  orb:deactivate(self.context.IComponent)
  --Mata as threads de validação de credencial e de atualização do estado
  --e chama o finish que por sua vez mata o orb
  Openbus:destroy()
end

