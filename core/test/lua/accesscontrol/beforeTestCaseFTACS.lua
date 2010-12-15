local print = print
local tostring = tostring

require "oil"
local orb = oil.orb

local Utils = require "openbus.util.Utils"
local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

function loadidls(self)
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end
  local idlfile = IDLPATH_DIR.."/"..Utils.OB_VERSION..
      "/access_control_service.idl"
  orb:loadidlfile(idlfile)
  idlfile = IDLPATH_DIR.."/"..Utils.OB_PREV.."/access_control_service.idl"
  orb:loadidlfile(idlfile)
end

return function (self)
      local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
      loadidls()

      local ltime = tostring(socket.gettime())

      ltime = string.gsub(ltime, "%.", "")

      -- Login do administrador
      self.login = {}
      self.login.user = "tester" -- .. ltime
      self.login.password = "tester" -- .. ltime

      self.acsCertFile  = "AccessControlService.crt"

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")

      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))

      local loadConfig, err = loadfile(DATA_DIR .."/conf/ACSFaultToleranceConfiguration.lua")
      if not loadConfig then
         Log:error("O arquivo 'ACSFaultToleranceConfiguration' não pode ser " ..
            "carregado ou não existe.",err)
         os.exit(1)
      end
      setfenv(loadConfig,self)
      loadConfig()
end
