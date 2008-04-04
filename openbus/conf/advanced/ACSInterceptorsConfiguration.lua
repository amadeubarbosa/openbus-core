--
-- Configuração para o interceptador de requisições ao serviço de acesso
--
local CONF_DIR = os.getenv("CONF_DIR")
local config = 
  assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()

-- Acrescenta informação sobre a(s) interface(s) a ser(em) checada(s)
config.interfaces = {
  { interface = "IDL:openbusidl/acs/IAccessControlService:1.0",
    excluded_ops = { loginByPassword = true, 
                     loginByCertificate = true,
                     getChallenge = true
                    }
  }
}
return config
