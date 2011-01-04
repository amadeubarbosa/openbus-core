--
-- Configuração para o interceptador de requisições ao serviço de registro
--
local Utils = require "openbus.util.Utils"
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local config =
  assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informação sobre as operacões a serem liberadas
config.interfaces = {
 {
    interface = Utils.COMPONENT_INTERFACE,
    excluded_ops = {"getFacet", "getFacetByName"}
  },
 {
    interface = Utils.RECEPTACLES_INTERFACE,
    excluded_ops = {"getConnections", "connect", "disconnect"}
  },
}

return config
