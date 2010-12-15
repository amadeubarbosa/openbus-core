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
    interface = Utils.FAULT_TOLERANT_SERVICE_INTERFACE,
    excluded_ops = {"isAlive"}
  },
}

-- Acrescenta informação sobre as operacões que ativam atualizacao de estado
config.ft_update_policy = {
  {
    interface = Utils.REGISTRY_SERVICE_INTERFACE,
    update_ops = { }
  },
  {
    interface = Utils.REGISTRY_SERVICE_INTERFACE_PREV,
    update_ops = {"register", "update" }
  },
}

return config
