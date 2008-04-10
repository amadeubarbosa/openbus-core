-- $Id$

local oil = require "oil"
local luuid = require "uuid"

local Session = require "openbus.services.session.Session"

local Log = require "openbus.common.Log"

local oop = require "loop.base"

---
--Faceta que disponibiliza a funcionalidade básica do serviço de sessão.
---
module("openbus.services.session.SessionService", oop.class)

---
--Cria a facete de um Serviço de Sessão.
--
--@param accessControlService O Serviço de Controle de Acesso.
--@param serverInterceptor O interceptador de servidor que será instalado para
--este serviço.
--
--@return A faceta do Serviço de Sessão.
---
function __init(self, accessControlService, serverInterceptor)
  return oop.rawnew(self, {
    sessions = {},
    serverInterceptor = serverInterceptor,
    accessControlService = accessControlService,
  })
end

---
--Cria uma sessão associada a uma credencial. A credencial em questão é
--recuperada da requisição pelo interceptador do serviço, e repassada através
--do objeto PICurrent.
--
--@param member O membro que está solicitando a criação da sessão e que estará
--inserido na sessão automaticamente.
--
--@return true, a sessão e o identificador de membro da sessão em caso de
--sucesso, ou false, caso contrário.
---
function createSession(self, member)
  local credential = self.serverInterceptor:getCredential()
  if self.sessions[credential.identifier] then
    Log:err("Tentativa de criar sessão já existente")
    return false
  end
  Log:service("Vou criar sessão")
  local session = Session(self:generateIdentifier(), credential)
  session = oil.newservant(session, "IDL:openbusidl/ss/ISession:1.0")
  self.sessions[credential.identifier] = session
  Log:service("Sessão criada!")

  -- A credencial deve ser observada!
  if not self.observerId then
    local observer = {
      sessionService = self,
      credentialWasDeleted =
        function(self, credential)
          self.sessionService:credentialWasDeleted(credential)
        end
    }
    self.observer = oil.newservant(observer,
                                  "IDL:openbusidl/acs/ICredentialObserver:1.0",
                                  "SessionServiceCredentialObserver")
    self.observerId =
      self.accessControlService:addObserver(self.observer,
                                            {credential.identifier})
  else
    self.accessControlService:addCredentialToObserver(self.observerId,
                                                     credential.identifier)
  end

  -- Adiciona o membro à sessão
  local memberID = session:addMember(member)
  return true, session, memberID
end

---
--Notificação de deleção de credencial (logout).
--
--@param credential A credencial removida.
---
function credentialWasDeleted(self, credential)

  -- Remove a sessão
  local session = self.sessions[credential.identifier]
  if session then
  Log:service("Removendo sessão de credencial deletada ("..
              credential.identifier..")")
    session:_deactivate()
    self.sessions[credential.identifier] = nil
  end
end

---
--Gera um identificador de sessão.
--
--@return Um identificador de sessão.
---
function generateIdentifier()
  return luuid.new("time")
end

---
--Obtém a sessão associada a uma credencial. A credencial em questão é
--recuperada da requisição pelo interceptador do serviço, e repassada através
--do objeto PICurrent.
--
--@return A sessão, ou nil, caso não exista sessão para a credencial do membro.
---
function getSession(self)
  local credential = self.serverInterceptor:getCredential()
  local session = self.sessions[credential.identifier]
  if not session then
   Log:warn("Não há sessão para "..credential.identifier)
    return nil
  end
  return session
end

---
--Procedimento após a reconexão do serviço.
---
function wasReconnected(self)

  -- registra novamente o observador de credenciais
  self.observerId = self.accessControlService:addObserver(self.observer, {})
  Log:service("Observador recadastrado")

  -- Mantém apenas as sessões com credenciais válidas
  local invalidCredentials = {}
  for credentialId, session in pairs(self.sessions) do
    if not self.accessService.addCredentialToObserver(self.observerId,
                                                      credentialId) then
      Log:service("Sessão para "..credentialId.." será removida")
      table.insert(invalidCredentials, credentialId)
    else
      Log:service("Sessão para "..credentialId.." será mantida")
    end
  end
  for _, credentialId in ipairs(invalidCredentials) do
    self.sessions[credentialId] = nil
  end
end

---
--Finaliza o serviço.
---
function shutdown(self)
  if self.observerId then
    self.accessControlService:removeObserver(self.observerId)
    self.observer:_deactivate()
    self.observer = nil
    self.observerId = nil
  end
end
