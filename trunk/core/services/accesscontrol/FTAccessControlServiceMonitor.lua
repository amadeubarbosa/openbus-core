-- $Id

local os = os
local tostring = tostring
local print = print

local oil = require "oil"
local orb = oil.orb

local Log = require "openbus.common.Log"
local OilUtilities = require "openbus.common.OilUtilities"
local oop = require "loop.simple"

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

Log:level(4)
oil.verbose:level(2)

---
--Componente (membro) responsável pelo Monitor do Serviço de Controle de Acesso
---
module("core.services.accesscontrol.FTAccessControlServiceMonitor")

------------------------------------------------------------------------------
-- Faceta FTACSMonitorFacet
------------------------------------------------------------------------------

FTACSMonitorFacet = oop.class{}

function FTACSMonitorFacet:isUnix()
    --TODO - Confirmar se vai manter assim
	if os.execute("uname") == 0 then
	--unix
       return true
	else
	--windows
 	   return false
	end
end

function FTACSMonitorFacet:getService()
	return self.context.IFaultTolerantService
end

---
--Monitora o serviço de controle de acesso e cria uma nova réplica se necessário.
---
function FTACSMonitorFacet:monitor()

    Log:faulttolerance("[Monitor SCA] Inicio")

    --variavel que conta ha quanto tempo o monitor esta monitorando
    local t = 5

    while true do
  
	local reinit = false

    local ok, res = self:getService().__try:isAlive()  

	Log:faulttolerance("[Monitor SCA] isAlive? "..tostring(ok)) 

	--verifica se metodo conseguiu ser executado - isto eh, se nao ocoreu falha de comunicacao
        if ok then
	    --se objeto remoto está em estado de falha, precisa ser reinicializado
	    if not res then
		reinit = true
	        Log:faulttolerance("[Monitor SCA] Servico de Controle de Acesso em estado de falha. Matando o processo...")
		--pede para o objeto se matar
                self:getService():kill()
	    end
	else
        Log:faulttolerance("[Monitor SCA] Servico de Controle de Acesso nao esta disponivel...")
	-- ocorreu falha de comunicacao com o objeto remoto
 	    reinit = true
	end

        if reinit then
		local timeToTry = 0

		repeat
		
			--self.accessControlService = nil
			self:getService():disconnect(self._nextConnId)

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

			
			local ftacsService = orb:newproxy("corbaloc::"..self.config.hostName..":"..self.config.hostPort.."/FTACS",
					             "IDL:openbusidl/ft/IFaultTolerantService:1.0")

			local connId = nil
			if OilUtilities:existent(ftacsService) then
			
			    --self.accessControlService = acs
				 
				local ftRec = self:getFacetByName("IReceptacles")
				ftRec = orb:narrow(ftRec)
				connId = ftRec:connect("IFaultTolerantService",ftacsService)
				if not connId then
					Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTACSMonitor")
					os.exit(1)
				end
			end

			timeToTry = timeToTry + 1

		--TODO: colocar o timeToTry de acordo com o tempo do monitor da réplica?
		until connId ~= nil or timeToTry == 1000
		    

		if connId == nil then
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

------------------------------------------------------------------------------
-- Faceta IComponent
------------------------------------------------------------------------------

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
