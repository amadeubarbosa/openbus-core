-- $Id$

local os = os
local table = table
local string = string

local loadfile = loadfile
local assert = assert
local pairs = pairs
local ipairs = ipairs
local error = error
local next = next
local format = string.format
local print = print
local tostring = tostring
local type = type

local luuid = require "uuid"
local oil = require "oil"
local orb = oil.orb

local TableDB  = require "openbus.util.TableDB"
local OffersDB = require "core.services.registry.OffersDB"
local Openbus  = require "openbus.Openbus"
local FaultTolerantService = require "core.services.faulttolerance.FaultTolerantService"

local Log = require "openbus.util.Log"
local oop = require "loop.simple"
local Utils = require "openbus.util.Utils"

local DATA_DIR = os.getenv("OPENBUS_DATADIR")

---
--Componente (membro) respons�vel pelo Servi�o de Registro.
---
module("core.services.registry.RegistryService")

------------------------------------------------------------------------------
-- Faceta IRegistryService
------------------------------------------------------------------------------

RSFacet = oop.class{}

---
--Registra uma nova oferta de servi�o. A oferta de servi�o � representada por
--uma tabela com os campos:
--   properties: lista de propriedades associadas � oferta (opcional)
--               cada propriedade � um par nome/valor (lista de strings)
--   member: refe�rncia para o membro que faz a oferta
--
--@param serviceOffer A oferta de servi�o.
--
--@return true e o identificador do registro da oferta em caso de sucesso, ou
--false caso contr�rio.
---
function RSFacet:register(serviceOffer)
 local credential = Openbus:getInterceptedCredential()
  for _, existentOfferEntry in pairs(self.offersByIdentifier) do
  --para cada oferta existente
   local equalProp = true
   for _, property in ipairs(serviceOffer.properties) do
   --para cada propriedade da oferta a ser inserida
     if not existentOfferEntry.properties[property.name][property.val] then
      --se alguma nao existir, sao diferentes
       equalProp = false
       break   
     end
   end
   if equalProp then 
     if existentOfferEntry.credential.identifier == credential.identifier then
	     Log:registry("Oferta ja existente com id "..existentOfferEntry.identifier)
	     self:updateMemberInfoInExistentOffer(existentOfferEntry, serviceOffer.member)
         return true, existentOfferEntry.identifier
      end
   end  
  end
  local identifier = self:generateIdentifier()
  local properties = self:createPropertyIndex(serviceOffer.properties,
    serviceOffer.member)
  local memberName = properties.component_id.name

  -- Recupera todas as facetas do membro
  local allFacets
  local metaInterface = serviceOffer.member:getFacetByName("IMetaInterface")
  if metaInterface then
    metaInterface = orb:narrow(metaInterface, "IDL:scs/core/IMetaInterface:1.0")
    allFacets = metaInterface:getFacets()
  else
    allFacets = {}
    Log:registry(format("Membro '%s' (%s) n�o disponibiliza a interface IMetaInterface.",
        memberName, credential.owner))
  end

  local offerEntry = {
    offer = serviceOffer,
  -- Mapeia as propriedades.
    properties = properties,
  -- Mapeia as facetas do componente.
    facets = self:createFacetIndex(credential.owner, memberName, allFacets),
    allFacets = allFacets,
    credential = credential,
    identifier = identifier
  }

  Log:registry("Registrando oferta com id "..identifier)

  self:addOffer(offerEntry)
  self.offersDB:insert(offerEntry)

  return true, identifier
end

---
--Adiciona uma oferta ao reposit�rio.
--
--@param offerEntry A oferta.
---
function RSFacet:addOffer(offerEntry)

  -- �ndice de ofertas por identificador
  self.offersByIdentifier[offerEntry.identifier] = offerEntry

  -- �ndice de ofertas por credencial
  local credential = offerEntry.credential
  if not self.offersByCredential[credential.identifier] then
    Log:registry("Primeira oferta da credencial "..credential.identifier)
    self.offersByCredential[credential.identifier] = {}
  end
  self.offersByCredential[credential.identifier][offerEntry.identifier] =
    offerEntry

  -- A credencial deve ser observada, porque se for deletada as
  -- ofertas a ela relacionadas devem ser removidas
  local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle, 
  					 		  orb, 
                         	  self.context.IComponent, 
                         	  "AccessControlServiceReceptacle", 
                         	  "IAccessControlService", 
                         	  "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
  if status then
	    acsFacet:addCredentialToObserver(self.observerId,
                                   credential.identifier)
        Log:service("Adicionada credencial no observador")
  else
      -- erro ja foi logado, so adiciona que nao pode adicionar
	  Log:service("Nao foi possivel adicionar credencial ao observador")
  end                       		
end

function RSFacet:updateMemberInfoInExistentOffer(existentOfferEntry, member)
  Log:registry("[updateMemberInfoInExistentOffer] Atualizando informacoes de membro em oferta existente...")
  --Atencao, o identificador da credencial antiga � o que prevalece
  --por causa dos observadores
  existentOfferEntry.offer.member = member
  existentOfferEntry.offer.properties = self:createPropertyIndex(existentOfferEntry.offer.properties,
                                        existentOfferEntry.offer.member)
  self.offersDB:update(existentOfferEntry)  

  self.offersByCredential[existentOfferEntry.credential.identifier][existentOfferEntry.identifier] =
    existentOfferEntry
    
  Log:registry("[updateMemberInfoInExistentOffer] Informacoes de membro atualizadas.")
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
function RSFacet:createPropertyIndex(offerProperties, member)
  local properties = {}
  for _, property in ipairs(offerProperties) do
    properties[property.name] = {}
    for _, val in ipairs(property.value) do
      properties[property.name][val] = true
    end
  end
  local componentId = member:getComponentId()
  local compId = componentId.name..":"..componentId.major_version.. "."
      .. componentId.minor_version.."."..componentId.patch_version
  properties["component_id"] = {}
  properties["component_id"].name = componentId.name
  properties["component_id"][compId] = true

  local credential = Openbus:getInterceptedCredential()
  properties["registered_by"] = {}
  properties["registered_by"][credential.owner] = true

  return properties
end

---
-- Busca as interfaces por meio da metainterface do membro e as 
-- disponibiza para consulta.
--
-- @param owner Dono da credencial.
-- @param memberName Membro do barramento.
-- @param allFacets Array de facetas do membro.
--
-- @result �ndice de facetas dispon�veis do membro.
--
function RSFacet:createFacetIndex(owner, memberName, allFacets)
  local count = 0
  local facets = {}
  local mgm = self.context.IManagement
  for _, facet in ipairs(allFacets) do
    if mgm:hasAuthorization(owner, facet.interface_name) then
      facets[facet.name] = true
      facets[facet.interface_name] = true
      facets[facet.facet_ref] = true
      count = count + 1
    end
  end
  Log:registry(format("Membro '%s' (%s) possui %d faceta(s) autorizada(s).",
      memberName, owner, count))
  return facets
end

---
--Remove uma oferta de servi�o.
--
--@param identifier A identifica��o da oferta de servi�o.
--
--@return true caso a oferta tenha sido removida, ou false caso contr�rio.
---
function RSFacet:unregister(identifier)
  Log:registry("Removendo oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warning("Oferta a remover com id "..identifier.." n�o encontrada")
    return false
  end

  local credential = Openbus:getInterceptedCredential()
  if credential.identifier ~= offerEntry.credential.identifier then
    Log:warning("Oferta a remover("..identifier..
                ") n�o registrada com a credencial do chamador")
    return false -- esse tipo de erro merece uma exce��o!
  end

  -- Remove oferta do �ndice por identificador
  self.offersByIdentifier[identifier] = nil

  -- Remove oferta do �ndice por credencial
  local credentialOffers = self.offersByCredential[credential.identifier]
  if credentialOffers then
    credentialOffers[identifier] = nil
  else
    Log:registry("N�o h� ofertas a remover com credencial "..
        credential.identifier)
    return true
  end
  if not next (credentialOffers) then
    -- N�o h� mais ofertas associadas � credencial
    self.offersByCredential[credential.identifier] = nil
    Log:registry("�ltima oferta da credencial: remove credencial do observador")
    local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle, 
  	 				 		    orb, 
                         	    self.context.IComponent, 
                         	    "AccessControlServiceReceptacle", 
                         	    "IAccessControlService", 
                         	    "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
    if status then
	    acsFacet:removeCredentialFromObserver(self.observerId,credential.identifier)
	else
	  -- erro ja foi logado, so adiciona que nao pode remover
	  Log:error("Nao foi possivel remover credencial")
    end     
    acsFacet:removeCredentialFromObserver(self.observerId,credential.identifier)
  end
  self.offersDB:delete(offerEntry)
  return true
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
function RSFacet:update(identifier, properties)
  Log:registry("Atualizando oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warning("Oferta a atualizar com id "..identifier.." n�o encontrada")
    return false
  end

  local credential = Openbus:getInterceptedCredential()
  if credential.identifier ~= offerEntry.credential.identifier then
    Log:warning("Oferta a atualizar("..identifier..
                ") n�o registrada com a credencial do chamador")
    return false -- esse tipo de erro merece uma exce��o!
  end

  -- Atualiza as propriedades da oferta de servi�o
  offerEntry.offer.properties = properties
  offerEntry.properties = self:createPropertyIndex(properties,
                                                   offerEntry.offer.member)
  self.offersDB:update(offerEntry)
  return true
end

---
-- Atualiza as ofertas de facetas do membro.
--
-- @param owner Identifica��o do membro.
--
function RSFacet:updateFacets(owner)
  for id, offerEntry in pairs(self.offersByIdentifier) do
    if offerEntry.credential.owner == owner then
      offerEntry.facets = self:createFacetIndex(owner, 
        offerEntry.properties.component_id.name, offerEntry.allFacets)
      self.offersDB:update(offerEntry)
    end
  end
end

---
--Busca por ofertas de servi�o que implementam as facetas descritas.
--Se nenhuma faceta for fornecida, todas as facetas s�o retornadas.
--
--@param facets As facetas da busca.
--
--@return As ofertas de servi�o que foram encontradas.
---
function RSFacet:find(facets)
  local ftFacet = self.context.IFaultTolerantService
  --atualiza estado em todas as r�plicas

  local params = { facets = facets, criteria = {} }
  ftFacet:updateStatus(params)
  
  local selectedOffers = {}
-- Se nenhuma faceta foi discriminada, todas as ofertas de servi�o
-- s�o retornadas.
  if (#facets == 0) then
    for _, offerEntry in pairs(self.offersByIdentifier) do
      table.insert(selectedOffers, offerEntry.offer)
    end
  else
  -- Para cada oferta de servi�o dispon�vel, selecionar-se
  -- a oferta que implementa todas as facetas discriminadas.
    for _, offerEntry in pairs(self.offersByIdentifier) do
      local hasAllFacets = true
      for _, facet in ipairs(facets) do
        if not offerEntry.facets[facet] then
          hasAllFacets = false
          break
        end
      end
      if hasAllFacets then
        table.insert(selectedOffers, offerEntry.offer)
      end
    end
     Log:registry("Encontrei "..#selectedOffers..
         " ofertas que implementam as facetas discriminadas.")
  end
  return selectedOffers
end

---
--Busca por ofertas de servi�o que implementam as facetas descritas, e,
--que atendam aos crit�rios (propriedades) especificados.
--
--@param facets As facetas da busca.
--@param criteria Os crit�rios da busca.
--
--@return As ofertas de servi�o que foram encontradas.
---
function RSFacet:findByCriteria(facets, criteria)
  local ftFacet = self.context.IFaultTolerantService
  --atualiza estado em todas as r�plicas

  local params = { facets = facets, criteria = criteria}
  ftFacet:updateStatus(params)
  
  local selectedOffers = {}
-- Se nenhuma faceta foi discriminada e nenhum crit�rio foi
-- definido, todas as ofertas de servi�o s�o retornadas.
  if (#facets == 0 and #criteria == 0) then
    for _, offerEntry in pairs(self.offersByIdentifier) do
      table.insert(selectedOffers, offerEntry.offer)
    end
  else
-- Para cada oferta de servi�o dispon�vel, seleciona-se
-- a oferta que implementa todas as facetas discriminadas,
-- e, possui todos os crit�rios especificados.
    for _, offerEntry in pairs(self.offersByIdentifier) do
      if self:meetsCriteria(criteria, offerEntry.properties) then
        local hasAllFacets = true
        for _, facet in ipairs(facets) do
          if not offerEntry.facets[facet] then
            hasAllFacets = false
            break
          end
        end
        if hasAllFacets then
          table.insert(selectedOffers, offerEntry.offer)
        end
      end
    end
    Log:registry("Com crit�rio, encontrei "..#selectedOffers..
        " ofertas que implementam as facetas discriminadas.")
  end
  return selectedOffers
end

function RSFacet:localFind(facets, criteria)
	Log:faulttolerance("[localFind] Buscando ofertas somente na replica local.")
	local selectedOffersEntries = {}

    local i = 1
	-- Se nenhuma faceta foi discriminada e nenhum crit�rio foi
	-- definido, todas as ofertas de servi�o que n�o existem localmente
	-- devem ser retornadas.
	if (#facets == 0 and #criteria == 0) then
    	for _, offerEntry in pairs(self.offersByIdentifier) do
    		selectedOffersEntries[i] = {}
			selectedOffersEntries[i].identifier = offerEntry.identifier
			selectedOffersEntries[i].aServiceOffer = offerEntry.offer
			selectedOffersEntries[i].aCredential = offerEntry.credential
			selectedOffersEntries[i].properties = offerEntry.properties
			selectedOffersEntries[i].authorizedFacets = Utils.marshalHashFacets(offerEntry.facets)
			selectedOffersEntries[i].allFacets = offerEntry.allFacets
			i = i + 1
    	end
    	Log:registry("Encontrei "..#selectedOffersEntries..
			 " ENTRADAS de ofertas que implementam as facetas discriminadas.")
    	
	elseif (#facets > 0 and #criteria == 0)  then
	-- Para cada oferta de servi�o dispon�vel, deve-se selecionar
  	-- a oferta que implementa todas as facetas discriminadas.
  		for _, offerEntry in pairs(self.offersByIdentifier) do
			local hasAllFacets = true
			for _, facet in ipairs(facets) do
				if not offerEntry.facets[facet] then
				  hasAllFacets = false
				  break
				end
			end
			if hasAllFacets then
				selectedOffersEntries[i] = {}
				selectedOffersEntries[i].identifier = offerEntry.identifier
				selectedOffersEntries[i].aServiceOffer = offerEntry.offer
				selectedOffersEntries[i].aCredential = offerEntry.credential
				selectedOffersEntries[i].properties = offerEntry.properties
				selectedOffersEntries[i].authorizedFacets = Utils.marshalHashFacets(offerEntry.facets)
				selectedOffersEntries[i].allFacets = offerEntry.allFacets
				i = i + 1
			end
		end
		Log:registry("Encontrei "..#selectedOffersEntries..
			 " ENTRADAS de ofertas que implementam as facetas discriminadas.")
  
	else  
	-- Para cada oferta de servi�o dispon�vel, seleciona-se
	-- a oferta que implementa todas as facetas discriminadas,
	-- E, possui todos os crit�rios especificados.
		for _, offerEntry in pairs(self.offersByIdentifier) do
		  if self:meetsCriteria(criteria, offerEntry.properties) then
			local hasAllFacets = true
			for _, facet in ipairs(facets) do
			  if not offerEntry.facets[facet] then
				hasAllFacets = false
				break
			  end
			end
			if hasAllFacets then
				selectedOffersEntries[i] = {}
				selectedOffersEntries[i].identifier = offerEntry.identifier
				selectedOffersEntries[i].aServiceOffer = offerEntry.offer
				selectedOffersEntries[i].aCredential = offerEntry.credential
				selectedOffersEntries[i].properties = offerEntry.properties
				selectedOffersEntries[i].authorizedFacets = Utils.marshalHashFacets(offerEntry.facets)
				selectedOffersEntries[i].allFacets = offerEntry.allFacets
				i = i + 1
			end
		  end
		end
		Log:registry("Com crit�rio, encontrei "..#selectedOffersEntries..
			" ENTRADAS de ofertas que implementam as facetas discriminadas.")
	end
	return selectedOffersEntries
end

---
--Verifica se uma oferta atende aos crit�rios de busca
--
--@param criteria Os crit�rios da busca.
--@param offerProperties As propriedades da oferta.
--
--@return true caso a oferta atenda aos crit�rios, ou false caso contr�rio.
---
function RSFacet:meetsCriteria(criteria, offerProperties)
  for _, criterion in ipairs(criteria) do
    local offerProperty = offerProperties[criterion.name]
    if offerProperty then
      for _, val in ipairs(criterion.value) do
        if not offerProperty[val] then
          return false -- oferta n�o tem valor em seu conjunto
        end
      end
    else
      return false -- oferta n�o tem propriedade com esse nome
    end
  end
  return true
end

---
--Notifica��o de dele��o de credencial. As ofertas de servi�o relacionadas
--dever�o ser removidas.
--
--@param credential A credencial removida.
---
function RSFacet:credentialWasDeleted(credential)
  Log:registry("Remover ofertas da credencial deletada "..credential.identifier)
  local credentialOffers = self.offersByCredential[credential.identifier]
  self.offersByCredential[credential.identifier] = nil

  if credentialOffers then
    for identifier, offerEntry in pairs(credentialOffers) do
      self.offersByIdentifier[identifier] = nil
      Log:registry("Removida oferta "..identifier.." do �ndice por id")
      local succ, msg = self.offersDB:delete(offerEntry)
      if succ then
      	Log:registry("Removida oferta "..identifier.." do DB")
      else
      	Log:registry(msg)
      end
    end
  else
    Log:registry("N�o havia ofertas da credencial "..credential.identifier)
  end
end

---
--Procedimento ap�s reconex�o do servi�o.
---
function RSFacet:expired()
  Openbus:connectByCertificate(self.context._componentId.name,
      self.privateKeyFile, self.accessControlServiceCertificateFile)
  local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle, 
  					 		  orb, 
                         	  self.context.IComponent, 
                         	  "AccessControlServiceReceptacle", 
                         	  "IAccessControlService", 
                         	  "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
  if not status then
	    --erro ja joi logado
	    return nil
  end     
  -- atualiza a refer�ncia junto ao servi�o de controle de acesso
  -- conecta-se com o controle de acesso:   [ACS]--( 0--[RS]
  local acsIComp = acsFacet:_component()
  local acsIRecep =  acsIComp:getFacetByName("IReceptacles")
  acsIRecep = Openbus.orb:narrow(acsIRecep, "IDL:scs/core/IReceptacles:1.0")
  local status, conns = oil.pcall(acsIRecep.connect, acsIRecep, 
    "RegistryServiceReceptacle", self.context.IComponent )
  if not status then
    Log:error("Falha ao conectar o Servi�o de Registro no recept�culo: " ..
      conns[1])
    return false
  end

  -- registra novamente o observador de credenciais
  self.observerId = acsFacet:addObserver(self.observer, {})
  Log:registry("Observador recadastrado")

  -- Mant�m no reposit�rio apenas ofertas com credenciais v�lidas
  local offerEntries = self.offersByIdentifier
  local credentials = {}
  for _, offerEntry in pairs(offerEntries) do
    credentials[offerEntry.credential.identifier] = offerEntry.credential
  end
  local invalidCredentials = {}
  for credentialId, credential in pairs(credentials) do
    if not acsFacet:addCredentialToObserver(self.observerId,
                                            credentialId) then
      Log:registry("Ofertas de "..credentialId.." ser�o removidas")
      table.insert(invalidCredentials, credential)
    else
      Log:registry("Ofertas de "..credentialId.." ser�o mantidas")
    end
  end
  for _, credential in ipairs(invalidCredentials) do
    self:credentialWasDeleted(credential)
  end

  Log:registry("Servi�o de registro foi reconectado")
end

---
--Gera uma identifica��o de oferta de servi�o.
--
--@return O identificador de oferta de servi�o.
---
function RSFacet:generateIdentifier()
    return luuid.new("time")
end

--------------------------------------------------------------------------------
-- Faceta IFaultTolerantService
--------------------------------------------------------------------------------

FaultToleranceFacet = FaultTolerantService.FaultToleranceFacet
FaultToleranceFacet.ftconfig = {}
FaultToleranceFacet.rsReference = ""

function FaultToleranceFacet:init()
	self.ftconfig = assert(loadfile(DATA_DIR .."/conf/RSFaultToleranceConfiguration.lua"))()
  
	local rgs = self.context.IRegistryService
	local notInHostAdd = rgs.config.registryServerHostName..":"
				   ..tostring(rgs.config.registryServerHostPort) 

	self.rsReference = "corbaloc::" .. notInHostAdd .. "/" .. Utils.REGISTRY_SERVICE_KEY
end

function FaultToleranceFacet:updateStatus(params)
	--Atualiza estado das ofertas
	Log:faulttolerance("[updateStatus] Atualiza estado das ofertas.")
    if not self.ftconfig then
		Log:faulttolerance("[updateStatus] Faceta precisa ser inicializada antes de ser chamada.")
		Log:faultolerance("[warn][updateStatus] N�o foi poss�vel executar 'updatestatus'")
		return false
	end
	
	if # self.ftconfig.hosts.RS <= 1 then
		Log:faulttolerance("[updateStatus] Nenhuma replica para atualizar ofertas.")
		return false
	end
    --	O atributo _anyval so retorna em chamadas remotas, em chamadas locais (mesmo processo) 
    --	deve-se acessar o parametro diretamente, al�m disso , 
    --  passar uma tabela no any tbm so funciona porque eh local
	-- se fosse uma chamada remota teria q ter uma struct pois senao da problema de marshall
	local input
	if not params._anyval then
		input = params
	else
	--chamada remota
		input = params._anyval
	end
	
	local facets = {}
	local criteria = {}

	if input ~= "all" then
		facets = input.facets
		criteria = input.criteria
	end

	local updated = self:updateOffersStatus(facets, criteria)

	
	return updated
end

function FaultToleranceFacet:updateOffersStatus(facets, criteria)
	Log:faulttolerance("[updateOffersStatus] Buscando ofertas nas replicas exceto em ".. self.rsReference)
	local rgs = self.context.IRegistryService
	local updated = false
	local i = 1
    local count = 0
	repeat
	  if self.ftconfig.hosts.RS[i] ~= self.rsReference then
	     local ret, stop, remoteRS = oil.pcall(Utils.fetchService, 
											Openbus:getORB(), 
											self.ftconfig.hosts.RS[i], 
											Utils.REGISTRY_SERVICE_INTERFACE)
		
		 if remoteRS then
			local selectedOffersEntries = remoteRS:localFind(facets, criteria)
			
			if not rgs.offersByIdentifier then
			   rgs.offersByIdentifier = {}
			end
			--SINCRONIZA
			--para todas as ofertas encontradas nas replicas
			for _, offerEntryFound in pairs(selectedOffersEntries) do
			   if type(offerEntryFound) ~= "number" then
			     local insert = true
				 local addOfferEntry = {}
				 addOfferEntry.identifier = offerEntryFound.identifier
				 addOfferEntry.credential = offerEntryFound.aCredential
				 addOfferEntry.offer = offerEntryFound.aServiceOffer
                 addOfferEntry.facets = Utils.unmarshalHashFacets(offerEntryFound.authorizedFacets)
                 addOfferEntry.allFacets = offerEntryFound.allFacets
                 addOfferEntry.properties = offerEntryFound.properties			     
				 -- verifica se ja existem localmente
				 Log:faulttolerance("[updateOffersStatus] Verificando se a oferta [".. 
				                       addOfferEntry.identifier .. "] ja existe localmente ...")
				 for _, offerEntry in pairs(rgs.offersByIdentifier) do
					--se ja existir, nao adiciona
					if Utils.equalsOfferEntries(addOfferEntry, offerEntry) then
						--se ja existir, nao insere
						insert = false
						Log:faulttolerance("[updateOffersStatus] ... SIM, a oferta [".. 
						                  addOfferEntry.identifier .. "] ja existe localmente.")
						break
					end
				 end
				 if insert then  
				    Log:faulttolerance("[updateOffersStatus] ... NAO, a oferta [".. 
				                       addOfferEntry.identifier .. "] nao existe localmente e sera inserida.")
				   -- se nao existir,
				   --insere na lista local
                   rgs:addOffer(addOfferEntry)
                    --insere no banco local
				   rgs.offersDB:insert(addOfferEntry) 

				   updated = true
				   count = count + 1
				 end
			   end
			end
		 end
	  end
	  i = i + 1 	
	until i > # self.ftconfig.hosts.RS
	if updated then
		Log:faulttolerance("[updateOffersStatus] Quantidade de ofertas inseridas:[".. tostring(count) .."].")
	else
	    Log:faulttolerance("[updateOffersStatus] Nenhuma oferta inserida.")
	end
	return updated
end

--------------------------------------------------------------------------------
-- Faceta IComponent
--------------------------------------------------------------------------------

---
--Inicia o servico.
--
--@see scs.core.IComponent#startup
---
function startup(self)
  Log:registry("Pedido de startup para servi�o de registro")
  local mgm = self.context.IManagement
  local rs = self.context.IRegistryService
  local config = rs.config

  -- Verifica se � o primeiro startup
  if not rs.initialized then
    Log:registry("Servi�o de registro est� inicializando")
    if string.match(config.privateKeyFile, "^/") then
      rs.privateKeyFile = config.privateKeyFile
    else
      rs.privateKeyFile = DATA_DIR.."/"..config.privateKeyFile
    end
    if string.match(config.accessControlServiceCertificateFile, "^/") then
      rs.accessControlServiceCertificateFile =
        config.accessControlServiceCertificateFile
    else
      rs.accessControlServiceCertificateFile = DATA_DIR .. "/" ..
        config.accessControlServiceCertificateFile
    end

    -- instancia mecanismo de persistencia
    local databaseDirectory
    if string.match(config.databaseDirectory, "^/") then
      databaseDirectory = config.databaseDirectory
    else
      databaseDirectory = DATA_DIR.."/"..config.databaseDirectory
    end
    rs.offersDB = OffersDB(databaseDirectory)
    rs.initialized = true
  else
    Log:registry("Servi�o de registro j� foi inicializado")
  end

  -- Inicializa o reposit�rio de ofertas
  rs.offersByIdentifier = {}   -- id -> oferta
  rs.offersByCredential = {}  -- credencial -> id -> oferta

  Openbus.rgs = rs
  -- autentica o servi�o, conectando-o ao barramento
  if not Openbus:isConnected() then
    Openbus:connectByCertificate(self.context._componentId.name,
      rs.privateKeyFile, rs.accessControlServiceCertificateFile)
  end

  -- Cadastra callback para LeaseExpired
  Openbus:addLeaseExpiredCallback( rs )

  -- obt�m a refer�ncia para o Servi�o de Controle de Acesso
  local accessControlService = Openbus:getAccessControlService()

  -- conecta-se com o controle de acesso:   [ACS]--( 0--[RS]
  local acsIComp = Openbus:getACSIComponent()
  local acsIRecep =  acsIComp:getFacetByName("IReceptacles")
  acsIRecep = Openbus.orb:narrow(acsIRecep, "IDL:scs/core/IReceptacles:1.0")
  local status, conns = oil.pcall(acsIRecep.connect, acsIRecep, 
    "RegistryServiceReceptacle", self.context.IComponent )
  if not status then
    Log:error("Falha ao conectar o Servi�o de Registro no recept�culo: " ..
      conns[1])
    return false
  end
  
  -- conecta o controle de acesso:   [RS]--( 0--[ACS]
  local success, conId =
    oil.pcall(self.context.IReceptacles.connect, self.context.IReceptacles,
              "AccessControlServiceReceptacle", acsIComp)
  if not success then
    Log:error("Erro durante conex�o com servi�o de Controle de Acesso.")
    Log:error(conId)
    error{"IDL:SCS/StartupFailed:1.0"}
 end


  -- registra um observador de credenciais
  local observer = {
    registryService = rs,
    credentialWasDeleted = function(self, credential)
      Log:registry("Observador notificado para credencial "..
          credential.identifier)
      self.registryService:credentialWasDeleted(credential)
    end
  }
  rs.observer = orb:newservant(observer, "RegistryServiceCredentialObserver",
    "IDL:tecgraf/openbus/core/v1_05/access_control_service/ICredentialObserver:1.0"
  )
  rs.observerId =
    accessControlService:addObserver(rs.observer, {})
  Log:registry("Cadastrado observador para a credencial")

  -- recupera ofertas persistidas
  Log:registry("Recuperando ofertas persistidas")
  local offerEntriesDB = rs.offersDB:retrieveAll()
  for _, offerEntry in pairs(offerEntriesDB) do
    -- somente recupera ofertas de credenciais v�lidas
    if accessControlService:isValid(offerEntry.credential) then
      rs:addOffer(offerEntry)
    else
      Log:registry("Oferta de "..offerEntry.credential.identifier.." descartada")
      rs.offersDB:delete(offerEntry)
    end
  end

  -- Refer�ncia � faceta de gerenciamento do ACS
  mgm.acsmgm = acsIComp:getFacetByName("IManagement")
  mgm.acsmgm = orb:narrow(mgm.acsmgm, "IDL:tecgraf/openbus/core/v1_05/access_control_service/IManagement:1.0")
  -- Administradores dos servi�os
  mgm.admins = {}
  for _, name in ipairs(config.administrators) do
     mgm.admins[name] = true
  end
  -- ACS � sempre administrador
  mgm.admins.AccessControlService = true
  -- Inicializa a base de gerenciamento
  mgm.authDB = TableDB(DATA_DIR.."/rs_auth.db")
  mgm.ifaceDB = TableDB(DATA_DIR.."/rs_iface.db")
  mgm:loadData()

  rs.started = true
  
  self.context.IFaultTolerantService:init()
  self.context.IFaultTolerantService:setStatus(true)
  
  Log:registry("Servi�o de registro iniciado")
end

---
--Finaliza o servi�o.
--
--@see scs.core.IComponent#shutdown
---
function shutdown(self)
  Log:registry("Pedido de shutdown para servi�o de registro")
  local rs = self.context.IRegistryService
  if not rs.started then
    Log:error("Servico ja foi finalizado.")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  rs.started = false

  -- Remove o observador
  if rs.observerId then
    local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle, 
  					 		    orb, 
                         	    self.context.IComponent, 
                         	    "AccessControlServiceReceptacle", 
                         	    "IAccessControlService", 
                         	    "IDL:tecgraf/openbus/core/v1_05/access_control_service/IAccessControlService:1.0")
    if not status then
	    -- erro ja foi logado
	    error{"IDL:SCS/ShutdownFailed:1.0"}
    end     
    acsFacet:removeObserver(rs.observerId)
    rs.observer:_deactivate()
  end

  if Openbus:isConnected() then
    Openbus:disconnect()
  end

  Log:registry("Servi�o de registro finalizado")
  
   orb:deactivate(rs)
   orb:deactivate(self.context.IManagement)
   orb:shutdown()
   Log:faulttolerance("Servico de Registro matou seu processo.")
end

--------------------------------------------------------------------------------
-- Faceta IManagement
--------------------------------------------------------------------------------

-- Aliases
local InvalidRegularExpressionException = "IDL:tecgraf/openbus/core/v1_05/registry_service/InvalidRegularExpression:1.0"
local InterfaceIdentifierInUseException = "IDL:tecgraf/openbus/core/v1_05/registry_service/InterfaceIdentifierInUse:1.0"
local InterfaceIdentifierNonExistentException = "IDL:tecgraf/openbus/core/v1_05/registry_service/InterfaceIdentifierNonExistent:1.0"
local InterfaceIdentifierAlreadyExistsException = "IDL:tecgraf/openbus/core/v1_05/registry_service/InterfaceIdentifierAlreadyExists:1.0"
local UserNonExistentException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/UserNonExistent:1.0"
local MemberNonExistentException = "IDL:tecgraf/openbus/core/v1_05/registry_service/MemberNonExistent:1.0"
local SystemDeploymentNonExistentException = "IDL:tecgraf/openbus/core/v1_05/access_control_service/SystemDeploymentNonExistent:1.0"
local AuthorizationNonExistentException = "IDL:tecgraf/openbus/core/v1_05/registry_service/AuthorizationNonExistent:1.0"

ManagementFacet = oop.class{}

ManagementFacet.expressions = {
  -- IDL:foo:* , IDL:foo/bar:*
  ["^IDL:([^%*]+):%*$"] = "^IDL:%1:%%d+%%.%%d+$",
  -- IDL:*:* , IDL:foo/*:* , IDL:foo*:*
  ["^IDL:([^%*]*)%*:%*$"] = "^IDL:%1.*:%%d+%%.%%d+$",
  -- IDL:*:1.0 , IDL:foo/*:1.0 , IDL:foo*:1.0
  ["^IDL:([^%*]*)%*:(%d+%.%d+)$"] = "^IDL:%1.*:%2$",
  -- IDL:foo:1.*
  ["^IDL:([^%*]+):(%d+%.)%*$"] = "^IDL:%1:%2%%d+$",
  -- IDL:*:1.* , IDL:foo/*:1.* , IDL:foo*:1.*
  ["^IDL:([^%*]*)%*:(%d%.)%*$"] = "^IDL:%1.*:%2%%d+$",
}

---
-- Verifica se o usu�rio tem permiss�o para executar o m�todo.
--
function ManagementFacet:checkPermission()
  local credential = Openbus:getInterceptedCredential()
  local admin = self.admins[credential.owner] or
                self.admins[credential.delegate]
  if not admin then
    error(Openbus:getORB():newexcept {
      "IDL:omg.org/CORBA/NO_PERMISSION:1.0",
      minor_code_value = 0,
      completion_status = 1,
    })
  end
end

---
-- Carrega os dados das bases de dados.
--
function ManagementFacet:loadData()
  -- Cache de objetos
  self.interfaces = {}
  self.authorizations = {}
  -- Carrega interfaces
  local data = assert(self.ifaceDB:getValues())
  for _, iface in ipairs(data) do
    self.interfaces[iface] = true
  end
  -- Carrega as autoriza��es.
  -- Verificar junto ao ACS o membro ainda existe.
  local remove = {}
  data = assert(self.authDB:getValues())
  for _, auth in ipairs(data) do
    local succ, err
    if auth.type == "ATSystemDeployment" then
      succ, err = self.acsmgm.__try:getSystemDeployment(auth.id)
    else -- type == "ATUser"
      succ, err = self.acsmgm.__try:getUser(auth.id)
    end
    if succ then
      self.authorizations[auth.id] = auth
    else
      if err[1] == SystemDeploymentNonExistentException or
         err[1] == UserNonExistentException
      then
        remove[auth] = true
        Log:warn(format("Removendo autoriza��es de '%s': " ..
         "removido do Servi�o de Controle de Acesso.", auth.id))
      else
        error(err) -- Exce��o desconhecida, repassando
      end
    end
  end
  for auth in pairs(remove) do
    self.authDB:remove(auth.id)
  end
end

---
-- Cadastra um identificador de interface aceito pelo Servi�o de Registro.
--
-- @param ifaceId Identificador de interface.
--
function ManagementFacet:addInterfaceIdentifier(ifaceId)
  self:checkPermission()
  if self.interfaces[ifaceId] then
    Log:error(format("Interface '%s' j� cadastrada.", ifaceId))
    error{InterfaceIdentifierAlreadyExistsException}
  end
  self.interfaces[ifaceId] = true
  local succ, msg = self.ifaceDB:save(ifaceId, ifaceId)
  if not succ then
    Log:error(format("Falha ao salvar a interface '%s': %s",
      ifaceId, msg))
  end
end

---
-- Remove o identificador.
-- 
-- @param ifaceId Identificador de interface.
-- 
function ManagementFacet:removeInterfaceIdentifier(ifaceId)
  self:checkPermission()
  if not self.interfaces[ifaceId] then
    Log:error(format("Interface '%s' n�o est� cadastrada.", ifaceId))
    error{InterfaceIdentifierNonExistentException}
  end
  for _, auth in pairs(self.authorizations) do
    if auth.authorized[ifaceId] == "strict" then
      Log:error(format("Interface '%s' em uso.", ifaceId))
      error{InterfaceIdentifierInUseException}
    end
  end
  self.interfaces[ifaceId] = nil
  local succ, msg = self.ifaceDB:remove(ifaceId)
  if not succ then
    Log:error(format("Falha ao remover interface '%s': %s", iface, msg))
  end
end

---
-- Recupera todos os identificadores de interface cadastrados.
--
-- @return Seq��ncia de identificadores de interface.
--
function ManagementFacet:getInterfaceIdentifiers()
  local array = {}
  for iface in pairs(self.interfaces) do
    array[#array+1] = iface
  end
  return array
end

---
-- Autoriza o membro a exportar a interface.  O Servi�o de Acesso
-- � consultado para verificar se o membro est� cadastrado.
--
-- @param id Identificador do membro.
-- @param ifaceId Identificador da interface.
--
function ManagementFacet:grant(id, ifaceId, strict)
  self:checkPermission()
  local expression
  if string.match(ifaceId, "%*") then
    for exp in pairs(self.expressions) do
      if string.match(ifaceId, exp) then
        expression = true
        break
      end
    end
    if not expression then
      Log:error(format("Express�o regular inv�lida: '%s'", ifaceId))
      error{InvalidRegularExpressionException}
    end
  elseif strict and not self.interfaces[ifaceId] then
    Log:error(format("Interface '%s' n�o cadastrada.", ifaceId))
    error{InterfaceIdentifierNonExistentException}
  end
  local auth = self.authorizations[id]
  if not auth then 
    -- Cria uma nova autoriza��o: verificar junto ao ACS se o membro existe
    local type = "ATSystemDeployment"
    local succ, member = self.acsmgm.__try:getSystemDeployment(id)
    if not succ then
      if member[1] ~= SystemDeploymentNonExistentException then
        error(member)  -- Exce��o desconhecida, repassando
      end
      type = "ATUser"
      succ, member = self.acsmgm.__try:getUser(id)
      if not succ then
        if member[1] ~= UserNonExistentException then
          error(member)  -- Exce��o desconhecida, repassando
        end
        Log:error(format("Membro '%s' n�o cadastrado.", id))
        error{MemberNonExistentException}
      end
    end
    auth = {
      id = id,
      type = type,
      authorized = {},
    }
    self.authorizations[id] = auth
  elseif auth and auth.authorized[ifaceId] then
    return
  end
  if expression then
    auth.authorized[ifaceId] = "expression"
  elseif strict then
    auth.authorized[ifaceId] = "strict"
  else
    auth.authorized[ifaceId] = "normal"
  end
  local succ, msg = self.authDB:save(id, auth)
  if not succ then
    Log:error(format("Falha ao salvar autoriza��o '%s': %s", id, msg))
  end
  self.context.IRegistryService:updateFacets(id)
end

---
-- Revoga a autoriza��o para exportar a interface.
--
-- @param id Identificador do membro.
-- @param ifaceId Identificador da interface.
--
function ManagementFacet:revoke(id, ifaceId)
  self:checkPermission()
  local auth = self.authorizations[id]
  if not (auth and auth.authorized[ifaceId]) then
    Log:error(format("N�o h� autoriza��o para '%s'.", id))
    error{AuthorizationNonExistentException}
  end
  local succ, msg
  auth.authorized[ifaceId] = nil
  -- Se n�o houver mais autoriza��es, remover a entrada
  if next(auth.authorized) then
    succ, msg = self.authDB:save(id, auth)
  else
    self.authorizations[id] = nil
    succ, msg = self.authDB:remove(id)
  end
  if not succ then
    Log:error(format("Falha ao remover autoriza��o '%s': %s", id, msg))
  end
  self.context.IRegistryService:updateFacets(id)
end

---
-- Remove a autoriza��o do membro.
--
-- @param id Identificador do membro.
--
function ManagementFacet:removeAuthorization(id)
  self:checkPermission()
  if not self.authorizations[id] then
    Log:error(format("N�o h� autoriza��o para '%s'.", id))
    error{AuthorizationNonExistentException}
  end
  self.authorizations[id] = nil
  local succ, msg = self.authDB:remove(id)
  if not succ then
    Log:error(format("Falha ao remover autoriza��o '%s': %s", id, msg))
  end
  self.context.IRegistryService:updateFacets(id)
end

---
-- Duplica a autoriza��o, mas a lista de interfaces � retornada
-- como array e n�o como hash. Essa fun��o � usada para exportar
-- a autoriza��o.
--
-- @param auth Autoriza��o a ser duplicada.
-- @return C�pia da autoriza��o.
--
function ManagementFacet:copyAuthorization(auth)
  local tmp = {}
  for k, v in pairs(auth) do
    tmp[k] = v
  end
  -- Muda de hash para array
  local authorized = {}
  for iface in pairs(tmp.authorized) do
    authorized[#authorized+1] = iface
  end
  tmp.authorized = authorized
  return tmp
end

---
-- Verifica se o membro � autorizado a exporta uma determinada interface.
--
-- @param id Identificador do membro.
-- @param iface Interface a ser consultada (repID).
--
-- @return true se � autorizada, false caso contr�rio.
--
function ManagementFacet:hasAuthorization(id, iface)
  local auth = self.authorizations[id]
  if auth and auth.authorized[iface] then
    return true
  elseif auth then
    for exp, type in pairs(auth.authorized) do
      if type == "expression" then
        for pat, sub in pairs(self.expressions) do
          -- Tenta criar o padr�o para Lua a partir da autoriza��o
          pat, sub = string.gsub(exp, pat, sub)
          -- Se o padr�o foi criado, verifica se a interface � reconhecida
          if sub == 1 and string.match(iface, pat) then
            return true
          end
        end
      end
    end
  end
  return false
end

---
-- Recupera a autoriza��o de um membro.
--
-- @param id Identificador do membro.
--
-- @return Autoriza��o do membro.
--
function ManagementFacet:getAuthorization(id)
  local auth = self.authorizations[id]
  if not auth then
    Log:error(format("N�o h� autoriza��o para '%s'.", id))
    error{AuthorizationNonExistentException}
  end
  return self:copyAuthorization(auth)
end

---
-- Recupera todas as autoriza��es cadastradas.
--
-- @return Seq��ncia de autoriza��es.
--
function ManagementFacet:getAuthorizations()
  local array = {}
  for _, auth in pairs(self.authorizations) do
    array[#array+1] = self:copyAuthorization(auth)
  end
  return array
end

---
-- Recupera as autoriza��es que cont�m \e todas as interfaces
-- fornecidas em seu conjunto de interfaces autorizadas.
--
-- @param ifaceIds Seq��ncia de identifidores de interface.
--
-- @return Seq��ncia de autoriza��es.
--
function ManagementFacet:getAuthorizationsByInterfaceId(ifaceIds)
  local array = {}
  for _, auth in pairs(self.authorizations) do
    local found = true
    for _, iface in ipairs(ifaceIds) do
      if not auth.authorized[iface] then
        found = false
        break
      end
    end
    if found then
      array[#array+1] = self:copyAuthorization(auth)
    end
  end
  return array
end
