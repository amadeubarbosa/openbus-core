local print = print
local tostring = tostring

require "oil"
local orb = oil.orb

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

function loadidls(self)
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  local idlfile = IDLPATH_DIR.."/v1_05/access_control_service.idl"
  orb:loadidlfile(idlfile)
  idlfile = IDLPATH_DIR.."/v1_04/access_control_service.idl"
  orb:loadidlfile(idlfile)
end

return function (self)
      local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
      loadidls()

      local ltime = tostring(socket.gettime())

      ltime = string.gsub(ltime, "%.", "")
 
     -- Obtém a configuração do serviço
      assert(loadfile(OPENBUS_HOME.."/data/conf/AccessControlServerConfiguration.lua"))()
      
      -- Login do administrador
      self.login = {}
      self.login.user = "tester-" .. ltime
      self.login.password = "tester-" .. ltime

      self.acsCertFile  = "AccessControlService.crt"

      local acsComp = orb:newproxy("corbaloc::".. AccessControlServerConfiguration.hostName ..":".. AccessControlServerConfiguration.hostPort .."/openbus_v1_05", "synchronous",
                                   "IDL:scs/core/IComponent:1.0")
      local facet = acsComp:getFacet("IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
      self.accessControlService = orb:narrow(facet, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")

      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
end
