require "OOP"

SessionService = Object:new{
    sessions = {},

    createSession = function(self, credential)
        if self.accessControlService:isValid(credential) then
            local session = {}
            self.sessions[credential] = session
            return session
        end
        return nil
    end,

    removeSession = function(self, credential)
        self.sessions[credential] = nil
    end,

    getSession = function(self, credential)
        return self.sessions[credential]
    end,
}
