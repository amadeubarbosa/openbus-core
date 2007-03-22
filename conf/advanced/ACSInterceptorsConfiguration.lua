--
-- Configuração para o interceptador de requisições ao serviço de acesso
--
local CONF_DIR = os.getenv("CONF_DIR")
local config = 
  assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()

-- acrescenta à configuração comum informações sobre métodos não checados
config.interface = "IDL:OpenBus/ACS/IAccessControlService:1.0"
config.excluded_ops = { loginByPassword = true, 
                        loginByCertificate = true,
                        getChallenge = true
                      }
return config
