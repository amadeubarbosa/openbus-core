require "OOP"

SessionService = Object:new{
    sessions = {},

    createSession = function(self, credential)
        local session = {}
        self.sessions[credential] = session
        return session
    end,

    removeSession = function(self, credential)
        self.sessions[credential] = nil
    end,

    getSession = function(self, credential)
        return self.sessions[credential]
    end,
};
