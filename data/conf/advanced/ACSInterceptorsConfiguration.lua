--
-- Configuração para o interceptador de requisições ao serviço de acesso
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
    interface = Utils.ACCESS_CONTROL_SERVICE_INTERFACE,
    excluded_ops = {"loginByPassword", "loginByCertificate", "getChallenge", "isValid"}
  },
  {
    interface = Utils.ACCESS_CONTROL_SERVICE_INTERFACE_V1_04,
    excluded_ops = {"loginByPassword", "loginByCertificate", "getChallenge", "isValid"}
  },
  {
    interface = Utils.FAULT_TOLERANT_SERVICE_INTERFACE,
    excluded_ops = {"isAlive"}
  },
}

-- Acrescenta informação sobre as operacões que ativam atualizacao de estado
config.ft_update_policy = {
  {
    interface = Utils.ACCESS_CONTROL_SERVICE_INTERFACE,
    update_ops = {"loginByPassword", "loginByCertificate"}
  },
  {
    interface = Utils.ACCESS_CONTROL_SERVICE_INTERFACE_V1_04,
    update_ops = {"loginByPassword", "loginByCertificate"}
  },
}



return config
