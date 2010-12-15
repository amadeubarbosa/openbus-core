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
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_VERSION.."/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_VERSION.."/registry_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_PREV.."/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_PREV.."/registry_service.idl")
  orb:loadidl("interface IHello_vft { };")
end

return function (self)
      local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      loadidls()

      -- Obtém a configuração do serviço
      assert(loadfile(OPENBUS_HOME.."/data/conf/AccessControlServerConfiguration.lua"))()
      self.acsHostName = AccessControlServerConfiguration.hostName
      self.acsHostPort = AccessControlServerConfiguration.hostPort

      local ltime = tostring(socket.gettime())
      ltime = string.gsub(ltime, "%.", "")

      -- Login do administrador
      self.login = {}
      self.login.user = "tester" -- .. ltime
      self.login.password = "tester" -- .. ltime

      self.systemId     = "TesteBarramento".. ltime
      self.deploymentId = self.systemId
      self.testKeyFile  = self.systemId .. ".key"
      self.acsCertFile  = DATA_DIR.."/certificates/AccessControlService.crt"
      local testACSCertFile = assert(io.open(self.acsCertFile,"r"))
      testACSCertFile:close()

      os.execute(OPENBUS_HOME.."/specs/shell/openssl-generate.ksh -n " .. self.systemId .. " -c "..OPENBUS_HOME.."/openssl/openssl.cnf <TesteBarramentoCertificado_input.txt  2> genkey-err.txt >genkeyT.txt ")

      os.execute(OPENBUS_HOME.."/core/bin/run_management.sh --acs-host=" .. self.acsHostName ..
                                                                        " --acs-port=" .. self.acsHostPort  ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --add-system="..self.systemId ..
                                                                        " --description=Teste_do_OpenBus" ..
                                                                        " 2>> management-err.txt >>management.txt ")

      os.execute(OPENBUS_HOME.."/core/bin/run_management.sh --acs-host=" .. self.acsHostName ..
                                                                        " --acs-port=" .. self.acsHostPort..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --add-deployment="..self.deploymentId ..
                                                                        " --system="..self.systemId ..
                                                                        " --description=Teste_do_Barramento" ..
                                                                        " --certificate="..self.systemId..".crt"..
                                                                        " 2>> management-err.txt >>management.txt ")

      os.execute(OPENBUS_HOME.."/core/bin/run_management.sh --acs-host=" .. self.acsHostName ..
                                                                        " --acs-port=" .. self.acsHostPort ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --set-authorization="..self.systemId ..
                                                                        " --grant='IDL:*:*'".. " --no-strict"..
                                                                        " 2>> management-err.txt >>management.txt ")

      -- instala o interceptador de cliente


      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))

      local loadConfig, err = loadfile(DATA_DIR .."/conf/RSFaultToleranceConfiguration.lua")
      if not loadConfig then
         Log:error("O arquivo 'RSFaultToleranceConfiguration' não pode ser " ..
            "carregado ou não existe.",err)
         os.exit(1)
      end
      setfenv(loadConfig,self)
      loadConfig()
end
