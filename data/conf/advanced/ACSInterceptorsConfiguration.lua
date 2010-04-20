--
-- Configuração para o interceptador de requisições ao serviço de acesso
--
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local config = 
  assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informação sobre as operacões a serem liberadas
config.interfaces = {
  {
    interface = "IDL:scs/core/IComponent:1.0",
    excluded_ops = {"getFacet"}
  },
  {
    interface = "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0",
    excluded_ops = {"loginByPassword", "loginByCertificate", "getChallenge"}
  },
  {
    interface = "IDL:openbusidl/acs/IAccessControlService:1.0",
    excluded_ops = {"loginByPassword", "loginByCertificate", "getChallenge"}
  },
  {
    interface = "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0",
    excluded_ops = {"isAlive"}
  },
}

return config
