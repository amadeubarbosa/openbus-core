-- $Id: ServiceWrapper.lua 

local os = os
local print = print
local loadfile = loadfile
local tostring = tostring

local Log = require "openbus.common.Log"
local oop = require "loop.simple"

local OilUtilities = require "openbus.common.OilUtilities"

local oil = require "oil"

local orb = oil.orb

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  Log:error("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end

---
--module("core.services.faulttolerance.ServiceWrapper", ServiceWrapper)
module("core.services.faulttolerance.ServiceWrapper", oop.class)


---
--Cria um wrapper do serviço tolerante a falhas.
--
--@param name O nome do componente.
--@param objRef A referencia para o componente.
--@param type A interface do componente.
--@param typeFile O nome do arquivo da interface do componente.
---
function __init(self,name, type, typeFile, hosts)

  print("############################################################################")
  if self.objRefName == name then
     Log:faulttolerance("[faulttolerance] ServiceWrapper constructer - return EXISTENT instance of:["..name.."]")
     return self
  else
    Log:faulttolerance("[faulttolerance] ServiceWrapper constructer - return NEW instance of:["..name.."]")
    orb:loadidlfile(IDLPATH_DIR.."/"..typeFile)
    return oop.rawnew(self, {service = nil,
                             objRefName = name,
                             objReference = "corbaloc::"..tostring(hosts[1]).."/"..name,
                             objType = type,
                             hostsAdd = hosts, indexCurr = 0 })

  end


end


function updateHostInUse(self)
        local numberOfHosts = # self.hostsAdd

	if self.indexCurr == numberOfHosts then
	   self.indexCurr = 1
      	else
          self.indexCurr = self.indexCurr + 1
	end
	self.objReference = "corbaloc::"..tostring(self.hostsAdd[self.indexCurr]).."/"..self.objRefName	  
end


---
--   * Obtém o serviço de controle de acesso tolerante a falhas.
--   * 
--   * @param maxTimeToTry Numero maximo de vezes para procurar por uma replica.
--   * 
--   * @return Uma réplica do serviço de controle de acesso tolerante a falhas.
---
function fetchNewService(self,maxTimeToTry)
  local service = {}
  local timeToTry = 0
  local stop = false

  repeat

	self:updateHostInUse()

	local success	
	success, service = oil.pcall(orb.newproxy, orb, self.objReference, self.objType)

        Log:faulttolerance("[fetchNewService]"..self.objReference.."-TYPE:"..self.objType)


         if success then 
		 --TODO: Quando o bug do oil for consertado, mudar para: if not service:_non_existent() then
		 --local succ, non_existent = service.__try:_non_existent()
		 --if succ and not non_existent then
		if OilUtilities:existent(service) then
	 	     --OK
	             Log:faulttolerance("[fetchNewService] Servico encontrado.")
		     stop = true

		     --TODO: Essa linha é devido a um outro bug no OiL: type_id = ""
		     service.__reference.type_id = self.objType
		     -- fim do TODO
		 end
 	 end

         timeToTry = timeToTry + 1

  --TODO: colocar o timeToTry de acordo com o tempo do monitor da réplica
  until stop or timeToTry == maxTimeToTry

  if service == nil or service ==false then
     Log:faulttolerance("[fetchNewService] Servico tolerante a falhas nao encontrado.")
     return nil
  end

  self.service = service

end

function checkService(self)
   local fetch = false

   if self.service == nil then
      fetch = true
   else
	
	 --TODO: Quando o bug do oil for consertado, mudar para: if not service:_non_existent() then
	 --local succ, non_existent = self.service.__try:_non_existent()
	 if OilUtilities:existent(self.service) then
	        local ok, res = self.service.__try:isAlive()  
		--verifica se metodo conseguiu ser executado - isto eh, se nao ocoreu falha de comunicacao
		if ok then
		    --se objeto remoto está em estado de falha, precisa ser reinicializado
		    if not res then
			fetch = true
			--pede para o objeto se matar
		        self.service:kill()
		    end
		else
		-- ocorreu falha de comunicacao com o objeto remoto
	 	    fetch = true
		end
	 else 
	-- ocorreu falha de comunicacao com o objeto remoto
 	    fetch = true
	 end



   end

   if fetch then
      self:fetchNewService(1000)
   end
   Log:faulttolerance("[fetchNewService] Servico ok.")
end

function getService(self)
   self:checkService()
   return self.service
end

function getNextService(self, notInHostAdd)
  local service = nil
  local indexCurrTmp = self.indexCurr

	local numberOfHosts = # self.hostsAdd

	if indexCurrTmp == numberOfHosts then
	   indexCurrTmp = 1
	else
	  indexCurrTmp = indexCurrTmp + 1
	end

	if self.hostsAdd[indexCurrTmp] ~= notInHostAdd then
		local objRef = "corbaloc::"..tostring(self.hostsAdd[indexCurrTmp]).."/"..self.objRefName	

		local success	
		success, service = oil.pcall(orb.newproxy, orb, objRef, self.objType)

		Log:faulttolerance("[getNextService]"..objRef.."-TYPE:"..self.objType)

		 if success then 
			 --TODO: Quando o bug do oil for consertado, mudar para: if not service:_non_existent() then
			 --local succ, non_existent = service.__try:_non_existent()
			 --if succ and not non_existent then
			if OilUtilities:existent(service) then
		 	     --OK
			     Log:faulttolerance("[getNextService] Servico encontrado.")

			     --TODO: Essa linha é devido a um outro bug no OiL: type_id = ""
			     service.__reference.type_id = self.objType
			     -- fim do TODO
			 end
	 	 end

	 end


  if service == nil or service ==false then
     Log:faulttolerance("[getNextService] Servico nao encontrado.")
     return nil
  end

  return service

end


