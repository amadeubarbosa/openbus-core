local Check = require "latt.Check"

return function(self)

      if (self.credentialManager:hasValue()) then
        self.accessControlService:logout(self.credential)
        self.credentialManager:invalidate()
      end
    end
