local print = print
local tostring = tostring

require "oil"
local orb = oil.orb

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

return function (self)
      local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
      loadidls()

      local ltime = tostring(socket.gettime())

      ltime = string.gsub(ltime, "%.", "")

      -- Login do administrador
      self.login = {}
      self.login.user = "tester-" .. ltime
      self.login.password = "tester-" .. ltime

      self.acsCertFile  = "AccessControlService.crt"

      local acsComp = orb:newproxy("corbaloc::localhost:2089/openbus_v1_05",
                                   "IDL:scs/core/IComponent:1.0")
      local facet = acsComp:getFacet("IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
      self.accessControlService = orb:narrow(facet, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")

      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
end
