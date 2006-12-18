require "OOP"

SessionService = Object:new{
    sessions = {},

    createSession = function(self, credential)
        local session = {}
        self.sessions[credential] = session
    end,

    removeSession = function(self, credential)
        self.session[crential] = nil
    end,

    getSession = function(self, credential)
        return self.sessions[credential]
    end,
};
