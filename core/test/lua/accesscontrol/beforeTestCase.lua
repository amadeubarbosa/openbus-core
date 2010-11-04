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

--
-- Esta funcao cadastra 'TesteBarramento<id_unico>' e requer que a suite de teste
-- principal use a funcao afterTestCase
--

return function (self)
      local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
      loadidls()

      -- Obtém a configuração do serviço
      assert(loadfile(OPENBUS_HOME.."/data/conf/AccessControlServerConfiguration.lua"))()

      local ltime = tostring(socket.gettime())
      ltime = string.gsub(ltime, "%.", "")

      -- Login do administrador
      self.login = {}
      self.login.user = "tester-" .. ltime
      self.login.password = "tester-" .. ltime

      self.systemId     = "TesteBarramento".. ltime
      self.deploymentId = self.systemId
      self.testKeyFile  = self.systemId .. ".key"
      self.acsCertFile  = "AccessControlService.crt"
      local testACSCertFile = assert(io.open(self.acsCertFile,"r"))
      testACSCertFile:close()

      os.execute(OPENBUS_HOME.."/specs/shell/openssl-generate.ksh -n " .. self.systemId .. " -c "..OPENBUS_HOME.."/openssl/openssl.cnf <TesteBarramentoCertificado_input.txt  2> genkey-err.txt >genkeyT.txt ")

      os.execute(OPENBUS_HOME.."/core/bin/run_management.sh --acs-host=" .. AccessControlServerConfiguration.hostName ..
                                                                        " --acs-port=" .. AccessControlServerConfiguration.hostPort  ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --add-system="..self.systemId ..
                                                                        " --description=Teste_do_OpenBus" ..
                                                                        " 2>> management-err.txt >>management.txt ")

      os.execute(OPENBUS_HOME.."/core/bin/run_management.sh --acs-host=" .. AccessControlServerConfiguration.hostName ..
                                                                        " --acs-port=" .. AccessControlServerConfiguration.hostPort  ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --add-deployment="..self.deploymentId ..
                                                                        " --system="..self.systemId ..
                                                                        " --description=Teste_do_Barramento" ..
                                                                        " --certificate="..self.systemId..".crt"..
                                                                        " 2>> management-err.txt >>management.txt ")

      os.execute(OPENBUS_HOME.."/core/bin/run_management.sh --acs-host=" .. AccessControlServerConfiguration.hostName ..
                                                                        " --acs-port=" .. AccessControlServerConfiguration.hostPort  ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --set-authorization="..self.systemId ..
                                                                        " --grant='IDL:*:*'".. " --no-strict"..
                                                                        " 2>> management-err.txt >>management.txt ")


      local acsComp = orb:newproxy("corbaloc::".. AccessControlServerConfiguration.hostName ..":".. AccessControlServerConfiguration.hostPort .."/openbus_v1_05",
          "synchronous", "IDL:scs/core/IComponent:1.0")
      local facet = acsComp:getFacet("IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
      self.accessControlService = orb:narrow(facet, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")

      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
end
