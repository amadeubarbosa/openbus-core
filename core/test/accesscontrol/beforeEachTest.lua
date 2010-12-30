local Check = require "latt.Check"

return function(self)
      _, self.credential =
          self.accessControlService:loginByPassword(self.login.user, self.login.password)
      self.credentialManager:setValue(self.credential)
    end
