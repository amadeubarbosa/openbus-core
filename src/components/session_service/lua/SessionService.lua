require "oil"

require "uuid"

require "Session"

local oop = require "loop.base"

SessionService = oop.class{
  sessions = {},
}

function SessionService:createSession(credential)
    if not self.accessControlService:isValid(credential) then
        return false
    end
    if self.sessions[credential.identifier] then
        return true, self.sessions[credential.identifier]
    end
    local session = Session{identifier = self:generateIdentifier()}
    session = oil.newobject(session, "IDL:OpenBus/SS/ISession:1.0")
    self.sessions[credential.identifier] = session
    return true, session
end

function SessionService:generateIdentifier()
    return uuid.new("time")
end

function SessionService:removeSession(credential)
    if not self.sessions[credential.identifier] then
        return false
    end
    self.sessions[credential.identifier] = nil
    return true
end

function SessionService:getSession(credential)
    return self.sessions[credential.identifier]
end
