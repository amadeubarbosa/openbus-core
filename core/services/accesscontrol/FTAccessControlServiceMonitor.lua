-- $Id

local os = os
local tostring = tostring

local oil = require "oil"

local orb = oil.orb

local tostring = tostring
local print = print

local IComponent = require "scs.core.IComponent"
local Log = require "openbus.common.Log"
local OilUtilities = require "openbus.common.OilUtilities"

local oop = require "loop.simple"

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


orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")
---
--Componente responsável pelo Monitor do Serviço de Controle de Acesso
---
module("core.services.accesscontrol.FTAccessControlServiceMonitor")

oop.class(_M, IComponent)

accessControlService = {}

---
--Cria um monitor do serviço de controle de acesso.
--
--@param name O nome do componente.
--@param config As configurações do componentes.
--@param accessControlService O serviço de controle de acesso a ser monitorado.
---
function __init(self, name, config, accessControlService)
  local component = IComponent:__init(name, 1)
  component.config = config
  self.accessControlService = accessControlService
  return oop.rawnew(self, component)
end

---
--Inicia o componente.
--
--@see scs.core.IComponent#startup
---
local BIN_DIR
function startup(self)
  BIN_DIR = os.getenv("OPENBUS_DATADIR") .. "/../core/bin"
  return self
end

---
--Obtém o Serviço de Controle de Acesso.
--
--@return O Serviço de Controle de Acesso, ou nil caso não tenha sido definido.
---
function getAccessControlService(self)
  return self.accessControlService
end

---
--Atualiza o serviço de controle de acesso a ser monitorado.
--
--@param accessControlService O serviço de controle de aceso a ser monitorado.
---
function setAccessControlService(self, accessControlService)
    self.accessControlService = accessControlService
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
--Monitora o serviço de controle de acesso e cria uma nova réplica se necessário.
---
function monitor(self)

    Log:faulttolerance("[Monitor SCA] Inicio")

    --variavel que conta ha quanto tempo o monitor esta monitorando
    local t = 5

    while true do
  
	local reinit = false

        local ok, res = self:getAccessControlService().__try:isAlive()  

	Log:faulttolerance("[Monitor SCA] isAlive? "..tostring(ok)) 

	--verifica se metodo conseguiu ser executado - isto eh, se nao ocoreu falha de comunicacao
        if ok then
	    --se objeto remoto está em estado de falha, precisa ser reinicializado
	    if not res then
		reinit = true
	        Log:faulttolerance("[Monitor SCA] Servico de Controle de Acesso em estado de falha. Matando o processo...")
		--pede para o objeto se matar
                self:getAccessControlService():kill()
	    end
	else
        Log:faulttolerance("[Monitor SCA] Servico de Controle de Acesso nao esta disponivel...")
	-- ocorreu falha de comunicacao com o objeto remoto
 	    reinit = true
	end

        if reinit then
		local timeToTry = 0

		repeat

		        Log:faulttolerance("[Monitor SCA] Espera 3 minutos para que dê tempo do Oil liberar porta...")

	                os.execute("sleep 180")

		        Log:faulttolerance("[Monitor SCA] Levantando Servico de Controle de Acesso...")

			  --Criando novo processo assincrono
			if self:isUnix() then
			--os.execute(BIN_DIR.."/run_ft_access_control_server.sh ".. self.config.hostPort..
			--						" &  > log_access_control_server-"..tostring(t)..".txt")
				os.execute(BIN_DIR.."/run_ft_access_control_server.sh ".. self.config.hostPort)
			else
			--os.execute("start "..BIN_DIR.."/run_ft_access_control_server.sh ".. self.config.hostPort..
			--						" > log_access_control_server-"..tostring(t)..".txt")
				os.execute("start "..BIN_DIR.."/run_ft_access_control_server.sh ".. self.config.hostPort)
			end

	                -- Espera 5 segundos para que dê tempo do SCA ter sido levantado
	                os.execute("sleep 5")

			self.accessControlService = nil

			local acs = orb:newproxy("corbaloc::"..self.config.hostName..":"..self.config.hostPort.."/ACS",
					             "IDL:openbusidl/acs/IAccessControlService:1.0")

			 --TODO: Quando o bug do oil for consertado, mudar para: if not acs:_non_existent() then
			 --local success, non_existent = acs.__try:_non_existent()
			 --if success and not non_existent then
			if OilUtilities:existent(acs) then
			     self.accessControlService = acs
			end

			timeToTry = timeToTry + 1

		--TODO: colocar o timeToTry de acordo com o tempo do monitor da réplica?
		until self.accessControlService ~= nil or timeToTry == 1000
		    

		if self.accessControlService == nil then
		     log:faulttolerance("[Monitor SCA] Servico de controle de acesso nao pode ser levantado.")
		     return nil
		end

	        Log:faulttolerance("[Monitor SCA] Servico de Controle de Acesso criado.")

        end
        Log:faulttolerance("[Monitor SCA] Dormindo:"..t)
	-- Dorme por 5 segundos
        oil.sleep(5)
        t = t + 5
        Log:faulttolerance("[Monitor SCA] Acordou")
    end
end


