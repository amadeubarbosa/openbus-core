-- $Id$

local os = os
local table = table
local string = string
local socket = require "socket"

local loadfile = loadfile
local assert = assert
local pairs = pairs
local ipairs = ipairs
local error = error
local next = next
local format = string.format
local print = print
local tostring = tostring
local tonumber = tonumber
local type = type
local setfenv = setfenv

local luuid = require "uuid"
local oil = require "oil"
local orb = oil.orb

local TableDB  = require "openbus.util.TableDB"
local OffersDB = require "core.services.registry.OffersDB"
local Openbus  = require "openbus.Openbus"
local FaultTolerantService =
  require "core.services.faulttolerance.FaultTolerantService"
local AdaptiveReceptacle = require "scs.adaptation.AdaptiveReceptacle"

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
-- Indica uma falha inesperada em um servi�o b�sico
ServiceFailureException = "IDL:tecgraf/openbus/core/"..
  Utils.OB_VERSION.."/ServiceFailure:1.0"

-- Indica que o servi�o tentou registrar alguma faceta n�o autorizada
UnauthorizedFacetsException = "IDL:tecgraf/openbus/core/"..
  Utils.OB_VERSION.."/registry_service/UnauthorizedFacets:1.0"

-- Indica que Servi�o de Registro n�o possui a oferta de servi�o indicada
ServiceOfferDoesNotExistException = "IDL:tecgraf/openbus/core/"..
  Utils.OB_VERSION.."/registry_service/ServiceOfferDoesNotExist:1.0"

-- Indica que o membro � inv�lido
InvalidMemberException = "IDL:tecgraf/openbus/core/"..
  Utils.OB_VERSION.."/registry_service/InvalidMember:1.0"

-- Indica que as propriedades s�o inv�lidas
InvalidPropertiesException = "IDL:tecgraf/openbus/core/"..
  Utils.OB_VERSION.."/registry_service/InvalidProperties:1.0"

-- Estas facetas s�o ignoradas durante o registro
local IgnoredFacets = {
  ["IDL:scs/core/IComponent:1.0"]     = true,
  ["IDL:scs/core/IReceptacles:1.0"]   = true,
  ["IDL:scs/core/IMetaInterface:1.0"] = true,
}

RSFacet = oop.class{}

---
--Registra uma nova oferta de servi�o. A oferta de servi�o � representada por
--uma tabela com os campos:
--   fProperties: lista de propriedades associadas � oferta (opcional)
--               cada propriedade a um par nome/valor (lista de strings)
--   fMember: refer�ncia para o membro que faz a oferta
--
--@param fProperties Lista de propriedades.
--@param fMember Componente a ser registrado.
--
--@return Identificador do servi�o ofertado.
--
--@exception InvalidMember Componente inv�lido.
--@exception InvalidProperties Propriedades inv�lidas.
--@exception UnauthorizedFacets Servi�o sem autoriza��o para publicar uma
--  ou mais facetas.
--@exception ServiceFailure Erro na execu��o do servi�o
---
function RSFacet:register(fProperties, fMember)
  if not fMember or fMember:_non_existent() then
    error(Openbus:getORB():newexcept{ InvalidMemberException })
  end
  local credential = Openbus:getInterceptedCredential()
  local properties = self:createPropertyIndex(fProperties, fMember)
  local facets = self:getAuthorizedFacets(fMember, credential, properties)

  local offerEntry = {
    offer = { fProperties = fProperties, fMember = fMember },
    properties = properties,
    facets = facets,
    credential = credential,
    identifier = self:generateIdentifier()
  }

  local orb = Openbus:getORB()
  for _, existentOfferEntry in pairs(self.offersByIdentifier) do
    if Utils.equalsOfferEntries(offerEntry, existentOfferEntry, orb) then
      -- oferta id�ntica a uma existente, n�o faz nada
      Log:debug(format(
          "A credencial {%s, %s, %s} tentou registrar uma oferta id�ntica � sua oferta de identificador %s",
          credential.identifier, credential.owner, credential.delegate,
          existentOfferEntry.identifier))
      return existentOfferEntry.identifier
    end
  end

  Log:debug(format(
      "A credencial {%s, %s, %s} registrou uma oferta com o identificador %s",
      credential.identifier, credential.owner, credential.delegate,
      offerEntry.identifier))

  self:addOffer(offerEntry)
  self.offersDB:insert(offerEntry)

  return offerEntry.identifier
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
    Log:debug(format(
        "A credencial {%s. %s, %s} est� tentando registrar sua primeira oferta",
            credential.identifier, credential.owner, credential.delegate))
    self.offersByCredential[credential.identifier] = {}
  end
  self.offersByCredential[credential.identifier][offerEntry.identifier] =
    offerEntry

  -- A credencial deve ser observada, porque se for deletada as
  -- ofertas a ela relacionadas devem ser removidas
  local orb = Openbus:getORB()
  local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle,
    orb, self.context.IComponent, "AccessControlServiceReceptacle",
    "IAccessControlService_" .. Utils.OB_VERSION,
    Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
  if status and acsFacet then
    acsFacet:addCredentialToObserver(self.observerId, credential.identifier)
    Log:debug(format("A credencial {%s, %s, %s} foi adicionada ao observador",
        credential.identifier, credential.owner, credential.delegate))
  else
    Log:warn(format(
        "N�o foi poss�vel adicionar a credencial {%s, %s, %s} ao observador",
        credential.identifier, credential.owner, credential.delegate))
  end
end

function RSFacet:updateMemberInfoInExistentOffer(existentOfferEntry, member)
  --Atencao, o identificador da credencial antiga � o que prevalece
  --por causa dos observadores
  existentOfferEntry.offer.fMember = member
  existentOfferEntry.properties = self:createPropertyIndex(
    existentOfferEntry.offer.fProperties, existentOfferEntry.offer.fMember)
  self.offersDB:update(existentOfferEntry)

  self.offersByCredential[existentOfferEntry.credential.identifier][existentOfferEntry.identifier] = existentOfferEntry
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
  if offerProperties == nil or type(offerProperties) ~= "table" then
    error(Openbus:getORB():newexcept{ InvalidPropertiesException })
  end
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

  --essa propriedade � usada pelo FT na sincronizacao das ofertas
  --ela representa quando uma oferta foi inserida ou modificada
  properties["modified"] = {}
  properties["modified"][tostring(socket.gettime()*1000)] = true

  return properties
end

---
-- Cria um �ndice com as facetas autorizadas do membro.
--
-- @param credential Credencial do membro.
-- @param offer Oferta enviada pelo membro.
-- @param properties Propriedades indexadas da oferta.
--
-- @return �ndice de facetas autorizadas.
--
-- @exception UnauthorizedFacets Cont�m a lista com uma ou
--   mais facetas que o membro n�o tem autoriza��o.
--
function RSFacet:getAuthorizedFacets(member, credential, properties)
  local succ, facets, memberFacets, count
  local metaInterface = member:getFacetByName("IMetaInterface")
  if not metaInterface then
    Log:error(format("O componente %s:%d.%d.%d da credencial {%s, %s, %s} n�o oferece uma faceta do tipo %s"),
        properties.component_id.name, properties.component_id.major_version,
        properties.component_id.minor_version,
        properties.component_id.patch_version,credential.identifier,
        credential.owner, credential.delegate, Utils.METAINTERFACE_INTERFACE)
    error(Openbus:getORB():newexcept{ InvalidMemberException })
    return {}
  end

  local orb = Openbus:getORB()
  metaInterface = orb:narrow(metaInterface, "IDL:scs/core/IMetaInterface:1.0")
  memberFacets = metaInterface:getFacets()
  succ, facets, count = self:createFacetIndex(credential.owner, memberFacets)
  if succ then
    Log:debug(format(
        "A credencial {%s, %s, %s} est� registrando o componente %s com %d interface(s) autorizada(s)",
        credential.identifier, credential.owner, credential.delegate,
        properties.component_id.name, count))
  else
    Log:error(format("A credencial {%s, %s, %s} tentou registrar o componente %s com %d interface(s) n�o autorizada(s)",
        credential.identifier, credential.owner, credential.delegate,
        properties.component_id.name, count))
    local unathorizedFacets = {}
    for facet in pairs(facets) do
      unathorizedFacets[#unathorizedFacets+1] = facet
    end
    error(Openbus:getORB():newexcept { UnauthorizedFacetsException,
      fFacets = unathorizedFacets,
    })
  end

  return facets
end

---
-- Verifica se as facetas do membro est�o autorizadas no management.
--
-- @param owner Dono da credencial.
-- @param allFacets Array de facetas do membro.
--
-- @return Em caso de sucesso, retorna true, o �ndice de facetas
-- dispon�veis do membro e o n�mero de facetas no �ndice.
-- No caso de falta de autoriza��o, retorna false, um �ndice de
-- facetas n�o autorizadas e o n�mero de facetas no �ndice
--
function RSFacet:createFacetIndex(owner, allFacets)
  local facetsByName = {}
  local count = 0
  local facets = {}
  local invalidCount = 0
  local invalidFacets = {}
  local mgm = self.context.IManagement
  -- Inverte o �ndice para facilitar a busca
  for _, facet in ipairs(allFacets) do
    facetsByName[facet.name] = facet
  end
  -- Verifica as autoriza��es
  for _, facet in pairs(facetsByName) do
    local interfaceName = facet.interface_name
    if not IgnoredFacets[interfaceName] then
      if not mgm:hasAuthorization(owner, interfaceName) then
        invalidFacets[interfaceName] = true
        invalidCount = invalidCount + 1
      elseif invalidCount == 0 then
        facets[facet.name] = "name"
        facets[facet.interface_name] = "interface_name"
        count = count + 1
      end
     end
  end
  if invalidCount == 0 then
    return true, facets, count
  end
  return false, invalidFacets, invalidCount
end

---
--Remove uma oferta de servi�o.
--
--@param identifier A identifica��o da oferta de servi�o.
--
--@exception ServiceOfferDoesNotExist Erro na execu��o do servi�o
--@exception ServiceFailure Erro na execu��o do servi�o
---
function RSFacet:unregister(identifier)
  local credential = Openbus:getInterceptedCredential()
  self:rawUnregister(identifier, credential)
  
  if credential.owner == "RegistryService" or
    credential.delegate == "RegistryService" then
    return
  end
  
  local ftFacet = self.context.IFaultTolerantService
  if not ftFacet:isFTInited() then
    return
  end

  if #ftFacet.ftconfig.hosts.RS <= 1 then
    Log:debug(format(
        "N�o existem r�plicas cadastradas para desfazer o registro da oferta %s",
        identifier))
    return
  end

  local i = 1
  repeat
  if ftFacet.ftconfig.hosts.RS[i] ~= ftFacet.rsReference then
    local ret, succ, remoteRGS = oil.pcall(Utils.fetchService,
      Openbus:getORB(), ftFacet.ftconfig.hosts.RS[i],
      Utils.REGISTRY_SERVICE_INTERFACE)
    if ret and succ then
      --encontrou outra replica
      Log:debug(format("Requisitou unregister na r�plica %s",
          ftFacet.ftconfig.hosts.RS[i]))
      -- Recupera faceta IRegistryService da replica remota
      local orb = Openbus:getORB()
      local remoteRGSIC = remoteRGS:_component()
      remoteRGSIC = orb:narrow(remoteRGSIC, "IDL:scs/core/IComponent:1.0")
      local ok, remoteRGSFacet = oil.pcall(remoteRGSIC.getFacetByName,
          remoteRGSIC, "IRegistryService_" .. Utils.OB_VERSION)
      if ok and remoteRGSFacet then
        remoteRGSFacet = orb:narrow(remoteRGSFacet,
          Utils.REGISTRY_SERVICE_INTERFACE)
          oil.newthread(function()
              local succ, err = oil.pcall(
                remoteRGSFacet.unregister, remoteRGSFacet,
                identifier)
              end)
      else
        Log:warn(format("A r�plica %s n�o foi encontrada",
            ftFacet.ftconfig.hosts.RS[i]))
      end -- fim ok facet IRegistryService
    end -- fim succ, encontrou replica
  end -- fim , nao eh a mesma replica
  i = i + 1
  until i > #ftFacet.ftconfig.hosts.RS
end

---
--M�todo interno respons�vel por efetivamente remover uma oferta de servi�o.
--
--@param identifier A identifica��o da oferta de servi�o.
--@param credential Credencial do membro que efetuou o registro ou
--  nil se for uma remo��o for�ada pelo administrador do barramento.
--
--@exception ServiceOfferDoesNotExist Erro na execu��o do servi�o
--@exception ServiceFailure Erro na execu��o do servi�o
---
function RSFacet:rawUnregister(identifier, credential)
  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warn(format("A oferta %s n�o pode ser removida porque n�o foi encontrada",
        identifier))
    error(Openbus:getORB():newexcept { ServiceOfferDoesNotExistException })
  end
  if credential then
    if credential.identifier ~= offerEntry.credential.identifier then
      local message = format("A oferta %s n�o pode ser removida porque n�o foi registrada pela credencial {%s, %s, %s}",
          identifier, credential.identifier, credential.owner,
          credential.delegate)
      Log:warn(message)
      error(Openbus:getORB():newexcept { ServiceFailureException, 
        fMessage = message})
    end
  else
    credential = offerEntry.credential
  end
  Log:debug(format("Removendo a oferta %s da credencial {%s, %s, %s}",
      identifier, credential.identifier, credential.owner, credential.delegate))

  -- Remove oferta do �ndice por identificador
  self.offersByIdentifier[identifier] = nil

  -- Remove oferta do �ndice por credencial
  local credentialOffers = self.offersByCredential[credential.identifier]
  if credentialOffers then
    credentialOffers[identifier] = nil
  else
    Log:debug(format("A credencial {%s, %s, %s} n�o possui ofertas de servi�o",
        credential.identifier, credential.owner, credential.delegate))
    return
  end

  if not next (credentialOffers) then
    -- N�o h� mais ofertas associadas � credencial
    local orb = Openbus:getORB()
    self.offersByCredential[credential.identifier] = nil
    Log:debug(format("A �ltima oferta da credencial {%s, %s, %s} foi removida e, por isso, ser� removida da lista do observador",
        credential.identifier, credential.owner, credential.delegate))
    local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle,
      orb, self.context.IComponent, "AccessControlServiceReceptacle",
      "IAccessControlService_" .. Utils.OB_VERSION, Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
    if status and acsFacet then
      acsFacet:removeCredentialFromObserver(self.observerId,
        credential.identifier)
    else
      -- erro ja foi logado, so adiciona que nao pode remover
      Log:error("N�o foi poss�vel remover credencial")
    end
  end

  self.offersDB:delete(offerEntry)
  Log:debug(format("A oferta %s da credencial {%s, %s, %s} foi removida",
      identifier, credential.identifier, credential.owner, credential.delegate))
end

---
--Atualiza a oferta de servi�o associada ao identificador especificado. Apenas
--as propriedades da oferta podem ser atualizadas (nessa vers�o, substituidas).
--
--@param identifier O identificador da oferta.
--@param properties As novas propriedades da oferta.
--
--@exception InvalidProperties Propriedades inv�lidas.
--@exception ServiceOfferDoesNotExist O membro n�o possui nenhuma oferta
--relacionada com o identificador informado.
--@exception ServiceFailure Erro na execu��o do servi�o
---
function RSFacet:setOfferProperties(identifier, properties)
  Log:debug(format("Iniciando a atualizando da oferta %s", identifier))
  if properties == nil or type(properties) ~= "table" then
    error(Openbus:getORB():newexcept{ InvalidPropertiesException })
  end
  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warn(format("A oferta %s n�o foi encontrada e, por isso, n�o pode ser atualizada",
        identifier))
    error(Openbus:getORB():newexcept { ServiceOfferDoesNotExistException })
  end

  local credential = Openbus:getInterceptedCredential()
  if credential.identifier ~= offerEntry.credential.identifier then
    local msg = format("A oferta %s n�o foi registrada pela credencial {%s, %s, %s} e, por isso, n�o pode ser atualizada",
      identifier, credential.identifier, credential.owner, credential.delegate)
    Log:warn(msg)
    error(Openbus:getORB():newexcept { ServiceFailureException, fMessage = msg})
  end

  local indexedProperties = self:createPropertyIndex(properties,
    offerEntry.offer.fMember)

  -- Atualiza as propriedades da oferta de servi�o
  local succ, facets = oil.pcall(self.getAuthorizedFacets, self, 
    offerEntry.offer.fMember, credential, indexedProperties)
  if not succ then
    if facets[1] == UnauthorizedFacetsException then
      local msg = "M�todo RSFacet:setOfferProperties n�o deveria lan�ar exce��o UnauthorizedFacets"
      Log:error(msg)
      error(Openbus:getORB():newexcept { ServiceFailureException, fMessage = msg})
    else
      -- relan�a o erro
      error(facets)
    end
  end
  offerEntry.facets = facets
  offerEntry.offer.fProperties = properties
  offerEntry.properties = indexedProperties
  self.offersDB:update(offerEntry)
end

---
--Busca por ofertas de servi�o que implementam as facetas descritas.
--Se nenhuma faceta for fornecida, todas as facetas s�o retornadas.
--
--@param facets As facetas da busca.
--
--@return As ofertas de servi�o que foram encontradas.
--
--@exception ServiceFailure Erro na execu��o do servi�o
---
function RSFacet:find(facets)
  local ftFacet = self.context.IFaultTolerantService

  local params = { facets = facets, criteria = {} }
  --troca credenciais para verificacao de permissao na faceta FT
  local intCredential = Openbus:getInterceptedCredential()
  Openbus.serverInterceptor.picurrent:setValue(Openbus:getCredential())
  ftFacet:updateStatus(params)
  --desfaz a troca
  Openbus.serverInterceptor.picurrent:setValue(intCredential)

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
    Log:debug(format("Foram encontradas %d ofertas com as facetas especificadas",
        #selectedOffers))
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
--
--@exception ServiceFailure Erro na execu��o do servi�o
---
function RSFacet:findByCriteria(facets, criteria)
  local ftFacet = self.context.IFaultTolerantService

  local params = { facets = facets, criteria = criteria}
  --troca credenciais para verificacao de permissao na faceta FT
  local intCredential = Openbus:getInterceptedCredential()
  Openbus.serverInterceptor.picurrent:setValue(Openbus:getCredential())
  ftFacet:updateStatus(params)
  --desfaz a troca
  Openbus.serverInterceptor.picurrent:setValue(intCredential)

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
          Log:debug(format(
              "Foram encontrados %d servi�os com os crit�rios especificados",
              #selectedOffers))
        else
          Log:debug(
              "N�o foram encontrados servi�os com os crit�rios especificados")
        end
      end
    end
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
--
--@exception ServiceFailure Erro na execu��o do servi�o
---
function RSFacet:localFind(facets, criteria)
  Log:debug("Procurando por ofertas de servi�o na r�plica local")
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
      selectedOffersEntries[i].authorizedFacets =
        Utils.marshalHashFacets(offerEntry.facets)
      i = i + 1
    end
    Log:debug(format(
        "Foram encontradas %d ofertas com os crit�rios especificados",
        #selectedOffersEntries))
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
        selectedOffersEntries[i].authorizedFacets =
          Utils.marshalHashFacets(offerEntry.facets)
        i = i + 1
      end
    end
    Log:debug(format(
        "Foram encontradas %d ofertas com os crit�rios especificados",
        #selectedOffersEntries))
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
          selectedOffersEntries[i].authorizedFacets =
            Utils.marshalHashFacets(offerEntry.facets)
          i = i + 1
        end
      end
    end
    Log:debug(format(
        "Foram encontradas %d ofertas com os crit�rios especificados",
        #selectedOffersEntries))
  end

  for k,offerEntry in pairs(selectedOffersEntries) do
    selectedOffersEntries[k].properties = Utils.convertToSendIndexedProperties( offerEntry.properties )
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
  Log:debug(format(
      "A credencial {%s, %s, %s} foi invalidada; removendo suas ofertas",
      credential.identifier, credential.owner, credential.delegate))
  local credentialOffers = self.offersByCredential[credential.identifier]
  self.offersByCredential[credential.identifier] = nil

  if credentialOffers then
    for identifier, offerEntry in pairs(credentialOffers) do
      self.offersByIdentifier[identifier] = nil
      local succ, msg = self.offersDB:delete(offerEntry)
      if not succ then
        Log:error(format("N�o foi poss�vel remover a oferta %s: %s",
            identifier, tostring(msg)))
      end
    end
  else
    Log:debug(format("A credencial {%s, %s, %s} n�o possui ofertas",
        credential.identifier, credential.owner, credential.delegate))
  end
end

---
--Procedimento ap�s reconex�o do servi�o.
---
function RSFacet:expired()
  Log:debug("A credencial do servi�o de registro expirou")
  Openbus:connectByCertificate(self.context._componentId.name,
    self.privateKeyFile, self.accessControlServiceCertificateFile)

  if not Openbus:isConnected() then
    Log:error("N�o foi poss�vel reconectar ao servi�o de controle de acesso")
    return false
  end

  local acsFacet = Openbus:getAccessControlService()
  -- atualiza a refer�ncia junto ao servi�o de controle de acesso
  -- conecta-se com o controle de acesso:   [ACS]--( 0--[RS]
  local acsIComp = Openbus:getACSIComponent()
  local acsIRecep =  acsIComp:getFacetByName("IReceptacles")
  local orb = Openbus:getORB()
  acsIRecep = orb:narrow(acsIRecep, "IDL:scs/core/IReceptacles:1.0")
  local status, conns = oil.pcall(acsIRecep.connect, acsIRecep,
    "RegistryServiceReceptacle", self.context.IComponent )
  if not status then
    Log:error("Falha ao conectar o servi�o de Registro no recept�culo: " ..
      conns[1])
    return false
  end

  -- registra novamente o observador de credenciais
  self.observerId = acsFacet:addObserver(self.observer, {})
  Log:debug(format("O observador de credenciais %s foi recadastrado",
      self.observerId))

  -- Mant�m no reposit�rio apenas ofertas com credenciais v�lidas
  local offerEntries = self.offersByIdentifier
  local credentials = {}
  for _, offerEntry in pairs(offerEntries) do
    credentials[offerEntry.credential.identifier] = offerEntry.credential
  end
  local invalidCredentials = {}
  for credentialId, credential in pairs(credentials) do
    if not acsFacet:addCredentialToObserver(self.observerId, credentialId) then
      Log:debug(format("As ofertas da credential {%s, %s, %s} ser�o removidas",
          credential.identifier, credential.owner, credential.delegate))
      table.insert(invalidCredentials, credential)
    else
      Log:debug(format("As ofertas da credencial {%s, %s, %s} ser�o mantidas",
          credential.identifer, credential.owner, credential.delegate))
    end
  end
  for _, credential in ipairs(invalidCredentials) do
    self:credentialWasDeleted(credential)
  end

  Log:info("O servi�o de registro foi reconectado")
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
-- Faceta IReceptacle
--------------------------------------------------------------------------------

RGSReceptacleFacet = oop.class({}, AdaptiveReceptacle.AdaptiveReceptacleFacet)

function RGSReceptacleFacet:getConnections(receptacle)
  --TODO: Generalizar esse m�todo para o ACS e RGS porem dentro do Openbus (Maira)
  --troca credenciais para verificacao de permissao no disconnect
  local intCredential = Openbus:getInterceptedCredential()
  Openbus.serverInterceptor.picurrent:setValue(Openbus:getCredential())
  local conns = AdaptiveReceptacle.AdaptiveReceptacleFacet.getConnections(self, receptacle)
  --desfaz a troca
  Openbus.serverInterceptor.picurrent:setValue(intCredential)
  return conns
end

function RGSReceptacleFacet:connect(receptacle, object)
 self.context.IManagement:checkPermission()
 local connId = AdaptiveReceptacle.AdaptiveReceptacleFacet.connect(self,
                          receptacle,
                          object) -- calling inherited method
  if connId then
    --SINCRONIZA COM AS REPLICAS SOMENTE SE CONECTOU COM SUCESSO
    self:updateConnectionState("connect", { receptacle = receptacle, object = object })
  end
  return connId
end

function RGSReceptacleFacet:disconnect(connId)
  self.context.IManagement:checkPermission()
  -- calling inherited method
  local status = oil.pcall(AdaptiveReceptacle.AdaptiveReceptacleFacet.disconnect, self, connId)
  if status then
      self:updateConnectionState("disconnect", { connId = connId })
  else
      Log:error("[disconnect] N�o foi poss�vel desconectar receptaculo.")
  end
end

function RGSReceptacleFacet:updateConnectionState(command, data)
    local credential = Openbus:getInterceptedCredential()
    if credential then
       if credential.owner == "RegistryService" or
          credential.delegate == "RegistryService" then
          --para nao entrar em loop
            return
       end
    end

    local ftFacet = self.context.IFaultTolerantService
    if not ftFacet:isFTInited() then
      return
    end

    if # ftFacet.ftconfig.hosts.RS <= 1 then
       Log:debug(format(
        "N�o existem r�plicas cadastradas para atualizar o estado do recept�culo para o comando %s",
        command))
      return
    end

    local i = 1
    local orb = Openbus:getORB()
    repeat
        if ftFacet.ftconfig.hosts.RS[i] ~= ftFacet.rsReference then
            local ret, succ, remoteRS = oil.pcall(Utils.fetchService,
                                                orb,
                                                ftFacet.ftconfig.hosts.RS[i],
                                                Utils.REGISTRY_SERVICE_INTERFACE)

            if ret and succ then
            --encontrou outra replica
              Log:debug(format(
                  "Requisitou comando %s no recept�culo da r�plica %s",
                  command, ftFacet.ftconfig.hosts.RS[i]))
                local remoteRSIC = remoteRS:_component()
                remoteRSIC = orb:narrow(remoteRSIC,"IDL:scs/core/IComponent:1.0")
                 -- Recupera faceta IReceptacles da replica remota
                local ok, remoteRSRecepFacet =  oil.pcall(remoteRSIC.getFacetByName, remoteRSIC, "IReceptacles")
                if ok then
                     remoteRSRecepFacet = orb:narrow(remoteRSRecepFacet,
                           "IDL:scs/core/IReceptacles:1.0")
                     if command == "connect" then
                         oil.newthread(function()
                                    local succ, ret = oil.pcall(remoteRSRecepFacet.connect, remoteRSRecepFacet, data.receptacle, data.object)
                                    end)
                     elseif command == "disconnect" then
                         oil.newthread(function()
                                    local succ, ret = oil.pcall(remoteRSRecepFacet.disconnect, remoteRSRecepFacet, data.connId)
                                    end)
                     end
                end
            else
              Log:error(format(
            "A r�plica %s n�o est� dispon�vel para ser atualizada quanto ao estado do recept�culo para o comando %s",
            ftFacet.ftconfig.hosts.RS[i], command))
            end
        end
        i = i + 1
    until i > # ftFacet.ftconfig.hosts.RS
end
--------------------------------------------------------------------------------
-- Faceta IFaultTolerantService
--------------------------------------------------------------------------------

FaultToleranceFacet = FaultTolerantService.FaultToleranceFacet
FaultToleranceFacet.ftconfig = {}
FaultToleranceFacet.rsReference = ""

function FaultToleranceFacet:init()
  local loadConfig, err = loadfile(DATA_DIR .."/conf/RSFaultToleranceConfiguration.lua")
  if not loadConfig then
    Log:error("O arquivo 'RSFaultToleranceConfiguration' n�o pode ser " ..
        "carregado ou n�o existe.",err)
    os.exit(1)
  end
  setfenv(loadConfig,self);
  loadConfig()

  local rgs = self.context.IRegistryService
  local notInHostAdd = rgs.config.registryServerHostName .. ":"
    .. tostring(rgs.config.registryServerHostPort)

  self.rsReference = "corbaloc::" .. notInHostAdd .. "/"
    .. Utils.REGISTRY_SERVICE_KEY
end

function FaultToleranceFacet:updateStatus(params)
  -- O atributo  _anyval so retorna  em chamadas remotas,  em chamadas
  -- locais (mesmo processo)  deve-se acessar o parametro diretamente.
  -- Al�m disso,  passar uma tabela no any tbm  so funciona porque �
  -- local se  fosse uma  chamada remota teria  q ter uma  struct pois
  -- sen�o da problema de marshall
  local input
  if not params._anyval then
    input = params
  else
    --chamada remota
    input = params._anyval

    --A permissao so eh verificada em chamadas remotas
    self.context.IManagement:checkPermission()
  end

  local facets = {}
  local criteria = {}

  if input ~= "all" then
    facets = input.facets
    criteria = input.criteria
  end

  --Atualiza estado das ofertas
  if not self.ftConfig then
    return false
  end

  if #self.ftconfig.hosts.RS <= 1 then
    Log:debug("N�o existem r�plicas cadastradas para atualizar o estado das ofertas de servi�o")
    return false
  end


  return self:updateOffersStatus(facets, criteria)
end

function FaultToleranceFacet:updateOffersStatus(facets, criteria)
  Log:debug(format(
      "Sincronizando a base de ofertas de servi�o com as replicas exceto %s",
      self.rsReference))
  local rgs = self.context.IRegistryService
  local updated = false
  local i = 1
  local count = 0
  local orb = Openbus:getORB()
  repeat
    if self.ftconfig.hosts.RS[i] ~= self.rsReference then
      local ret, succ, remoteRS = oil.pcall(Utils.fetchService,
        orb, self.ftconfig.hosts.RS[i],
        Utils.REGISTRY_SERVICE_INTERFACE)

      if ret and succ then
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
            addOfferEntry.facets =
              Utils.unmarshalHashFacets(offerEntryFound.authorizedFacets)

            --Recupera o indice das propriedades inseridas pelo RGS
            addOfferEntry.properties =
              Utils.convertToReceiveIndexedProperties(offerEntryFound.properties)
            --Refazendo indice das propriedades
            for _, property in ipairs(addOfferEntry.offer.fProperties) do
              if not addOfferEntry.properties[property.name] then
                addOfferEntry.properties[property.name] = {}
              end
              for _, val in ipairs(property.value) do
                  addOfferEntry.properties[property.name][val] = true
              end
            end

            -- verifica se ja existem localmente
            for _, offerEntry in pairs(rgs.offersByIdentifier) do
              --se ja existir, nao adiciona
              local sameOfferDescription =
                    Utils.equalsOfferEntries(addOfferEntry, offerEntry, orb)
              if addOfferEntry.identifier == offerEntry.identifier and
                 sameOfferDescription then
              --Existe entrada completa igual, nao insere
                insert = false
                break
              elseif addOfferEntry.identifier == offerEntry.identifier
                     and not sameOfferDescription then
                  -- J� existe uma oferta diferente com o mesmo id,
                  -- atualiza a oferta mantendo o id somente se foi
                  -- modificada depois que a que est� localmente
                  for field, value in pairs(addOfferEntry.properties.modified) do
                    if tonumber(field) > socket.gettime()*1000 then
                      --oferta � mais nova que a atual
                      insert = false
                      self.offersDB:update(addOfferEntry)
                      updated = true
                      count = count + 1
                      break
                    end
                  end
              end
            end
            if insert then
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
  until i > #self.ftconfig.hosts.RS
  if updated then
    Log:debug(format("Foram obtidas %d ofertas de servi�o", count))
  end
  return updated
end

function FaultToleranceFacet:isFTInited()
  if not self.ftconfig then
    Log:error("A faceta de toler�ncia a falhas n�o foi inicializada corretamente")
    return false
  end
  return true
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
  local mgm = self.context.IManagement
  local rs = self.context.IRegistryService
  local config = rs.config
  self.context.IFaultTolerantService:init()

  -- Verifica se � o primeiro startup
  if not rs.initialized then
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
    Log:debug("O servi�o de registro j� foi inicializado anteriormente")
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
  Openbus:setLeaseExpiredCallback( rs )

  -- obt�m a refer�ncia para o servi�o de Controle de Acesso
  local accessControlService = Openbus:getAccessControlService()

  local acsIComp = Openbus:getACSIComponent()

  -- registra um observador de credenciais
  local observer = {
    registryService = rs,
      credentialWasDeleted = function(self, credential)
        Log:debug(format(
            "O observador foi notificado de que a credencial foi removida",
            credential.identifier, credential.owner, credential.delegate))
        self.registryService:credentialWasDeleted(credential)
      end
  }
  local orb = Openbus:getORB()
  rs.observer = orb:newservant(observer, "RegistryServiceCredentialObserver",
    Utils.CREDENTIAL_OBSERVER_INTERFACE)
  rs.observerId = accessControlService:addObserver(rs.observer, {})
  Log:debug(
      format("O observador de credenciais foi cadastrado com o identificador %s",
      rs.observerId))

  -- recupera ofertas persistidas
  Log:info("Recuperando ofertas de servi�o persistidas")
  local offerEntriesDB = rs.offersDB:retrieveAll()
  for _, offerEntry in pairs(offerEntriesDB) do
    -- somente recupera ofertas de credenciais v�lidas
    if accessControlService:isValid(offerEntry.credential) then
      rs:addOffer(offerEntry)
    else
      Log:debug(format("A oferta %s foi descartada porque a credencial {%s, %s, %s} n�o � mais v�lida",
          offerEntry.identifier, offerEntry.credential.identifier,
          offerEntry.credential.owner, offerEntry.credential.delegate))
      rs.offersDB:delete(offerEntry)
    end
  end

  -- Refer�ncia � faceta de gerenciamento do ACS
  mgm.acsmgm = acsIComp:getFacetByName("IManagement_" .. Utils.OB_VERSION)
  mgm.acsmgm = orb:narrow(mgm.acsmgm, Utils.MANAGEMENT_ACS_INTERFACE)
  mgm.acsmgm = orb:newproxy(mgm.acsmgm, "protected")
  -- Administradores dos servi�os
  mgm.admins = {}
  for _, name in ipairs(config.administrators) do
    mgm.admins[name] = true
  end
  -- ACS, RGS e monitor s�o sempre administradores
  mgm.admins.AccessControlService = true
  mgm.admins.RegistryService = true
  mgm.admins.RGSMonitor = true

  -- Inicializa a base de gerenciamento
  mgm.authDB = TableDB(DATA_DIR.."/rs_auth.db")
  mgm.ifaceDB = TableDB(DATA_DIR.."/rs_iface.db")
  mgm:loadData()

  rs.started = true

  -- conecta-se com o controle de acesso:   [ACS]--( 0--[RS]
  local acsIRecep =  acsIComp:getFacetByName("IReceptacles")
  acsIRecep = orb:narrow(acsIRecep, "IDL:scs/core/IReceptacles:1.0")
  local status, conns = oil.pcall(acsIRecep.connect, acsIRecep,
    "RegistryServiceReceptacle", self.context.IComponent )
  if not status then
    Log:error("Falha ao conectar o servi�o de Registro no recept�culo: " ..
      conns[1])
    return false
  end
end

---
--Finaliza o servi�o.
--
--@see scs.core.IComponent#shutdown
---
function shutdown(self)
  local rs = self.context.IRegistryService
  if not rs.started then
    Log:error("Servico ja foi finalizado.")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  rs.started = false

  -- Remove o observador
  local orb = Openbus:getORB()
  if rs.observerId then
    local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle,
      orb, self.context.IComponent, "AccessControlServiceReceptacle",
      "IAccessControlService_" .. Utils.OB_VERSION, Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
    if not status or not acsFacet then
      -- erro ja foi logado
      error{"IDL:SCS/ShutdownFailed:1.0"}
    end
    acsFacet:removeObserver(rs.observerId)
    rs.observer:_deactivate()
  end

  if Openbus:isConnected() then
    Openbus:disconnect()
  end

  Log:info("O servi�o de registro foi finalizado")

  orb:deactivate(rs)
  orb:deactivate(self.context.IManagement)
  orb:deactivate(self.context.IFaultTolerantService)
  orb:deactivate(self.context.IComponent)
  --Mata as threads de valida��o de credencial e de atualiza��o do estado
  --e chama o finish que por sua vez mata o orb
  Openbus:destroy()
end

--------------------------------------------------------------------------------
-- Faceta IManagement
--------------------------------------------------------------------------------

-- Aliases
local InvalidRegularExpressionException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/registry_service/InvalidRegularExpression:1.0"
local InterfaceInUseException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/registry_service/InterfaceInUse:1.0"
local InterfaceDoesNotExistException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/registry_service/InterfaceDoesNotExist:1.0"
local InterfaceAlreadyExistsException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/registry_service/InterfaceAlreadyExists:1.0"
local UserDoesNotExistException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/access_control_service/UserDoesNotExist:1.0"
local EntityDoesNotExistException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/registry_service/EntityDoesNotExist:1.0"
local SystemDeploymentDoesNotExistException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/access_control_service/SystemDeploymentDoesNotExist:1.0"
local AuthorizationDoesNotExistException = "IDL:tecgraf/openbus/core/"..
    Utils.OB_VERSION.."/registry_service/AuthorizationDoesNotExist:1.0"

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
      succ, err = self.acsmgm:getSystemDeployment(auth.id)
    else -- type == "ATUser"
      succ, err = self.acsmgm:getUser(auth.id)
    end
    if succ then
      self.authorizations[auth.id] = auth
    else
      if err[1] == SystemDeploymentDoesNotExistException or
         err[1] == UserDoesNotExistException
      then
        remove[auth] = true
        Log:warn(format("Removendo autoriza��es de '%s': " ..
         "removido do servi�o de Controle de Acesso.", auth.id))
      else
        error(err) -- Exce��o desconhecida, repassando
      end
    end
  end
  for auth in pairs(remove) do
    self.authDB:remove(auth.id)
    self:updateManagementStatus("removeAuthorization", {id = auth.id})
  end
end

---
-- Cadastra um identificador de interface aceito pelo servi�o de Registro.
--
-- @param ifaceId Identificador de interface.
--
function ManagementFacet:addInterfaceIdentifier(ifaceId)
  self:checkPermission()
  if self.interfaces[ifaceId] then
    Log:info(format("Interface '%s' j� cadastrada.", ifaceId))
    error{InterfaceAlreadyExistsException}
  end
  self.interfaces[ifaceId] = true
  local succ, msg = self.ifaceDB:save(ifaceId, ifaceId)
  if not succ then
    Log:error(format("Falha ao salvar a interface '%s': %s",
      ifaceId, tostring(msg)))
  else
    self:updateManagementStatus("addInterfaceIdentifier", {ifaceId = ifaceId})
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
    Log:info(format("Interface '%s' n�o est� cadastrada.", ifaceId))
    error{InterfaceDoesNotExistException}
  end
  for _, auth in pairs(self.authorizations) do
    if auth.authorized[ifaceId] == "strict" then
      Log:info(format("Interface '%s' em uso.", ifaceId))
      error{InterfaceInUseException}
    end
  end
  self.interfaces[ifaceId] = nil
  local succ, msg = self.ifaceDB:remove(ifaceId)
  if not succ then
    Log:error(format("Falha ao remover interface '%s': %s", iface, tostring(msg)))
  else
    self:updateManagementStatus("removeInterfaceIdentifier",
      { ifaceId = ifaceId })
  end
end

---
-- Recupera todos os identificadores de interface cadastrados.
--
-- @return Sequ�ncia de identificadores de interface.
--
function ManagementFacet:getInterfaceIdentifiers()
  local array = {}
  for iface in pairs(self.interfaces) do
    array[#array+1] = iface
  end
  return array
end

---
-- Autoriza o membro a exportar a interface.  O servi�o de Acesso
-- � consultado para verificar se o membro est�cadastrado.
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
      Log:info(format("Express�o regular inv�lida: '%s'", ifaceId))
      error{InvalidRegularExpressionException}
    end
  elseif strict and not self.interfaces[ifaceId] then
    Log:info(format("Interface '%s' n�o cadastrada.", ifaceId))
    error{InterfaceDoesNotExistException}
  end
  local auth = self.authorizations[id]
  if not auth then
    -- Cria uma nova autoriza��o: verificar junto ao ACS se o membro existe
    local type = "ATSystemDeployment"
    local succ, member = self.acsmgm:getSystemDeployment(id)
    if not succ then
      if member[1] ~= SystemDeploymentDoesNotExistException then
        error(member)  -- Exce��o desconhecida, repassando
      end
      type = "ATUser"
      succ, member = self.acsmgm:getUser(id)
      if not succ then
        if member[1] ~= UserDoesNotExistException then
          error(member)  -- Exce��o desconhecida, repassando
        end
        Log:info(format("Membro '%s' n�o cadastrado.", id))
        error{EntityDoesNotExistException}
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
    Log:error(format("Falha ao salvar autoriza��o '%s': %s", id, tostring(msg)))
  else
     self:updateManagementStatus("grant", { id = id, ifaceId = ifaceId, strict = strict})
  end
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
    Log:info(format("N�o h� autoriza��o para '%s'.", id))
    error{AuthorizationDoesNotExistException}
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
    Log:error(format("Falha ao remover autoriza��o  '%s': %s", id, tostring(msg)))
  else
    self:updateManagementStatus("revoke", { id = id, ifaceId = ifaceId})
  end
end

---
-- Remove a autoriza��o do membro.
--
-- @param id Identificador do membro.
--
function ManagementFacet:removeAuthorization(id)
  self:checkPermission()
  if not self.authorizations[id] then
    Log:info(format("N�o h� autoriza��o  para '%s'.", id))
    error{AuthorizationDoesNotExistException}
  end
  self.authorizations[id] = nil
  local succ, msg = self.authDB:remove(id)
  if not succ then
    Log:error(format("Falha ao remover autoriza��o '%s': %s", id, tostring(msg)))
  else
    self:updateManagementStatus("removeAuthorization", { id = id})
  end
end

---
-- Duplica a autoriza��o , mas a lista de interfaces � retornada
-- como array e n�o como hash. Essa fun��o � usada para exportar
-- a autoriza��o'.
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
-- Verifica se o membro � autorizado a exportar uma determinada interface.
--
-- @param id Identificador do membro.
-- @param iface Interface a ser consultada (repID).
--
-- @return true se � autorizada, false caso contr�rio.
--
function ManagementFacet:hasAuthorization(id, iface)
  local auth = self.authorizations[id]
  if not auth then
    return false
  end
  if auth.authorized[iface] then
    return true
  end

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
    Log:info(format("N�o h� autoriza��o para '%s'.", id))
    error{AuthorizationDoesNotExistException}
  end
  return self:copyAuthorization(auth)
end

---
-- Recupera todas as autoriza��es cadastradas.
--
-- @return Sequ�ncia de autoriza��es
--
function ManagementFacet:getAuthorizations()
  local array = {}
  for _, auth in pairs(self.authorizations) do
    array[#array+1] = self:copyAuthorization(auth)
  end
  return array
end

---
-- Recupera as autoriza��es  que cont�m \e todas as interfaces
-- fornecidas em seu conjunto de interfaces autorizadas.
--
-- @param ifaceIds Sequ�ncia de identifidores de interface.
--
-- @return Sequ�ncia de autoriza��es.
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

---
-- Recupera do registro a lista de todas interfaces oferecidas.
--
-- @return Array com as ofertas.
--
function ManagementFacet:getOfferedInterfaces()
  self:checkPermission()
  local array = {}
  local offers = self.context.IRegistryService.offersByIdentifier
  for id, offer in pairs(offers) do
    local ifaces = {}
    for facet, type in pairs(offer.facets) do
      if type == "interface_name" then
        ifaces[#ifaces+1] = facet
      end
    end

    if #ifaces > 0 then
      array[#array+1] = {
        id = id,
        member = offer.credential.owner,
        interfaces = ifaces,
        registrationDate = offer.registrationDate,
      }
    end
  end
  return array
end

---
-- Recupera do registro a lista de interfaces oferecidas por um dado membro.
--
-- @param member Identificador do membro do barramento.
--
-- @return Array contendo as intefaces oferecidas
--
function ManagementFacet:getOfferedInterfacesByMember(member)
  self:checkPermission()
  local array = {}
  local ifaces = {}
  local offers = self.context.IRegistryService.offersByIdentifier

  for id, offer in pairs(offers) do
    if offer.credential.owner == member then
      local ifaces = {}
      for facet, type in pairs(offer.facets) do
        if type == "interface_name" then
          ifaces[#ifaces+1] = facet
        end
      end
      if #ifaces > 0 then
        array[#array+1] = {
          id = id,
          member = offer.credential.owner,
          interfaces = ifaces,
          registrationDate = offer.registrationDate
        }
      end
    end
  end
  return array
end

---
-- Remove do registro a oferta identificada.
--
-- @param id Identificador da oferta no registro.
--
function ManagementFacet:unregister(id)
  self:checkPermission()
  return self.context.IRegistryService:rawUnregister(id)
end

---
--
--
function ManagementFacet:updateManagementStatus(command, data)
  local credential = Openbus:getInterceptedCredential()
  if crendential then
     if credential.owner == "RegistryService" or
       credential.delegate == "RegistryService" then
       return
     end
  end

  local ftFacet = self.context.IFaultTolerantService
  if not ftFacet.ftConfig then
    return false
  end

  if #ftFacet.ftconfig.hosts.RS <= 1 then
    Log:debug(format(
        "N�o existem r�plicas cadastradas para atualizar o estado da ger�ncia para o comando %s",
        command))
    return false
  end

  local orb = Openbus:getORB()
  local i = 1
  repeat
    if ftFacet.ftconfig.hosts.RS[i] ~= ftFacet.rsReference then
      local ret, succ, remoteRGS = oil.pcall(Utils.fetchService,
        Openbus:getORB(), ftFacet.ftconfig.hosts.RS[i],
        Utils.REGISTRY_SERVICE_INTERFACE)
      if succ then
        --encontrou outra replica
        Log:debug(format("Requisitou comando %s na r�plica %s", command,
            ftFacet.ftconfig.hosts.RS[i]))
        -- Recupera faceta IManagement da replica remota
        local remoteRGSIC = remoteRGS:_component()
        remoteRGSIC = orb:narrow(remoteRGSIC, "IDL:scs/core/IComponent:1.0")
        local ok, remoteMgmFacet = oil.pcall(remoteRGSIC.getFacetByName,
          remoteRGSIC, "IManagement_" .. Utils.OB_VERSION)

        if ok then
          remoteMgmFacet = orb:narrow(remoteMgmFacet,
            Utils.MANAGEMENT_RS_INTERFACE)
          if command == "addInterfaceIdentifier" then
            oil.newthread(function()
              local succ, ret = oil.pcall(
                remoteMgmFacet.addInterfaceIdentifier, remoteMgmFacet,
                data.ifaceId)
            end)
          elseif command == "removeInterfaceIdentifier" then
            oil.newthread(function()
              local succ, ret = oil.pcall(
                remoteMgmFacet.removeInterfaceIdentifier,
                remoteMgmFacet, data.ifaceId)
            end)
          elseif command == "grant" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.grant, remoteMgmFacet,
                data.id, data.ifaceId, data.strict)
            end)
          elseif command == "revoke" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.revoke,
                remoteMgmFacet, data.id, data.ifaceId)
            end)
          elseif command == "removeAuthorization" then
            oil.newthread(function()
              local succ, ret = oil.pcall(remoteMgmFacet.removeAuthorization,
                remoteMgmFacet, data.id)
            end)
          end --fim command
        end -- fim ok facet IManagement
      else
        Log:error(format(
            "A r�plica %s n�o est� dispon�vel para ser atualizada quanto ao estado da ger�ncia para o comando %s",
            ftFacet.ftconfig.hosts.RS[i], command))
      end -- fim succ, encontrou replica
    end -- fim , nao eh a mesma replica
    i = i + 1
  until i > #ftFacet.ftconfig.hosts.RS
end
