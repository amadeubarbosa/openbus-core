require "oil"
local orb = oil.orb

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"

--
-- Esta funcao descadastra 'TesteBarramento<id_unico>'
--
return function (self)
      local OPENBUS_HOME = os.getenv("OPENBUS_HOME")
      -- Obtém a configuração do serviço
      assert(loadfile(OPENBUS_HOME.."/data/conf/AccessControlServerConfiguration.lua"))()
      os.execute(OPENBUS_HOME.."/bin/run_management.sh --acs-host=" .. AccessControlServerConfiguration.hostName ..
                                                                        " --acs-port=" .. AccessControlServerConfiguration.hostPort ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --del-deployment="..self.deploymentId..
                                                                        " 2>> management-err.txt >>management.txt ")

      os.execute(OPENBUS_HOME.."/bin/run_management.sh --acs-host=" .. AccessControlServerConfiguration.hostName ..
                                                                        " --acs-port=" .. AccessControlServerConfiguration.hostPort ..
                                                                        " --login=tester" ..
                                                                        " --password=tester" ..
                                                                        " --del-system="..self.systemId..
                                                                        " 2>> management-err.txt >>management.txt ")
      --Apaga as chaves e certificados gerados
      os.execute("rm -r " .. self.systemId .. ".key")
      os.execute("rm -r " .. self.systemId .. ".crt")
end
