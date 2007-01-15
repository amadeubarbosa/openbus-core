require "oil"

require "uuid"

require "OOP"

SessionService = createClass()

SessionService.invalidSession = { identifier = "", }
SessionService.sessions = {}

function SessionService:createSession(credential)
    if not self.accessControlService:isValid(credential) then
        return self.invalidSession
    end
    if self.sessions[credential.identifier] then
        return self.sessions[credential.identifier]
    end
    local session = Session:new{identifier = self:generateIdentifier()}
    session = oil.newobject(session, "IDL:OpenBus/SS/Session:1.0")
    self.sessions[credential.identifier] = session
    return session
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
    if not self.sessions[credential.identifier] then
        return self.invalidSession
    end
    return self.sessions[credential.identifier]
end
