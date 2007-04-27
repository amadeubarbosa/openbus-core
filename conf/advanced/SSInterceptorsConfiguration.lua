--
-- Configuração para o interceptador de requisições ao serviço de sessão
--
local CONF_DIR = os.getenv("CONF_DIR")
local config = 
  assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informação sobre a(s) interface(s) a ser(em) checada(s)
config.interfaces = {
  { interface = "IDL:openbusidl/ss/ISessionService:1.0",
    excluded_ops = { }
  },
  { interface = "IDL:openbusidl/ss/ISession:1.0",
    excluded_ops = { }
  }
}
return config
