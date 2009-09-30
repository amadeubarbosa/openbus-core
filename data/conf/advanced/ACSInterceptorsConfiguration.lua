--
-- Configuração para o interceptador de requisições ao serviço de acesso
--
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local config = 
  assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informação sobre as operacões a serem liberadas
config.interfaces = {
  {
    interface = "IDL:openbusidl/acs/IAccessControlService:1.0",
    excluded_ops = {"loginByPassword", "loginByCertificate", "getChallenge"}
  },
  {
    interface = "IDL:openbusidl/ft/IFaultTolerantService:1.0",
    excluded_ops = {"isAlive"}
  },
}

return config
