--
-- Faceta que disponibiliza a funcionalidade básica do serviço de sessão
--
-- $Id$
--
require "oil"
require "uuid"

local verbose = require "openbus.common.Log"

local Session = require "openbus.services.session.Session"

local oop = require "loop.base"

SessionService = oop.class{
  sessions = {},
}

function SessionService:__init(accessControlService, picurrent)
  self.picurrent = picurrent
  self.accessControlService = accessControlService
  return self
end

-- Cria uma sessão associada a uma credencial.
-- A credencial em questão é recuperada da requisição pelo interceptador 
-- do serviço, e repassada através do objeto PICurrent
function SessionService:createSession()
  local credential = self.picurrent:getValue()
  if self.sessions[credential.identifier] then
    verbose:err("Tentativa de criar sessão já existente")
    return false
  end
  verbose:service("Vou criar sessão")
  local session = Session(self:generateIdentifier())
  session = oil.newobject(session, "IDL:OpenBus/SS/ISession:1.0")
  self.sessions[credential.identifier] = session
  verbose:service("Sessão criada!")

  -- A credencial deve ser observada!
  if not self.observerId then
    local observer = {
      sessionService = self,
      credentialWasDeleted = 
        function(self, credential)
          self.sessionService:credentialWasDeleted(credential)
        end
    }
    self.observer = oil.newobject(observer, 
                                  "IDL:OpenBus/ACS/ICredentialObserver:1.0",
                                  "SessionServiceCredentialObserver")
    self.observerId = 
      self.accessControlService:addObserver(self.observer, 
                                            {credential.identifier})
  else
    self.accessControlService:addCredentialToObserver(self.observerId,
                                                     credential.identifier)
  end
  return true, session
end

-- Notificação de deleção de credencial (logout)
function SessionService:credentialWasDeleted(credential)
  if self.sessions[credential.identifier] then
    self.sessions[credential.identifier] = nil
    self.accessControlService:removeCredentialFromObserver(self.observerId,
                                                        credential.identifier)
  end
end

function SessionService:generateIdentifier()
  return uuid.new("time")
end

-- Obtém a sessão associada a uma credencial.
-- A credencial em questão é recuperada da requisição pelo interceptador 
-- do serviço, e repassada através do objeto PICurrent
function SessionService:getSession()
  local credential = self.picurrent:getValue()
  local session = self.sessions[credential.identifier]
  if not session then
   verbose:warn("Não há sessão para "..credential.identifier)
  end
  return session
end
