-- $Id$
local print = print

local oil = require "oil"
local orb = oil.orb

local oop = require "loop.base"
local log = require "openbus.common.Log"
local FTLeaseRenewer = require "openbus.common.FTLeaseRenewer"

local AccessControlServiceWrapper = require "core.services.accesscontrol.AccessControlServiceWrapper"

---
--Gerenciador de conexões de membros ao barramento.
---
module("openbus.common.ConnectionManager", oop.class)

---
--Cria o gerenciador de conexões.
--
--@param accessControlServerHost A localização do serviço de controle de acesso.
--@param credentialManager O objeto onde a credencial do membro fica armazenada.
--
--@return O gerenciador de conexões.
---
function __init(self, accessControlServerHost, credentialManager)
  local obj = {
    accessControlServerHost = accessControlServerHost,
    credentialManager = credentialManager
  }
  return oop.rawnew(self, obj)
end

---
--Obtém referência para o serviço de controle de acesso.
--TODO: Foi mantido para evitar propagação de erros no Openbus, porém deve existir
--	somente o getAccessControlServiceWrapper
--
--@return O Serviço de Controle de Acesso, ou nil, caso não esteja definido.
--=
function getAccessControlService(self)
  return self:getAccessControlServiceWrapper():getAccessControlService()
end


---
--Obtém o Wrapper para o serviço de controle de acesso.
--
--@return O Wrapper do Serviço de Controle de Acesso, ou nil, caso não esteja definido.
--=
function getAccessControlServiceWrapper(self)
  if self.accessControlServiceWrapper == nil then
	self.accessControlServiceWrapper = AccessControlServiceWrapper
  end
  return self.accessControlServiceWrapper
end


---
--Finaliza o procedimento de conexão, após um login bem sucedido salva a
--credencial e inicia o processo de renovação de lease.
--
--@param credential A credencial do membro.
--@param lease O período de tempo entre as renovações do lease.
--@param leaseExpiredCallback Função que será executada quando o lease expirar.
---
function completeConnection(self, credential, lease, leaseExpiredCallback)

  self.credentialManager:setValue(credential)
  self.leaseRenewer = FTLeaseRenewer(lease, credential, self:getAccessControlServiceWrapper(), leaseExpiredCallback)
  self.leaseRenewer:startRenew()
end

---
--Desconecta um membro do barramento.
---
function disconnect(self)
  if self.leaseRenewer then
    self.leaseRenewer:stopRenew()
    self.leaseRenewer = nil
  end
  if self.accessControlService and self.credentialManager:hasValue() then
    self.accessControlService:logout(self.credentialManager:getValue())
    self.credentialManager:invalidate()
  end
end
