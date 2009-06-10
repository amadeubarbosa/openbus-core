local pairs = pairs
local print = print
local tonumber = tonumber
local oil = require "oil"
local orb = oil.orb
local oop = require "loop.simple"

local log = require "openbus.common.Log"
log:level(4)

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local Properties = require "openbus.common.Properties"

local FTManager = require "openbus.common.FTManager"

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end


local faultTolerantManager = {}
---
--Interceptador de requisições de serviço tolerantes a falhas,
---
module "openbus.common.FTClientInterceptor"

oop.class(_M, ClientInterceptor)

---
--Cria o interceptador.
--
--@param config As configurações do interceptador.
--@param credentialManager O objeto onde a credencial do membro fica armazenada.
--
--@return O interceptador.
---
function __init(self, config, credentialManager)
  log:faulttolerance("[FTClientInterceptor] Construindo interceptador para cliente")
  log:faulttolerance("[FTClientInterceptor] Instanciando o FTManager")

  local hosts = {}
  local prop = Properties(DATA_DIR.."/conf/FaultToleranceConfiguration.properties")

  for key,value in pairs(prop.values) do
     if key:match("^acsHostAdd") then
        local i = tonumber(key:match("[0-9]+"))
	    hosts[i] = value
     end
  end

  faultTolerantManager = FTManager:__init("ACS", 
			"IDL:openbusidl/acs/IAccessControlService:1.0", 
			"access_control_service.idl", hosts)

  return ClientInterceptor.__init(self, config, credentialManager)
end

---
--Intercepta o request para envio da informação de contexto (credencial)
--
--@param request Informações sobre a requisição.
---
function sendrequest(self, request)
   log:faulttolerance("[FTClientInterceptor] Interceptando request do cliente")
   faultTolerantManager:checkService()
   return ClientInterceptor:sendrequest(request)
end
