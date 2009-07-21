--
-- Configura��o para o interceptador de requisi��es ao servi�o de sess�o
--
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local config =
  assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informa��o sobre operac�es a serem liberadas
config.interfaces = {
  {
    interface = "IDL:openbusidl/acs/ICredentialObserver:1.0",
    excluded_ops = {"credentialWasDeleted"},
  },
}

return config
