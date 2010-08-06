--
-- Teste do ACS usando a api Openbus criado para testar distribuicao de carga a partir de diferentes configuracoes
-- de tempo (timeout) do FT.
--
local oil = require "oil"

local Check = require "latt.Check"

local Openbus = require "openbus.Openbus"
local Utils = require "openbus.util.Utils"
local Log = require "openbus.util.Log"

local iConfig = {
  contextID = 1234,
  credential_type_v1_05 = "IDL:tecgraf/openbus/core/v"..Utils.OB_VERSION.."/access_control_service/Credential:1.0",
  credential_type = "IDL:openbusidl/acs/Credential:1.0"
}

local host = "d1"
local port = 2089
local props = {}

local ltime = tostring(socket.gettime())
ltime = string.gsub(ltime, "%.", "")

local user = "tester" .. ltime
local password = "tester" .. ltime

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local entityName = "TesteBarramento"
local privateKey = "TesteBarramento.key"
local acsCertificate = DATA_DIR.."/certificates/AccessControlService.crt"

oil.verbose:level(0)
Log:level(0)

Suite = {
  Test1 = {
    beforeTestCase = function(self)
      Openbus:init(host, port, nil, iConfig)
      Openbus:enableFaultTolerance()
    end,

    afterTestCase = function(self)
      Openbus:destroy()
    end,

    afterEachTest = function(self)
      if Openbus:isConnected() then
        Openbus:disconnect()
      end
    end,

    testGetRegistryService = function(self)
      Check.assertFalse(Openbus:getRegistryService())
      Check.assertTrue(Openbus:connectByLoginPassword(user, password))
      Check.assertTrue(Openbus:disconnect())
    end,

    
  },
}


