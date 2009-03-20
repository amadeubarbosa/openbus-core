--
-- Configura��o para o interceptador de requisi��es ao servi�o de sess�o
--
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local config =
  assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informa��o sobre a(s) interface(s) a ser(em) checada(s)
config.interfaces = {
  { interface = "IDL:openbusidl/ss/ISessionService:1.0",
    excluded_ops = { }
  },
  { interface = "IDL:openbusidl/ss/ISession:1.0",
    excluded_ops = { }
  }
}
return config
