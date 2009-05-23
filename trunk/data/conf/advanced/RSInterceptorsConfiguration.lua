--
-- Configuração para o interceptador de requisições ao serviço de registro
--
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local config = 
  assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informação sobre a(s) interface(s) a ser(em) checada(s)
config.interfaces = {
  { interface = "IDL:openbusidl/rs/IRegistryService:1.0",
    excluded_ops = { }
  }
}
return config
