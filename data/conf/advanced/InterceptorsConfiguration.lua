--
-- Configura��o comum aos interceptadores de requisi��es de servi�o
--
local Utils = require "openbus.util.Utils"
return {
  contextID = 1234,
  credential_type = "IDL:tecgraf/openbus/core/"..Utils.OB_VERSION..
      "/access_control_service/Credential:1.0",
  credential_type_prev = "IDL:tecgraf/openbus/core/"..Utils.OB_PREV..
      "/access_control_service/Credential:1.0",
}
