-- $Id$

local os     = os
local string = string
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

local luuid = require "uuid"
local lce = require "lce"
local oil = require "oil"
local Utils = require "openbus.util.Utils"
local Openbus = require "openbus.Openbus"
local SmartComponent = require "openbus.faulttolerance.SmartComponent"
local OilUtilities = require "openbus.util.OilUtilities"
local FaultTolerantService =
  require "core.services.faulttolerance.FaultTolerantService"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

local LeaseProvider = require "openbus.lease.LeaseProvider"

local TableDB       = require "openbus.util.TableDB"
local CredentialDB  = require "core.services.accesscontrol.CredentialDB"
local CertificateDB = require "core.services.accesscontrol.CertificateDB"

local Log = require "openbus.util.Log"

local scs = require "scs.core.base"

local oop = require "loop.simple"


---
--Componente respons�vel pelo Servi�o de Controle de Acesso
---
module("core.services.accesscontrol.AccessControlService")

--------------------------------------------------------------------------------
-- Faceta IAccessControlService
--------------------------------------------------------------------------------

local DATA_DIR = os.getenv("OPENBUS_DATADIR")

ACSFacet = oop.class{}

---
--Credencial inv�lida.
--
--@class table
--@name invalidCredential
--
--@field identifier O identificador da credencial que, neste caso, � vazio.
--@field owner O nome da entidade dona da credencial que, neste caso, � vazio.
--@field delegate O nome da entidade delegada que, neste caso, � vazio.
---
ACSFacet.invalidCredential = {identifier = "", owner = "", delegate = ""}
ACSFacet.invalidLease = -1
ACSFacet.faultDescription = {_isAlive = false, _errorMsg = "" }
---
--Realiza um login de uma entidade atrav�s de usu�rio e senha.
--
--@param name O nome da entidade.
--@param password A senha da entidade.
--
--@return true, a credencial da entidade e o lease caso o login seja realizado
--com sucesso, ou false e uma credencial e uma lease inv�lidos, caso contr�rio.
---
function ACSFacet:loginByPassword(name, password)
  for _, validator in ipairs(self.loginPasswordValidators) do
    local result, err = validator:validate(name, password)
    if result then
      local entry = self:addEntry(name)
      return true, entry.credential, entry.lease.duration
    else
       Log:warn(format("Erro ao validar o usu�rio %s: %s", name, err))
    end
  end
  Log:error("usu�rio "..name.." n�o p�de ser validado no sistema.")
  return false, self.invalidCredential, self.invalidLease
end

---
--Realiza um login de um membro atrav�s de assinatura digital.
--
--@param name OI nome do membro.
--@param answer A resposta para um desafio previamente obtido.
--
--@return true, a credencial do membro e o lease caso o login seja realizado
--com sucesso, ou false e uma credencial e uma lease inv�lidos, caso contr�rio.
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
    errorMessage = errorMessage or "desafio inv�lido"
    Log:error(format("Erro ao obter a resposta de %s: %s", name, errorMessage))
    return false, self.invalidCredential, self.invalidLease
  end
  self.challenges[name] = nil
  local entry = self:addEntry(name, true)
  Log:access_control("Usuario [" .. name .. "] logado com credencial [".. entry.credential.identifier .."].")
  return true, entry.credential, entry.lease.duration
end

---
--Obt�m o desafio para um membro.
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
    Log:access_control("Desafio obtido do Management para usuario [" .. name .. "] com certificado.")
    return self:generateChallenge(name, lce.x509.readfromderstring(cert))
  end
  Log:error("Erro ao obter a desafio de : " .. name)
  return ""
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
  Log:access_control("Gerando desafio para ("..name..")")
  local randomSequence = tostring(luuid.new("time"))
  self.challenges[name] = randomSequence
  local key = certificate:getpublickey()
  if key then
     Log:access_control("Chave privada obtida.")
  else
     Log:error("N�o foi poss�vel obter a chave privada.")
     return ""
  end
  local ret, erroMsg = lce.cipher.encrypt(key, randomSequence)
  if not ret then
     Log:error(erroMsg)
  end
  return ret, erroMsg
end

---
--Faz o logout de uma credencial.
--
--@param credential A credencial.
--
--@return true caso a credencial estivesse logada, ou false caso contr�rio.
---
function ACSFacet:logout(credential)
  local entry = self.entries[credential.identifier]
  if not entry then
    Log:warn("Tentativa de logout com credencial inexistente: "..
      credential.identifier)
    return false
  end
  self:removeEntry(entry)
  return true
end

---
--Verifica se uma credencial � v�lida.
--
--@param credential A credencial.
--
--@return true caso a credencial seja v�lida, ou false caso contr�rio.
---
function ACSFacet:isValid(credential)
  Log:access_control("Validando a credencial {"..credential.identifier.." - "..
      credential.owner.."/"..credential.delegate.."}")
  local entry = self.entries[credential.identifier]
  if not entry then
  --VAI BUSCAR NAS REPLICAS
    local ftFacet = self.context.IFaultTolerantService
    local gotEntry = ftFacet:updateStatus(credential)
    if gotEntry then
       --tenta de novo
       entry = self.entries[credential.identifier]
    end

    if not entry then
    --realmente n�o encontrou
       Log:access_control("A credencial {"..credential.identifier.." - "..
        credential.owner.."/"..credential.delegate.."} n�o � v�lida.")
       return false
    end
  end

  if entry.credential.delegate ~= "" and not entry.certified then
    Log:access_control("A credencial {"..credential.identifier.." - "..
        credential.owner.."/"..credential.delegate.."} n�o � v�lida.")
    return false
  end
  Log:access_control("A credencial {"..credential.identifier.." - "..
      credential.owner.."/"..credential.delegate.."} � v�lida.")
  return true
end

---
--Verifica a validade de um array de credenciais.
--
--@param credentials O array de credenciais.
--
--@return Um array de booleanos indicando para cada credencial recebida se a
--mesma � v�lida ou n�o.
---
function ACSFacet:areValid(credentials)
  local areValid = {}
  for _, credential in ipairs(credentials) do
    local result = self:isValid(credential)
    Log:access_control(credential.identifier.." - "..tostring(result))
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
--Verifica se uma credencial � v�lida e retorna sua entrada completa.
--
--@param credential A credencial.
--
--@return a credencial caso exista, ou nil caso contr�rio.
---
function ACSFacet:getEntryCredential(credential)

  local duration = self.lease
  local emptyEntry = {
                credential = {  identifier = "",
                                owner = "",
                                delegate = "" },
                certified = false,
                lease = { lastUpdate = os.time(), duration = duration },
                observers = {},
                observedBy = ""
            }
  local entry = self.entries[credential.identifier]

  if not entry then
    return emptyEntry
  end
  if entry.credential.identifier ~= credential.identifier then
    return emptyEntry
  end
  if entry.credential.delegate ~= "" and not entry.certified then
    return emptyEntry
  end
  return entry
end

function ACSFacet:getAllEntryCredential()
  local credential = Openbus:getInterceptedCredential()
  if credential.owner ~= "AccessControlService" then
     error(Openbus:getORB():newexcept {
       "IDL:omg.org/CORBA/NO_PERMISSION:1.0",
       minor_code_value = 0,
       completion_status = 1,
    })
  end

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
  Log:access_control("[getAllEntryCredential]Recuperando todas as [" .. tostring(i) .."] entradas")
  return retEntries
end


---
--Adiciona uma credencial � lista de credenciais de um observador.
--
--@param observerIdentifier O identificador do observador.
--@param credentialIdentifier O identificador da credencial.
--
--@return true caso a credencil tenha sido adicionada, ou false caso contr�rio.
---
function ACSFacet:addCredentialToObserver(observerIdentifier, credentialIdentifier)
  local entry = self.entries[credentialIdentifier]
  if not entry then
    --VAI BUSCAR NAS REPLICAS
    local ftFacet = self.context.IFaultTolerantService
    local params = { credential = credential,
                    notInHostAdd = self.config.hostName..":"
                                   ..tostring(self.config.hostPort) }
    local gotEntry = ftFacet:updateStatus(params)
    if gotEntry then
       --tenta de novo
       entry = self.entries[credential.identifier]
    end

    if not entry then
    --realmente n�o encontrou
       Log:access_control("A credencial {"..credential.identifier.." - "..
        credential.owner.."/"..credential.delegate.."} n�o � v�lida.")
       return false
    end
  end

  local observerEntry = self.observers[observerIdentifier]
  if not observerEntry then
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
--@return true caso o observador tenha sido removido, ou false caso contr�rio.
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
--@return true caso a credencial seja removida, ou false caso contr�rio.
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
--@param name O nome da entidade para a qual a credencial ser� gerada.
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
  return entry
end

---
--Adiciona uma credencial ao banco de dados.
--
--@param name O nome da entidade para a qual a credencial ser� gerada.
--
--@return A credencial.
---
function ACSFacet:addEntryCredential(entry)
  local duration = self.lease
  entry.lease = { lastUpdate = os.time(), duration = duration }
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
--Envia aos observadores a notifica��o de que um credencial n�o existe mais.
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
    Log:warn(credential.owner.. " credencial inv�lida.")
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
local SystemInUseException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemInUse:1.0"
local SystemNonExistentException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemNonExistent:1.0"
local SystemAlreadyExistsException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemAlreadyExists:1.0"
--
local InvalidCertificateException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/InvalidCertificate:1.0"
local SystemDeploymentNonExistentException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemDeploymentNonExistent:1.0"
local SystemDeploymentAlreadyExistsException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemDeploymentAlreadyExists:1.0"
--
local UserAlreadyExistsException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/UserAlreadyExists:1.0"
local UserNonExistentException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/UserNonExistent:1.0"


ManagementFacet = oop.class{}

---
-- Verifica se o usu�rio tem permiss�o para executar o m�todo.
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
  -- Carrega os usu�rio
  local data = assert(self.userDB:getValues())
  for _, info in ipairs(data) do
    self.users[info.id] = true
  end
  -- Carrega os sistemas
  local data = assert(self.systemDB:getValues())
  for _, info in ipairs(data) do
    self.systems[info.id] = true
  end
  -- Carrega os dados e cria as implanta��es dos sistemas
  data = assert(self.deploymentDB:getValues())
  for _, info in ipairs(data) do
    self.deployments[info.id] = true
  end
end

---
-- Cadastra um novo sistema.
--
-- @param id Identificador �nico do sistema.
-- @param description Descri��o do sistema.
--
function ManagementFacet:addSystem(id, description)
  self:checkPermission()
  if self.systems[id] then
    Log:error(format("Sistema '%s' j� cadastrado.", id))
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
-- Remove o sistema do barramento. Um sistema s� poder� ser removido
-- se n�o possuir nenhuma implanta��o cadastrada que o referencia.
--
-- @param id Identificador do sistema.
--
function ManagementFacet:removeSystem(id)
  self:checkPermission()
  if not self.systems[id] then
    Log:error(format("Sistema '%s' n�o cadastrado.", id))
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
-- Atualiza a descri��o do sistema.
--
-- @param id Identificador do sistema.
-- @param description Nova descri��o para o sistema.
--
function ManagementFacet:setSystemDescription(id, description)
  self:checkPermission()
  if not self.systems[id] then
    Log:error(format("Sistema '%s' n�o cadastrado.", id))
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
-- @return Uma sequ�ncia de sistemas.
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
    Log:error(format("Sistema '%s' n�o cadastrado.", id))
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
-- Cadastra uma nova implanta��o para um sistema.
--
-- @param id Identificador �nico da implanta��o (estilo login UNIX).
-- @param systeId Identificador do sistema a que esta implanta��o pertence.
-- @param description Descri��o da implanta��o.
--
function ManagementFacet:addSystemDeployment(id, systemId, description,
                                             certificate)
  self:checkPermission()
  if self.deployments[id] then
    Log:error(format("implanta��o '%s' j� cadastrada.", id))
    error{SystemDeploymentAlreadyExistsException}
  end
  if not self.systems[systemId] then
    Log:error(format("Falha ao criar implanta��o '%s': sistema %s "..
                     "n�o cadastrado.", id, systemId))
    error{SystemNonExistentException}
  end
  local succ, msg = lce.x509.readfromderstring(certificate)
  if not succ then
    Log:error(format("Falha ao criar implanta��o '%s': certificado inv�lido.",
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
    Log:error(format("Falha ao salvar implanta��o %s na base de dados: %s",
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
-- Remove uma implanta��o de sistema.
--
-- @param id Identificador da implanta��o.
--
function ManagementFacet:removeSystemDeployment(id)
  self:checkPermission()
  if not self.deployments[id] then
    Log:error(format("implanta��o '%s' n�o cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  self.deployments[id] = nil
  local succ, msg = self.deploymentDB:remove(id)
  if not succ then
    Log:error(format("Falha ao remover implanta��o '%s' da base de dados: %s",
      id, msg))
  else
    self:updateManagementStatus("removeSystemDeployment", { id = id})

    succ, msg = self.certificateDB:remove(id)
    if not succ and msg ~= "not found" then
       Log:error(format("Falha ao remover certificado da implanta��o '%s': %s",
            id, msg))
    end

    -- Invalida a credencial do membro que est� sendo removido
    local acs = self.context.IAccessControlService
    acs:removeEntryById(id)
    -- Remove todas as autoriza��es do membro
    local succ, rs =  oil.pcall(Utils.getReplicaFacetByReceptacle,
      Openbus:getORB(),
      self.context.IComponent,
      "RegistryServiceReceptacle",
      "IManagement_v" .. Utils.OB_VERSION,
      Utils.MANAGEMENT_RS_INTERFACE)
    if succ and rs then
       rs.__try:removeAuthorization(id)
    end
  end
end

---
-- Altera a descri��o da implanta��o.
--
-- @param id Identificador da implanta��o.
-- @param description Nova descri��o da implanta��o.
--
function ManagementFacet:setSystemDeploymentDescription(id, description)
  self:checkPermission()
  if not self.deployments[id] then
    Log:error(format("implanta��o '%s' n�o cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  local depl, msg = self.deploymentDB:get(id)
  if not depl then
    Log:error(format("Falha ao recuperar implanta��o '%s': %s", id, msg))
  else
    local succ
    depl.description = description
    succ, msg = self.deploymentDB:save(id, depl)
    if not succ then
      Log:error(format("Falha ao salvar implanta��o '%s' na base de dados: %s",
        id, msg))
    else
        self:updateManagementStatus("setSystemDeploymentDescription",
                         { id = id, description = description})
    end
  end
end

---
-- Recupera o certificado da implanta��o.
--
-- @param id Identificador da implanta��o.
--
-- @return Certificado da implanta��o.
--
function ManagementFacet:getSystemDeploymentCertificate(id)
  if not self.deployments[id] then
    Log:error(format("implanta��o '%s' n�o cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  local cert, msg = self.certificateDB:get(id)
  if not cert then
    Log:error(format("Falha ao recuperar certificado de '%s': %s", id, msg))
  end
  return cert
end

---
-- Altera o certificado da implanta��o.
--
-- @param id Identificador da implanta��o.
-- @param certificate Novo certificado da implanta��o.
--
function ManagementFacet:setSystemDeploymentCertificate(id, certificate)
  self:checkPermission()
  if not self.deployments[id] then
    Log:error(format("implanta��o '%s' n�o cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  local tmp, msg = lce.x509.readfromderstring(certificate)
  if not tmp then
    Log:error(format("%s: certificado inv�lido.", id, msg))
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
-- Recupera todas implanta��es cadastradas.
--
-- @return Uma sequ�ncia com as implanta��es cadastradas.
--
function ManagementFacet:getSystemDeployments()
  local depls, msg = self.deploymentDB:getValues()
  if not depls then
    Log:error(format("Falha ao recuperar implanta��es: %s", msg))
  end
  return depls
end

---
-- Recupera a implanta��o dado o seu identificador.
--
-- @return Retorna a implanta��o referente ao identificador.
--
function ManagementFacet:getSystemDeployment(id)
  if not self.deployments[id] then
    Log:error(format("implanta��o '%s' n�o cadastrada.", id))
    error{SystemDeploymentNonExistentException}
  end
  local depl, msg = self.deploymentDB:get(id)
  if not depl then
    Log:error(format("Falha ao recuperar implanta��o '%s': %s", id, msg))
  end
  return depl
end

---
-- Recupera todas as implanta��es de um dado sistema.
--
-- @param systemId Identificador do sistema
--
-- @return sequ�ncia com as implanta��es referentes ao sistema informado.
--
function ManagementFacet:getSystemDeploymentsBySystemId(systemId)
  local array = {}
  local depls, msg = self.deploymentDB:getValues()
  if not depls then
    Log:error(format("Falha ao recuperar implanta��es: %s", msg))
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
-- Cadastra um novo usu�rio.
--
-- @param id Identificador �nico do usu�rio.
-- @param name Nome do usu�rio.
--
function ManagementFacet:addUser(id, name)
  self:checkPermission()
  if self.users[id] then
    Log:error(format("usu�rio '%s' j� cadastrado.", id))
    error{UserAlreadyExistsException}
  end
  self.users[id] = true
  succ, msg = self.userDB:save(id, {
    id = id,
    name = name
  })
  if not succ then
    Log:error(format("Falha ao salvar usu�rio '%s' na base de dados: %s",
      id, msg))
  else
    self:updateManagementStatus("addUser", { id = id, name = name})
  end
end

---
-- Remove um usu�rio do barramento.
--
-- @param id Identificador do usu�rio.
--
function ManagementFacet:removeUser(id)
  self:checkPermission()
  if not self.users[id] then
    Log:error(format("usu�rio '%s' n�o cadastrado.", id))
    error{UserNonExistentException}
  end
  self.users[id] = nil
  local succ, msg = self.userDB:remove(id)
  if not succ then
    Log:error(format("Falha ao remover usu�rio '%s' da base de dados: %s",
      id, msg))
  else
     self:updateManagementStatus("removeUser", { id = id})

     -- Remove todas as autoriza��es do membro
     local succ, rs =  oil.pcall(Utils.getReplicaFacetByReceptacle,
                            Openbus:getORB(),
                            self.context.IComponent,
                            "RegistryServiceReceptacle",
                            "IManagement_v" .. Utils.OB_VERSION,
                            Utils.MANAGEMENT_RS_INTERFACE)
     if succ and rs then
         rs.__try:removeAuthorization(id)
     end
  end

end

---
-- Altera o nome do usu�rio.
--
-- @param id Identificador do usu�rio.
-- @param name Novo nome do usu�rio.
--
function ManagementFacet:setUserName(id, name)
  self:checkPermission()
  if not self.users[id] then
    Log:error(format("usu�rio '%s' n�o cadastrado.", id))
    error{UserNonExistentException}
  end
  local user, msg = self.userDB:get(id)
  if not user then
    Log:error(format("Falha ao recuperar usu�rio '%s': %s", id, msg))
  else
    local succ
    user.name = name
    succ, msg = self.userDB:save(id, user)
    if not succ then
      Log:error(format("Falha ao salvar usu�rio '%s' na base de dados: %s",
        id, msg))
    else
      self:updateManagementStatus("setUserName", { id = id, name = name})
    end
  end
end

---
-- Recupera a implanta��o dado o seu identificador.
--
-- @return Retorna a implanta��o referente ao identificador.
--
function ManagementFacet:getUser(id)
  if not self.users[id] then
    Log:error(format("usu�rio '%s' n�o cadastrado.", id))
    error{UserNonExistentException}
  end
  local user, msg = self.userDB:get(id)
  if not user then
    Log:error(format("Falha ao recuperar usu�rio '%s': %s", id, msg))
  end
  return user
end

---
-- Recupera todos usu�rios cadastrados
--
-- @return Uma sequ�ncia com os usu�rios.
--
function ManagementFacet:getUsers()
  local users, msg = self.userDB:getValues()
  if not users then
    Log:error(format("Falha ao recuperar usu�rios: %s", msg))
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
    Log:faulttolerance("[updateManagementStatus] Atualiza estado da gerencia para o comando[".. command .."].")
    local ftFacet = self.context.IFaultTolerantService
    if not ftFacet.ftconfig then
        Log:faulttolerance("[updateManagementStatus] Faceta precisa ser inicializada antes de ser chamada.")
        Log:warn("[updateManagementStatus] n�o foi poss�vel executar 'updateManagementStatus'")
        return false
    end

    if # ftFacet.ftconfig.hosts.ACS <= 1 then
        Log:faulttolerance("[updateManagementStatus] Nenhuma replica para atualizar estado da gerencia.")
        return false
    end

    local i = 1
    repeat
        if ftFacet.ftconfig.hosts.ACS[i] ~= ftFacet.acsReference then
            local ret, succ, remoteACSIC = oil.pcall(Utils.fetchService,
                                                Openbus:getORB(),
                                                ftFacet.ftconfig.hosts.ACSIC[i],
                                                Utils.COMPONENT_INTERFACE)

            if succ then
            --encontrou outra replica
                Log:faulttolerance("[updateManagementStatus] Atualizando replica ".. ftFacet.ftconfig.hosts.ACSIC[i] ..".")
                 -- Recupera faceta IManagement da replica remota
                local ok, remoteMgmFacet =  oil.pcall(remoteACSIC.getFacetByName, remoteACSIC, "IManagement_v"..Utils.OB_VERSION)
                if ok then
                     local orb = Openbus:getORB()
                     remoteMgmFacet = orb:narrow(remoteMgmFacet,
                           Utils.MANAGEMENT_ACS_INTERFACE)
                     --*** System operations***
                     if command == "addSystem" then
                         oil.newthread(function()
                                          local succ, ret = oil.pcall(remoteMgmFacet.addSystem, remoteMgmFacet, data.id, data.description)
                                       end)
                     elseif command == "setSystemDescription" then
                         oil.newthread(function()
                                          local succ, ret = oil.pcall(remoteMgmFacet.setSystemDescription,  remoteMgmFacet,
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
                end
            end
        end
        i = i + 1
    until i > # ftFacet.ftconfig.hosts.ACSIC
    Log:faulttolerance("[updateManagementStatus] Replicas atualizadas quanto ao estado das interfaces e autorizacoes para o comando[".. command .."].")
end

--------------------------------------------------------------------------------
-- Faceta IReceptacle
--------------------------------------------------------------------------------

ACSReceptacleFacet = oop.class({}, AdaptiveReceptacle.AdaptiveReceptacleFacet)

function ACSReceptacleFacet:connect(receptacle, object)
 local connId = AdaptiveReceptacle.AdaptiveReceptacleFacet.connect(self,
                          receptacle,
                          object) -- calling inherited method
  if connId then
  --SINCRONIZA COM AS REPLICAS SOMENTE SE CONECTOU COM SUCESSO
    self:updateConnectionState("connect", { receptacle = receptacle, object = object })
  end
  return connId
end

function ACSReceptacleFacet:disconnect(connId)
  -- calling inherited method
  local status, void = oil.pcall(AdaptiveReceptacle.AdaptiveReceptacleFacet.disconnect,
                                AdaptiveReceptacle.AdaptiveReceptacleFacet, connId)
  if not status then
    Log:error("[IReceptacles::IReceptacles] Error while calling disconnect")
    Log:error("[IReceptacles::IReceptacles] Error: " .. void)
  else
      --SINCRONIZA COM AS REPLICAS SOMENTE SE DESCONECTOU COM SUCESSO
      self:updateConnectionState("disconnect", { connId = connId })
  end
end

function ACSReceptacleFacet:updateConnectionState(command, data)
    local credential = Openbus:getInterceptedCredential()
    if credential.owner == "AccessControlService" or
       credential.delegate == "AccessControlService" then
       --para nao entrar em loop
         return
    end
    Log:faulttolerance("[updateConnectionState] Atualiza estado do ACS quanto ao [".. command .."].")
    local ftFacet = self.context.IFaultTolerantService
    if not ftFacet.ftconfig then
        Log:faulttolerance("[updateConnectionState] Faceta precisa ser inicializada antes de ser chamada.")
        Log:warn("[updateConnectionState] n�o foi poss�vel atualizar estado quanto ao [".. command .."]")
        return
    end

    if # ftFacet.ftconfig.hosts.ACS <= 1 then
        Log:faulttolerance("[updateConnectionState] Nenhuma replica para atualizar estado quanto ao [".. command .."].")
        return
    end

    local i = 1
    repeat
        if ftFacet.ftconfig.hosts.ACS[i] ~= ftFacet.acsReference then
            local ret, succ, remoteACSIC = oil.pcall(Utils.fetchService,
                                                Openbus:getORB(),
                                                ftFacet.ftconfig.hosts.ACSIC[i],
                                                Utils.COMPONENT_INTERFACE)

            if succ then
            --encontrou outra replica
                Log:faulttolerance("[updateConnectionState] Atualizando replica ".. ftFacet.ftconfig.hosts.ACSIC[i] ..".")
                 -- Recupera faceta IReceptacles da replica remota
                local ok, remoteACSRecepFacet =  oil.pcall(remoteACSIC.getFacetByName, remoteACSIC, "IReceptacles")
                if ok then
                     local orb = Openbus:getORB()
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
            end
        end
        i = i + 1
    until i > # ftFacet.ftconfig.hosts.ACSIC
    Log:faulttolerance("[updateConnectionState] Replicas atualizadas quanto ao [".. command .."].")
end

--------------------------------------------------------------------------------
-- Faceta IFaultTolerantService
--------------------------------------------------------------------------------

FaultToleranceFacet = FaultTolerantService.FaultToleranceFacet
FaultToleranceFacet.ftconfig = {}

function FaultToleranceFacet:init()
  self.ftconfig = assert(loadfile(DATA_DIR .."/conf/ACSFaultToleranceConfiguration.lua"))()

  local acs = self.context.IAccessControlService

  local notInHostAdd = acs.config.hostName..":"
                   ..tostring(acs.config.hostPort)

  self.acsReference = "corbaloc::" .. notInHostAdd .. "/" .. Utils.ACCESS_CONTROL_SERVICE_KEY
end

function FaultToleranceFacet:updateStatus(params)
    --Atualiza estado das credenciais
    Log:faulttolerance("[updateStatus] Atualiza estado das credenciais.")

    if not self.ftconfig then
        Log:faulttolerance("[updateStatus] Faceta precisa ser inicializada antes de ser chamada.")
        Log:warn("[updateStatus] n�o foi poss�vel executar 'updatestatus'")
        return false
    end

    if # self.ftconfig.hosts.ACS <= 1 then
        Log:faulttolerance("[updateStatus] Nenhuma replica para atualizar credenciais.")
        return false
    end

    --  O atributo _anyval so retorna em chamadas remotas, em chamadas locais (mesmo processo)
    --  deve-se acessar o parametro diretamente, al�m disso ,
    --  passar uma tabela no any tbm so funciona porque eh local
    -- se fosse uma chamada remota teria q ter uma struct pois senao da problema de marshall
    local input
    if not params._anyval then
        input = params
    else
    --chamada remota
        input = params._anyval
    end

    if input == "all" then
        --sincroniza todas as credenciais a mais das outras replicas
        --com esta e os dados de gerencia
        Log:faulttolerance("[updateStatus] Sincronizando base de credenciais com as replicas exceto em "..self.acsReference)
          local updated = false
          local i = 1
          local count = 0
          repeat
            if self.ftconfig.hosts.ACS[i] ~= self.acsReference then
               local ret, stop, acs = oil.pcall(Utils.fetchService,
                                                Openbus:getORB(),
                                                self.ftconfig.hosts.ACS[i],
                                                Utils.ACCESS_CONTROL_SERVICE_INTERFACE)

                if acs then
                --encontrou outra replica
                    local acsFacet = self.context.IAccessControlService
                    --********* CREDENCIAL - inicio *****************
                    local repEntries = acs:getAllEntryCredential()
                    if # repEntries > 0 then
                        local localEntries = acsFacet.entries
                        if localEntries == nil then
                           localEntries = {}
                        end
                        --SINCRONIZA
                        for _,repEntry in pairs(repEntries) do
                            local add = true
                            if type(repEntry) ~= "number" then
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
                                   addEntry.observers[observerId] = true
                                 end
                                 addEntry.observedBy = {}
                                 for _, observerId in pairs(repEntry.observedBy) do
                                   addEntry.observedBy[observerId] = true
                                 end
                                 acsFacet:addEntryCredential(addEntry)
                                 updated = true
                                 count = count + 1
                              end
                            end
                        end
                    end
                    --********* CREDENCIAL - fim *****************
                end
            end
            i = i + 1
          until i > # self.ftconfig.hosts.ACS
          if updated then
            Log:faulttolerance("[updateOffersStatus] Quantidade de credenciais inseridas:[".. tostring(count) .."].")
          end
          return updated
    else
        --procura por uma credencial espec�fica
        local credential = input
        Log:faulttolerance("[updateStatus] Buscando uma credencial nas replicas exceto em "..self.acsReference)

        local entryCredential = nil
        local i = 1

        repeat
            if self.ftconfig.hosts.ACS[i] ~= self.acsReference then
               local ret, stop, acs = oil.pcall(Utils.fetchService,
                                                Openbus:getORB(),
                                                self.ftconfig.hosts.ACS[i],
                                                Utils.ACCESS_CONTROL_SERVICE_INTERFACE)

                if acs then
                    entryCredential = acs:getEntryCredential(credential)
                end
            end
             i = i + 1
        until entryCredential or i == # self.ftconfig.hosts.ACS

        if entryCredential then
            if not entryCredential.certified then
               return false
            else
               --ADICIONA LOCALMENTE
               local acsFacet = self.context.IAccessControlService
               local entry = acsFacet:addEntryCredential(entryCredential)
            end
        else
           return false
        end
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
  -- pois n�o realiza conex�o.
  Openbus.acs = acs
  Openbus:_setInterceptors()

  -- Administradores dos Servi�os
  mgm.admins = {}
  for _, name in ipairs(config.administrators) do
     mgm.admins[name] = true
  end
  -- ACS e monitor s�o sempre administrador
  mgm.admins.AccessControlService = true
  mgm.admins.ACSMonitor = true

  acs.lease = config.lease

  local timeOut = assert(loadfile(DATA_DIR .."/conf/FTTimeOutConfiguration.lua"))()
  local minLease = timeOut.fetch.MAX_TIMES * ( timeOut.fetch.sleep +
          (timeOut.non_existent.MAX_TIMES * timeOut.non_existent.sleep) )
  if (acs.lease < minLease) then
     Log:warn(">>>> Tempo do lease foi definido menor que o tempo total de falha.")
  end

  -- Inicializa as base de dados de gerenciamento
  mgm.userDB = TableDB(DATA_DIR .. "/acs_user.db")
  mgm.systemDB = TableDB(DATA_DIR .. "/acs_system.db")
  mgm.deploymentDB = TableDB(DATA_DIR .. "/acs_deployment.db")
  -- Carrega a cache
  mgm:loadData()

  -- Inicializa a ger�ncia de certificados
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
    acs.entries[entry.credential.identifier] = entry -- Deveria fazer c�pia?
    if entry.credential.owner == "AccessControlService" then
      acsEntry = entry
    end
  end

  -- Se a credencial do ACS n�o existir (primeira execu��o), criar uma nova
  acsEntry = acsEntry or acs:addEntry("AccessControlService", true)
  -- Credencial n�o expira
  acsEntry.lease.duration = math.huge
  Openbus:setCredential(acsEntry.credential)

  -- Controle de leasing
  acs.checkExpiredLeases = function()
    -- Uma corotina s� percorre a tabela de tempos em tempos
    -- ou precisamos acordar na hora "exata" que cada lease expira
    -- pra verificar?
    for id, entry in pairs(acs.entries) do
      Log:lease("Verificando a credencial de "..id)
      local credential = entry.credential
      local lastUpdate = entry.lease.lastUpdate
      local secondChance = entry.lease.secondChance
      local duration = entry.lease.duration
      local now = os.time()
      if (os.difftime (now, lastUpdate) > duration ) then
        if secondChance then
          Log:warn(credential.owner.. " lease expirado: LOGOUT.")
          acs:logout(credential) -- you may clear existing fields.
        else
          entry.lease.secondChance = true
        end
      end
    end
  end
  acs.leaseProvider = LeaseProvider(acs.checkExpiredLeases, acs.lease)

  local ftFacet = self.context.IFaultTolerantService
  ftFacet:init()

  if # ftFacet.ftconfig.hosts.ACS <= 1 then
     Log:warn("Nenhuma replica para buscar conexoes com Servico de Registro.")
     return
  end
  local acsRecepFacet = self.context.IReceptacles
  local i = 1
  repeat
      if ftFacet.ftconfig.hosts.ACS[i] ~= ftFacet.acsReference then
         local ret, succ, remoteACSIC = oil.pcall(Utils.fetchService,
                                                Openbus:getORB(),
                                                ftFacet.ftconfig.hosts.ACSIC[i],
                                                Utils.COMPONENT_INTERFACE)

          if succ then
          --encontrou outra replica
                Log:faulttolerance("Buscando conexoes na replica ".. ftFacet.ftconfig.hosts.ACSIC[i] ..".")
                -- Recupera faceta IReceptacles da replica remota
                local ok, remoteACSRecepFacet =  oil.pcall(remoteACSIC.getFacetByName, remoteACSIC, "IReceptacles")
                if ok then
                     local orb = Openbus:getORB()
                     remoteACSRecepFacet = orb:narrow(remoteACSRecepFacet,
                           "IDL:scs/core/IReceptacles:1.0")
                     --Recupera conexoes do Servico de Registro
                     local status, conns = oil.pcall(remoteACSRecepFacet.getConnections,
                                                     remoteACSRecepFacet,
                                                     "RegistryServiceReceptacle")
                     if not status then
                       Log:warn("Nao foi possivel obter o Servi�o [IRegistryService_v" .. Utils.OB_VERSION .. "]: " .. conns[1])
                       return
                     elseif conns[1] then
                        local recepIC = conns[1].objref
                        recepIC = orb:narrow(recepIC, "IDL:scs/core/IComponent:1.0")
                        --Connecta localmente direto na AdaptiveReceptacle
                        --para nao ativar atualizacao nas replicas
                        local cid = AdaptiveReceptacle.AdaptiveReceptacleFacet.connect(acsRecepFacet, "RegistryServiceReceptacle", recepIC)
                        Log:faulttolerance("Conexao do Servico de Registro recuperado e conectado com id: " .. cid)
                     end
                end
          end
      end
      i = i + 1
  until i > # ftFacet.ftconfig.hosts.ACSIC

end

---
--Finaliza o Servi�o.
--
--@see scs.core.IComponent#shutdown
---
function shutdown(self)
  Log:access_control("Pedido de shutdown para Servi�o de controle de acesso")
  local acs = self.context.IAccessControlService
  acs.leaseProvider:stopCheck()
  local orb = Openbus:getORB()
  orb:deactivate(acs)
  orb:deactivate(self.context.IManagement)
  orb:deactivate(self.context.ILeaseProvider)
  orb:deactivate(self.context.IFaultTolerantService)
  orb:deactivate(self.context.IComponent)
  orb:shutdown()
  Log:faulttolerance("Servico de Controle de Acesso matou seu processo.")
end
