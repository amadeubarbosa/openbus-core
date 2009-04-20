-- $Id

local os = os

local oil = require "oil"

local orb = oil.orb

local tostring = tostring
local print = print

local IComponent = require "scs.core.IComponent"
local Log = require "openbus.common.Log"
local OilUtilities = require "openbus.common.OilUtilities"

local oop = require "loop.simple"

local RegistryService = require "core.services.registry.RegistryService"

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")


if IDLPATH_DIR == nil then
  Log:error("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end


local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

Log:level(4)
oil.verbose:level(2)


orb:loadidlfile(IDLPATH_DIR.."/registry_service.idl")
---
--Componente responsável pelo Monitor do Serviço de Registro
---
module("core.services.registry.FTRegistryServiceMonitor")

oop.class(_M, IComponent)

registryService = {}

---
--Cria um monitor do serviço de registro.
--
--@param name O nome do componente.
--@param config As configurações do componentes.
--@param accessControlService O serviço de registro a ser monitorado.
---
function __init(self, name, config, registryService)
  local component = IComponent:__init(name, 1)
  component.config = config
  self.registryService = registryService
  return oop.rawnew(self, component)
end

---
--Inicia o componente.
--
--@see scs.core.IComponent#startup
---
function startup(self)
  local BIN_DIR = os.getenv("OPENBUS_DATADIR") .. "../../core/bin"
  return self
end

---
--Obtém o Serviço de registro.
--
--@return O Serviço de registro, ou nil caso não tenha sido definido.
---
function getRegistryService(self)
  return self.registryService
end

---
--Atualiza o serviço de registro a ser monitorado.
--
--@param accessControlService O serviço de controle de aceso a ser monitorado.
---
function setRegistryService(self, registryService)
    self.registryService = registryService
end


function isUnix()
--TODO - Confirmar se vai manter assim
	if os.execute("uname") == 0 then
	--unix
           return true
	else
	--windows
 	   return false
	end
end

---
--Monitora o serviço de registro e cria uma nova réplica se necessário.
---
function monitor(self)

    Log:faulttolerance("[Monitor SR] Inicio")

    --variavel que conta ha quanto tempo o monitor esta monitorando
    local t = 5

    while true do
  
	local reinit = false

        local ok, res = self:getRegistryService().__try:isAlive()  
	Log:faulttolerance("[Monitor SR] isAlive? "..tostring(ok))  

	--verifica se metodo conseguiu ser executado - isto eh, se nao ocoreu falha de comunicacao
        if ok then
	    --se objeto remoto está em estado de falha, precisa ser reinicializado
	    if not res then
		reinit = true
	        Log:faulttolerance("[Monitor SR] Servico de registro em estado de falha. Matando o processo...")
		--pede para o objeto se matar
                self:getRegistryService():kill()
	    end
	else
        Log:faulttolerance("[Monitor SR] Servico de registro nao esta disponivel...")
	-- ocorreu falha de comunicacao com o objeto remoto
 	    reinit = true
	end

        if reinit then

	        Log:faulttolerance("[Monitor SR] Espera 3 minutos (180 segundos) para que dê tempo do Oil liberar porta...")

                os.execute("sleep 180")

	        Log:faulttolerance("[Monitor SR] Levantando Servico de registro...")
                                      
		  --Criando novo processo assincrono
		if self:isUnix() then
 		    os.execute(BIN_DIR.."/run_ft_registry_server.sh ".. self.config.accessControlServerHostPort..
									" & > log_registry_server-"..tostring(t)..".txt")
		else
  		    os.execute("start "..BIN_DIR.."/run_ft_registry_server.sh "..
							 self.config.accessControlServerHostPort..
							"> log_registry_server-"..tostring(t)..".txt")
		end

                -- Espera 5 segundos para que dê tempo do SR ter sido levantado
                os.execute("sleep 5")

		local timeToTry = 0

		self.registryService = nil

		repeat
			local registry = orb:newproxy("corbaloc::"..self.config.accessControlServerHost.."/RS",
					             "IDL:openbusidl/rs/IRegistryService:1.0")

			 --TODO: Quando o bug do oil for consertado, mudar para: if not registry:_non_existent() then
			 --local success, non_existent = registry.__try:_non_existent()
			 --if success and not non_existent then
		 	 if OilUtilities:existent(registry) then
			     self.registryService = registry
			 end

			 timeToTry = timeToTry + 1

		--TODO: colocar o timeToTry de acordo com o tempo do monitor da réplica?
		until self.registryService ~= nil or timeToTry == 1000
		    

		if self.registryService == nil then
		     log:faulttolerance("[Monitor SR] Servico de registro nao encontrado.")
		     return nil
		end

	        Log:faulttolerance("[Monitor SR] Servico de registro criado.")

        end
        Log:faulttolerance("[Monitor SR] Dormindo:"..t)
	-- Dorme por 5 segundos
        oil.sleep(5)
        t = t + 5
        Log:faulttolerance("[Monitor SR] Acordou")
    end
end


