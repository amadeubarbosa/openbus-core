local print = print
local tostring = tostring

require "oil"
local orb = oil.orb

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"


--
-- Esta funcao cadastra 'TesteBarramento<id_unico>' e requer que a suite de teste
-- principal use a funcao afterTestCase
--

return function (self)
      local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
      loadidls()

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

      os.execute(OPENBUS_HOME.."/specs/shell/openssl-generate.ksh -n " .. self.systemId .. " -c "..OPENBUS_HOME.."/openssl/openssl.cnf <TesteBarramentoCertificado_input.txt  2> genkey-err.txt >genkeyT.txt ")

      os.execute(OPENBUS_HOME.."/core/bin/run_management.sh --acs-host=localhost" ..
                                                                        " --acs-port=2089" ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --add-system="..self.systemId ..
                                                                        " --description=Teste_do_OpenBus" ..
                                                                        " 2>> management-err.txt >>management.txt ")

      os.execute(OPENBUS_HOME.."/core/bin/run_management.sh --acs-host=localhost" ..
                                                                        " --acs-port=2089" ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --add-deployment="..self.deploymentId ..
                                                                        " --system="..self.systemId ..
                                                                        " --description=Teste_do_Barramento" ..
                                                                        " --certificate="..self.systemId..".crt"..
                                                                        " 2>> management-err.txt >>management.txt ")

      os.execute(OPENBUS_HOME.."/core/bin/run_management.sh --acs-host=localhost" ..
                                                                        " --acs-port=2089" ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --set-authorization="..self.systemId ..
                                                                        " --grant='IDL:*:*'".. " --no-strict"..
                                                                        " 2>> management-err.txt >>management.txt ")


      local acsComp = orb:newproxy("corbaloc::amores.tecgraf.puc-rio.br:2089/openbus_v1_05",
          "IDL:scs/core/IComponent:1.0")
      local facet = acsComp:getFacet("IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
      self.accessControlService = orb:narrow(facet, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")

      -- instala o interceptador de cliente
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")

      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      self.credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, self.credentialManager))
end
