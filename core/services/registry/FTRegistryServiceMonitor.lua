-- $Id

local os = os

local oil = require "oil"

local orb = oil.orb

local tostring = tostring
local print = print
local pairs = pairs

--local IComponent = require "scs.core.IComponent"
local Log = require "openbus.util.Log"
local OilUtilities = require "openbus.util.OilUtilities"

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

local BIN_DIR = os.getenv("OPENBUS_DATADIR") .. "/../core/bin"

Log:level(4)
oil.verbose:level(2)


orb:loadidlfile(IDLPATH_DIR.."/registry_service.idl")
---
--Componente responsável pelo Monitor do Serviço de Registro
---
module("core.services.registry.FTRegistryServiceMonitor")

------------------------------------------------------------------------------
-- Faceta FTRSMonitorFacet
------------------------------------------------------------------------------

FTRSMonitorFacet = oop.class{}


---
--Obtém o Serviço de registro.
--
--@return O Serviço de registro, ou nil caso não tenha sido definido.
---
function FTRSMonitorFacet:getService()
  return self.context.IFaultTolerantService
end


function FTRSMonitorFacet:isUnix()
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
function FTRSMonitorFacet:monitor()

    Log:faulttolerance("[Monitor SR] Inicio")

    --variavel que conta ha quanto tempo o monitor esta monitorando
    local t = 5

    while true do
  
	local reinit = false

    local ok, res = self:getService().__try:isAlive()  
	Log:faulttolerance("[Monitor SR] isAlive? "..tostring(ok))  

	--verifica se metodo conseguiu ser executado - isto eh, se nao ocoreu falha de comunicacao
        if ok then
	    --se objeto remoto está em estado de falha, precisa ser reinicializado
	    if not res then
		reinit = true
	        Log:faulttolerance("[Monitor SR] Servico de registro em estado de falha. Matando o processo...")
		--pede para o objeto se matar
                self:getService():kill()
	    end
	else
        Log:faulttolerance("[Monitor SR] Servico de registro nao esta disponivel...")
	-- ocorreu falha de comunicacao com o objeto remoto
 	    reinit = true
	end

        if reinit then

		local timeToTry = 0

		repeat
		
		    if self.recConnId ~= nil then
				local status, ftRecD = 
					oil.pcall(self.context.IComponent.getFacet, self.context.IComponent, "IDL:scs/core/IReceptacles:1.0")

				if not status then
					print("[IReceptacles::IComponent] Error while calling getFacet(IDL:scs/core/IReceptacles:1.0)")
					print("[IReceptacles::IComponent] Error: " .. ftRecD)
					return
				end
				ftRecD = orb:narrow(ftRecD)
			
				local status, void = oil.pcall(ftRecD.disconnect, ftRecD, self.recConnId)
				if not status then
					print("[IReceptacles::IReceptacles] Error while calling disconnect")
					print("[IReceptacles::IReceptacles] Error: " .. void)
					return
				end
			
				Log:faulttolerance("[Monitor SR] disconnect executed successfully!")
			
				Log:faulttolerance("[Monitor SR] Espera 3 minutos para que dê tempo do Oil liberar porta...")

				os.execute("sleep 180")
				
			end

			Log:faulttolerance("[Monitor SR] Levantando Servico de registro...")
				
                                      
			--Criando novo processo assincrono
			
			if self:isUnix() then
 			    os.execute(BIN_DIR.."/run_registry_server.sh ".. self.config.registryServerHostPort)
 			    --os.execute(BIN_DIR.."/run_registry_server.sh ".. self.config.registryServerHostPort..
			--						" & > log_registry_server-"..tostring(t)..".txt")
			else
  			    os.execute("start "..BIN_DIR.."/run_registry_server.sh "..
							 self.config.registryServerHostPort)
  			    --os.execute("start "..BIN_DIR.."/run_registry_server.sh "..
		--					 self.config.registryServerHostPort..
		--					"> log_registry_server-"..tostring(t)..".txt")
			end

        	-- Espera 5 segundos para que dê tempo do SR ter sido levantado
        	os.execute("sleep 5")

			local ftrsService = orb:newproxy("corbaloc::"..self.config.registryServerHostName..
											":"..self.config.registryServerHostPort.."/FTRS",
											"IDL:openbusidl/ft/IFaultTolerantService:1.0")

			self.recConnId = nil
			if OilUtilities:existent(ftrsService) then
				local ftRec = self:getFacetByName("IReceptacles")
				ftRec = orb:narrow(ftRec)
				self.recConnId = ftRec:connect("IFaultTolerantService",ftrsService)
				if not self.recConnId then
					Log:error("Erro ao conectar receptaculo IFaultTolerantService ao FTRSMonitor")
					os.exit(1)
				end
			end


			 timeToTry = timeToTry + 1

		until self.recConnId ~= nil or timeToTry == 1000
		    

		if self.recConnId == nil then
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



