--
-- Configuração comum aos interceptadores de requisições de serviço
--
local Utils = require "openbus.util.Utils"
return {
  contextID = 1234,
  credential_type_v1_05 =
      "IDL:tecgraf/openbus/core/v"..Utils.OB_VERSION.."/access_control_service/Credential:1.0",
  credential_type =
      "IDL:openbusidl/acs/Credential:1.0"
}
