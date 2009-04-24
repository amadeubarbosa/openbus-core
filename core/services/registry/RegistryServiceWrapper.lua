-- $Id: RegistryServiceWrapper.lua 


local os = os
local print = print
local loadfile = loadfile
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local type = type

local table = require "table"

local Log = require "openbus.common.Log"
local oop = require "loop.simple"


local ServiceWrapper = require "core.services.faulttolerance.ServiceWrapper"
local OilUtilities = require "openbus.common.OilUtilities"

local oil = require "oil"
local orb = oil.orb

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  Log:error("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end

orb:loadidlfile(IDLPATH_DIR.."/registry_service.idl")

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obt�m a configura��o do servi�o
assert(loadfile(DATA_DIR.."/conf/RegistryServerConfiguration.lua"))()

-- Seta os n�veis de verbose para o openbus e para o oil
if RegistryServerConfiguration.logLevel then
  Log:level(RegistryServerConfiguration.logLevel)
end
if RegistryServerConfiguration.oilVerboseLevel then
  oil.verbose:level(RegistryServerConfiguration.oilVerboseLevel)
end

local Properties = require "openbus.common.Properties"
---
--Componente respons�vel pelo Wrapper do Servi�o de Registro
---
local hosts = {}
local prop = Properties(DATA_DIR.."/conf/FaultToleranceConfiguration.properties")

for key,value in pairs(prop.values) do
   if key:match("^rsHostAdd") then
        local i = tonumber(key:match("[0-9]+"))
	hosts[i] = value
   end
end

--oop.class(_M, ServiceWrapper)

local obj = ServiceWrapper:__init("RS","IDL:openbusidl/rs/IRegistryService:1.0","registry_service.idl", hosts)

package.loaded["core.services.registry.RegistryServiceWrapper"] = obj



function obj:offersLookupInReplicas(criteria,notInHostAdd)

  Log:faulttolerance("[offersLookupInReplicas] Buscando ofertas nas replicas, exceto em ["..notInHostAdd.."].")
  local selectedOffers = {}
  local i = 0
  repeat

     local rs = self:getNextService(notInHostAdd)
     if rs ~= nil then
	     local selectedOffersTmp = rs:localFind(criteria)

	     if #selectedOffersTmp > 0 then
		     -- dentre as que encontrou...
		     for i, offerTmp in pairs(selectedOffersTmp) do
			       local insert = true
			       -- ... vai comparar com as ja recuperadas...
			       for j, offer in pairs(selectedOffers) do
				  --TODO: por algum motivo est� adicionando 1 na lista, nao consegui descobrir o porque
		                  --if type(offerTmp) == "table" and type(offer) == "table" then
					 -- ...para cada uma testa se � igual...
					 if offerTmp == offer then 
					   --...se for igual, nao precisa adicionar...
					   insert = false
					   break 
					 end 
				  --end
			       end 
	print("#########################################################################################")
	print(type(offerTmp))
	print(offerTmp)
	--		       if i ~= "n" then
			       --if insert and type(offerTmp) == "table" then
			       if insert then
			       --...so adiciona se ainda nao existe, para nao haver duplicatas
			print("so adiciona se ainda nao existe, para nao haver duplicatas -----------------------")
			print(offerTmp)
				 table.insert(selectedOffers, offerTmp)
			       end
	 	     end
	     end
     end
     i = i + 1 	
  until i == #self.hostsAdd

  return selectedOffers
end


function obj:getRegistryService()
   self:checkService()
   return self.service
end


---
--Registra uma nova oferta de servi�o. A oferta de servi�o  representada por
--uma tabela com os campos:
--   type: tipo da oferta (string)
--   description: descri��o (textual) da oferta
--   properties: lista de propriedades associadas � oferta (opcional)
--               cada propriedade � um par nome/valor (lista de strings)
--   member: refe�rncia para o membro que faz a oferta
--
--@param serviceOffer A oferta de servi�o.
--
--@return true e o identificador do registro da oferta em caso de sucesso, ou
--false caso contr�rio.
---
function obj:register(serviceOffer)
  return self:getRegistryService():register(serviceOffer)
end

---
--Adiciona uma oferta ao reposit�rio.
--
--@param offerEntry A oferta.
---
function obj:addOffer(offerEntry)
  return self:getRegistryService():addOffer(offerEntry)
end

---
--Constr�i um conjunto com os valores das propriedades, para acelerar a busca.
--OBS: procedimento v�lido enquanto propriedade for lista de strings !!!
--
--@param offerProperties As propriedades da oferta de servi�o.
--@param member O membro dono das propriedades.
--
--@return As propriedades da oferta em uma tabela cuja chave � o nome da
--propriedade.
---
function obj:createPropertyIndex(offerProperties, member)
    return self:getRegistryService():createPropertyIndex(offerProperties, member)
end

---
--Remove uma oferta de servi�o.
--
--@param identifier A identifica��o da oferta de servi�o.
--
--@return true caso a oferta tenha sido removida, ou false caso contr�rio.
---
function obj:unregister(identifier)
    return self:getRegistryService():unregister(identifier)
end

---
--Atualiza a oferta de servi�o associada ao identificador especificado. Apenas
--as propriedades da oferta podem ser atualizadas (nessa vers�o, substituidas).
--
--@param identifier O identificador da oferta.
--@param properties As novas propriedades da oferta.
--
--@return true caso a oferta seja atualizada, ou false caso contr�rio.
---
function obj:update(identifier, properties)
    return self:getRegistryService():update(identifier, properties)
end

---
--Busca por ofertas de servi�o de um determinado tipo, que atendam aos
--crit�rios (propriedades) especificados. A especifica��o de critrios
--� opcional.
--
--@param criteria Os crit�rios da busca.
--
--@return As ofertas de servi�o que correspondem aos crit�rios.
---
function obj:find(criteria)
    return self:getRegistryService():find(criteria)
end

---
--Verifica se uma oferta atende aos crit�rios de busca
--
--@param criteria Os crit�rios da busca.
--@param offerProperties As propriedades da oferta.
--
--@return true caso a oferta atenda aos crit�rios, ou false caso contr�rio.
---
function obj:meetsCriteria(criteria, offerProperties)
    return self:getRegistryService():meetsCriteria(criteria, offerProperties)
end

---
--Notifica��o de dele��o de credencial. As ofertas de servi�o relacionadas
--dever�o ser removidas.
--
--@param credential A credencial removida.
---
function obj:credentialWasDeleted(credential)
    return self:getRegistryService():credentialWasDeleted(credential)
end

---
--Gera uma identifica��o de oferta de servi�o.
--
--@return O identificador de oferta de servi�o.
---
function obj:generateIdentifier()
    return self:getRegistryService():generateIdentifier()
end

---
--Procedimento ap�s reconex�o do servi�o.
---
function obj:wasReconnected()
   return self:getRegistryService():wasReconnected()
end

---
--Finaliza o servi�o.
--
--@see scs.core.IComponent#shutdown
---
function obj:shutdown()
    return self:getRegistryService():shutdown()
end


