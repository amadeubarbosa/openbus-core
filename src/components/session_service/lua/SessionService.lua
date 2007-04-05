--
-- Faceta que disponibiliza a funcionalidade b�sica do servi�o de sess�o
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

-- Cria uma sess�o associada a uma credencial.
-- A credencial em quest�o � recuperada da requisi��o pelo interceptador 
-- do servi�o, e repassada atrav�s do objeto PICurrent
function SessionService:createSession()
  local credential = self.picurrent:getValue()
  verbose:service("Criar sess�o para "..credential.identifier)
  if self.sessions[credential.identifier] then
    verbose:err("Tentativa de criar sess�o j� existente")
    return false
  end
  local session = Session{identifier = self:generateIdentifier()}
  session = oil.newobject(session, "IDL:OpenBus/SS/ISession:1.0")
  self.sessions[credential.identifier] = session
  verbose:service("Sess�o criada!")

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

-- Notifica��o de dele��o de credencial (logout)
function SessionService:credentialWasDeleted(credential)
  if self.sessions[credential.identifier] then
    verbose:service("Removendo sess�o de "..credential.identifier)
    self.sessions[credential.identifier] = nil
    verbose:service("Removendo credencial do observador")
    self.accessControlService:removeCredentialFromObserver(self.observerId,
                                                        credential.identifier)
  end
end

function SessionService:generateIdentifier()
  return uuid.new("time")
end

-- Obt�m a sess�o associada a uma credencial.
-- A credencial em quest�o � recuperada da requisi��o pelo interceptador 
-- do servi�o, e repassada atrav�s do objeto PICurrent
function SessionService:getSession()
  local credential = self.picurrent:getValue()
  verbose:service("Obter sess�o de "..credential.identifier)
  return self.sessions[credential.identifier]
end
