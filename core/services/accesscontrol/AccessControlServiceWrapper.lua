-- $Id: AccessControlServiceWrapper.lua 
local os = os
local print = print
local loadfile = loadfile
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber

local Log = require "openbus.common.Log"
local oop = require "loop.simple"
local ServiceWrapper = require "core.services.faulttolerance.ServiceWrapper"

local oil = require "oil"
local orb = oil.orb


local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  Log:error("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end

orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/AccessControlServerConfiguration.lua"))()

-- Define os níveis de verbose para o OpenBus e para o OiL.
if AccessControlServerConfiguration.logLevel then
  Log:level(AccessControlServerConfiguration.logLevel)
end
if AccessControlServerConfiguration.oilVerboseLevel then
  oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
end

local Viewer = require "loop.debug.Viewer"
local Properties = require "openbus.common.Properties"


---
--Componente responsável pelo Wrapper do Serviço de Controle de Acesso
---

local hosts = {}
local prop = Properties(DATA_DIR.."/conf/FaultToleranceConfiguration.properties")

for key,value in pairs(prop.values) do
   if key:match("^acsHostAdd") then
        local i = tonumber(key:match("[0-9]+"))
	hosts[i] = value
   end
end

local obj = ServiceWrapper:__init("ACS", "IDL:openbusidl/acs/IAccessControlService:1.0", "access_control_service.idl", hosts)


package.loaded["core.services.accesscontrol.AccessControlServiceWrapper"] = obj

function obj:credentialLookupInReplicas(credential, notInHostAdd)
  Log:faulttolerance("[credentialLookupInReplicas] Buscando credencial nas replicas exceto em "..notInHostAdd)
  local entryCredential = nil
  local i = 0
  repeat
     local acs = self:getNextService(notInHostAdd)
     if acs ~= nil then
	     entryCredential = acs:getEntryCredential(credential)
     end
     i = i + 1 	
  until entryCredential ~= nil or i == # self.hostsAdd

  return entryCredential
end


function obj:getAccessControlService()
   self:checkService()
   return self.service
end


---
--Realiza um Login de uma entidade através de usuário e senha.
--
--@param name O nome da entidade.
--@param password A senha da entidade.
--
--@return true, a credencial da entidade e o lease caso o Login seja realizado
--com sucesso, ou false e uma credencial e uma lease inválidos, caso contrário.
---
function obj:loginByPassword(name, password)
  return self:getAccessControlService():loginByPassword(name, password)
end

---
--Realiza um Login de um membro através de assinatura digital.
--
--@param name OI nome do membro.
--@param answer A resposta para um desafio previamente obtido.
--
--@return true, a credencial do membro e o lease caso o Login seja realizado
--com sucesso, ou false e uma credencial e uma lease inválidos, caso contrário.
--
--@see getChallenge
---
function obj:loginByCertificate (name, answer)
  return self:getAccessControlService():loginByCertificate(name, answer)
end

---
--Obtém o desafio para um membro.
--
--@param name O nome do membro.
--
--@return O desafio.
--
--@see LoginByCertificate
---
function obj:getChallenge (name)
  return self:getAccessControlService():getChallenge(name)
end

---
--Obtém o certificado de um membro.
--
--@param name O nome do membro.
--
--@return O certificado do membro.
---
function obj:getCertificate (name)
  return self:getAccessControlService():getCertificate(name)
end

---
--Gera um desafio para um membro.
--
--@param name O nome do membro.
--@param certificate O certificado do membro.
--
--@return O desafio.
---
function obj:generateChallenge (name, certificate)
  return self:getAccessControlService():generateChallenge(name, certificate)
end


function obj:renewLease (credential)
  return self:getAccessControlService():renewLease(credential)
end

---
--Faz o Logout de uma credencial.
--
--@param credential A credencial.
--
--@return true caso a credencial estivesse Logada, ou false caso contrário.
---
function obj:logout (credential)
  return self:getAccessControlService():logout(credential)
end

---
--Verifica se uma credencial é válida.
--
--@param credential A credencial.
--
--@return true caso a credencial seja válida, ou false caso contrário.
---
function obj:isValid (credential)
  return self:getAccessControlService():isValid(credential)
end

---
--Obtém o Wrapper do Serviço de Registro.
--
--@return O Wrapper do Serviço de Registro, ou nil caso não tenha sido definido.
---
function obj:getRegistryService()
  return self:getAccessControlService():getRegistryService()
end

---
--Define o componente responsável pelo Wrapper do Serviço de Registro.
--
--@param registryServiceComponent O componente responsável pelo Wrapper do Serviço de
--Registro.
--
--@return true caso o componente seja definido, ou false caso contrário.
---
function obj:setRegistryService (registryServiceComponent)
  return self:getAccessControlService():setRegistryService(registryServiceComponent)
end

---
--Adiciona um observador de credenciais.
--
--@param observer O observador.
--@param credentialIdentifiers As credenciais de interesse do observador.
--
--@return O identificador do observador.
---
function obj:addObserver (observer, credentialIdentifiers)
  return self:getAccessControlService():addObserver(observer, credentialIdentifiers)
end

---
--Adiciona uma credencial à lista de credenciais de um observador.
--
--@param observerIdentifier O identificador do observador.
--@param credentialIdentifier O identificador da credencial.
--
--@return true caso a credencil tenha sido adicionada, ou false caso contrário.
---
function obj:addCredentialToObserver (observerIdentifier, credentialIdentifier)
  return self:getAccessControlService():addCredentialToObserver(observerIdentifier, credentialIdentifier)
end

---
--Remove um observador e retira sua credencial da lista de outros observadores.
--
--@param observerIdentifier O identificador do observador.
--@param credential A credencial.
--
--@return true caso o observador tenha sido removido, ou false caso contrário.
---
function obj:removeObserver (observerIdentifier, credential)
  return self:getAccessControlService():removeObserver(observerIdentifier, credential)
end

---
--Remove uma credencial da lista de credenciais de um observador.
--
--@param observerIdentifier O identificador do observador.
--@param credentialIdentifier O identificador da credencial.
--
--@return true caso a credencial seja removida, ou false caso contrário.
---
function obj:removeCredentialFromObserver (observerIdentifier,credentialIdentifier)
  return self:getAccessControlService():removeCredentialFromObserver(observerIdentifier,credentialIdentifier)
end

---
--Adiciona uma credencial ao banco de dados.
--
--@param name O nome da entidade para a qual a credencial será gerada.
--
--@return A credencial.
---
function obj:addEntry (name, certified)
  return self:getAccessControlService():addEntry(name, certified)
end

---
--Gera um identificador de credenciais.
--
--@return O identificador de credenciais.
---
function obj:generateCredentialIdentifier()
  return self:getAccessControlService():generateCredentialIdentifier()
end

---
--Gera um identificador de observadores de credenciais.
--
--@return O identificador de observadores de credenciais.
---
function obj:generateObserverIdentifier()
  return self:getAccessControlService():generateObserverIdentifier()
end

---
--Remove uma credencial da base de dados e notifica os observadores sobre tal
--evento.
--
--@param entry A credencial.
---
function obj:removeEntry (entry)
  return self:getAccessControlService():removeEntry(entry)
end

---
--Envia aos observadores a notificação de que um credencial não existe mais.
--
--@param credential A credencial.
---
function obj:notifyCredentialWasDeleted (credential)
  return self:getAccessControlService():notifyCredentialWasDeleted(credential)
end







