--
-- Faceta que disponibiliza a funcionalidade básica do serviço de sessão
--
-- $Id$
--
require "oil"
require "uuid"
require "Session"

local oop = require "loop.base"
local verbose = require "Verbose"

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
  verbose:service("Criar sessão para "..credential.identifier)
  if self.sessions[credential.identifier] then
    verbose:err("Tentativa de criar sessão já existente")
    return false
  end
  local session = Session{identifier = self:generateIdentifier()}
  session = oil.newobject(session, "IDL:OpenBus/SS/ISession:1.0")
  self.sessions[credential.identifier] = session
  verbose:service("Sessão criada!")

  -- A credencial deve ser observada!
  if not self.observerId then
    verbose:service("Criando observador de credenciais")
    self.observer = oil.newobject(self, 
                                  "IDL:OpenBus/ACS/ICredentialObserver:1.0",
                                  "SessionServiceCredentialObserver")
    verbose:service("Adicionando observador de credenciais ao controle acesso")
    self.observerId = 
      self.accessControlService:addObserver(self.observer, 
                                            {credential.identifier})
    verbose:service("Observador de credenciais adicionado")
  else
    verbose:service("Inserindo credencial ao observador")
    self.accessControlSevice:addCredentialToObserver(self.observerId,
                                                     credential.identifier)
  end
  return true, session
end

-- Notificação de deleção de credencial (logout)
function SessionService:credentialWasDeleted(credential)
  if self.sessions[credential.identifier] then
    verbose:service("Removendo sessão de "..credential.identifier)
    self.sessions[credential.identifier] = nil
    verbose:service("Removendo credencial do observador")
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
  verbose:service("Obter sessão de "..credential.identifier)
  return self.sessions[credential.identifier]
end
