--
-- Configura��o para o interceptador de requisi��es ao servi�o de registro
--
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local config = 
  assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informa��o sobre as operac�es a serem liberadas
config.interfaces = {
 {
    interface = "IDL:tecgraf/openbus/fault_tolerance/v1_05/IFaultTolerantService:1.0",
    excluded_ops = {"isAlive"}
  },
}

return config
