--
-- Testes unitários do arquivo Utils.lua
--
-- $Id: testUtils.lua $
--
local oil = require "oil"
local orb = oil.orb

local CredentialManager = require "openbus.util.CredentialManager"
local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local Utils = require "openbus.util.Utils"

local OPENBUS_HOME = os.getenv("OPENBUS_HOME")

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
      if IDLPATH_DIR == nil then
        io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
        os.exit(1)
      end
      orb:loadidlfile(IDLPATH_DIR.."/v1_05/access_control_service.idl")
      orb:loadidlfile(IDLPATH_DIR.."/v1_04/access_control_service.idl")
      orb:loadidlfile(IDLPATH_DIR.."/v1_05/fault_tolerance.idl") 
    end,
    testFetchACS = function(self)
      -- Obtém a configuração do serviço
      assert(loadfile(OPENBUS_HOME.."/data/conf/AccessControlServerConfiguration.lua"))()
      local acs, lp, ic = Utils.fetchAccessControlService(orb, AccessControlServerConfiguration.hostName, 
                                                           AccessControlServerConfiguration.hostPort)
      local user = "tester"
      local password = "tester"
      local DATA_DIR = os.getenv("OPENBUS_DATADIR")
      local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
      local credentialManager = CredentialManager()
      orb:setclientinterceptor(ClientInterceptor(config, credentialManager))
      local success, credential = acs:loginByPassword(user, password)
      credentialManager:setValue(credential)
      acs:logout(credential)
    end,
 }
}
