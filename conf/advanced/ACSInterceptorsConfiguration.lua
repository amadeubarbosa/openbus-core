--
-- Configura��o para o interceptador de requisi��es ao servi�o de acesso
--
local CONF_DIR = os.getenv("CONF_DIR")
local config = 
  assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()

-- acrescenta � configura��o comum informa��es sobre m�todos n�o checados
config.interface = "IDL:OpenBus/ACS/IAccessControlService:1.0"
config.excluded_ops = { loginByPassword = true, 
                        loginByCertificate = true,
                        getChallenge = true
                      }
return config
