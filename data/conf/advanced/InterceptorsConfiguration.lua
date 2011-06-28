--
-- Configuração comum aos interceptadores de requisições de serviço
--
local Utils = require "openbus.util.Utils"
return {
  contextID = 1234,
  credential_type = "IDL:tecgraf/openbus/core/"..Utils.IDL_VERSION..
      "/access_control_service/Credential:1.0",
  credential_type_prev = "IDL:openbusidl/acs/Credential:1.0",
}
