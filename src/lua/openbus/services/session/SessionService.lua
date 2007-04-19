-----------------------------------------------------------------------------
-- Faceta que disponibiliza a funcionalidade básica do serviço de sessão
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "oil"
require "uuid"

local log = require "openbus.common.Log"

local Session = require "openbus.services.session.Session"

local oop = require "loop.base"

SessionService = oop.class{}

function SessionService:__init(accessControlService, picurrent)
  self = oop.rawnew(self, {
    sessions = {},
    picurrent = picurrent,
    accessControlService = accessControlService,
  })
  return self
end

-- Cria uma sessão associada a uma credencial.
-- A credencial em questão é recuperada da requisição pelo interceptador 
-- do serviço, e repassada através do objeto PICurrent
function SessionService:createSession()
  local credential = self.picurrent:getValue()
  if self.sessions[credential.identifier] then
    log:err("Tentativa de criar sessão já existente")
    return false
  end
  log:service("Vou criar sessão")
  local session = Session(self:generateIdentifier())
  session = oil.newobject(session, "IDL:openbusidl/ss/ISession:1.0")
  self.sessions[credential.identifier] = session
  log:service("Sessão criada!")

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
                                  "IDL:openbusidl/acs/ICredentialObserver:1.0",
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

  -- Remove a sessão
  if self.sessions[credential.identifier] then
    self.sessions[credential.identifier] = nil
  end

  -- Remove a credencial do conjunto observado
  self.accessControlService:removeCredentialFromObserver(self.observerId,
                                                        credential.identifier)
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
   log:warn("Não há sessão para "..credential.identifier)
  end
  return session
end
