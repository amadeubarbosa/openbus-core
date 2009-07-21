--
-- Configuração para o interceptador de requisições ao serviço de registro
--
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local config = 
  assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informação sobre as operacões a serem liberadas
config.interfaces = {
  {
    interface = "IDL:openbusidl/acs/ICredentialObserver:1.0",
    excluded_ops = {"credentialWasDeleted"},
  },
}

return config
