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
--   properties: lista de propriedades associadas � oferta (opcional)
--               cada propriedade a um par nome/valor (lista de strings)
--   member: refer�ncia para o membro que faz a oferta
--
--@param serviceOffer A oferta de servi�o.
--
--@return Identificador do registro da oferta.
--
--@exception UnauthorizedFacets Exce��o contendo a lista de facetas
--que o membro n�o tem autoriza��o.
---
function RSFacet:register(serviceOffer)
  local credential = Openbus:getInterceptedCredential()
  local properties = self:createPropertyIndex(serviceOffer.properties,
    serviceOffer.member)
  local facets = self:getAuthorizedFacets(serviceOffer.member, credential,
    properties)

  local offerEntry = {
    offer = serviceOffer,
    -- Mapeia as propriedades.
    properties = properties,
    -- Mapeia as facetas do componente.
    facets = facets,
    credential = credential,
    identifier = self:generateIdentifier(),
  }


  local orb = Openbus:getORB()
  for _, existentOfferEntry in pairs(self.offersByIdentifier) do
    if Utils.equalsOfferEntries(offerEntry, existentOfferEntry, orb) then
      -- oferta id�ntica a uma existente, n�o faz nada
      Log:registry("Oferta j� existente com id " ..
        existentOfferEntry.identifier)
      return existentOfferEntry.identifier
    end
  end

  Log:registry("Registrando oferta com id "..offerEntry.identifier)

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
    Log:registry("Primeira oferta da credencial "..credential.identifier)
    self.offersByCredential[credential.identifier] = {}
  end
  self.offersByCredential[credential.identifier][offerEntry.identifier] =
    offerEntry

  -- A credencial deve ser observada, porque se for deletada as
  -- ofertas a ela relacionadas devem ser removidas
  local orb = Openbus:getORB()
  local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle,
    orb, self.context.IComponent, "AccessControlServiceReceptacle",
    "IAccessControlService_v" .. Utils.OB_VERSION,
    Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
  if status and acsFacet then
    acsFacet:addCredentialToObserver(self.observerId, credential.identifier)
    Log:service("Adicionada credencial no observador")
  else
    -- erro ja foi logado, so adiciona que nao pode adicionar
    Log:service("Nao foi possivel adicionar credencial ao observador")
  end
end

function RSFacet:updateMemberInfoInExistentOffer(existentOfferEntry, member)
  Log:registry("[updateMemberInfoInExistentOffer] Atualizando informa��es de membro em oferta existente...")
  --Atencao, o identificador da credencial antiga � o que prevalece
  --por causa dos observadores
  existentOfferEntry.offer.member = member
  existentOfferEntry.properties = self:createPropertyIndex(
    existentOfferEntry.offer.properties, existentOfferEntry.offer.member)
  self.offersDB:update(existentOfferEntry)

  self.offersByCredential[existentOfferEntry.credential.identifier][existentOfferEntry.identifier] = existentOfferEntry

  Log:registry("[updateMemberInfoInExistentOffer] Informa��es de membro atualizadas.")
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
-- @exception UnathorizedFacets Cont�m a lista com uma ou
--   mais facetas que o membro n�o tem autoriza��o.
--
function RSFacet:getAuthorizedFacets(member, credential, properties)
  local succ, facets, count
  local metaInterface = member:getFacetByName("IMetaInterface")
  if metaInterface then
    local orb = Openbus:getORB()
    metaInterface = orb:narrow(metaInterface, "IDL:scs/core/IMetaInterface:1.0")
    succ, facets, count = self:createFacetIndex(credential.owner,
      metaInterface:getFacets(), properties.facets)
    if succ then
      Log:registry(format("Membro '%s' (%s) possui %d faceta(s) autorizada(s).",
        properties.component_id.name, credential.owner, count))
    else
      Log:error(format("Membro '%s' (%s) possui %d faceta(s) n�o autorizada(s).",
        properties.component_id.name, credential.owner, count))
      local tmp = {}
      for facet in pairs(facets) do
        tmp[#tmp+1] = facet
      end
      error(Openbus:getORB():newexcept {
        "IDL:tecgraf/openbus/core/v1_05/registry_service/UnathorizedFacets:1.0",
        facets = tmp,
      })
    end
  else
    facets = {}
    Log:registry(format(
      "Membro '%s' (%s) n�o disponibiliza IMetaInterface para autoriza��o das facetas.",
      properties.component_id.name, credential.owner))
  end
  return facets
end

---
-- Busca as interfaces por meio da metainterface do membro e as
-- disponibiza para consulta.
--
-- @param owner Dono da credencial.
-- @param allFacets Array de facetas do membro.
-- @param filter Tabela contendo facetas (repId) permitidas ou
--  nil para indicar sem filtro.
--
-- @return Em caso de sucesso, retorna true, o �ndice de facetas
-- dispon�veis do membro e o n�mero de facetas no �ndice.
-- No caso de falta de autoriza��o, retorna false, um �ndice de
-- facetas n�o autorizadas e o n�mero de facetas no �ndice
--
function RSFacet:createFacetIndex(owner, allFacets, filter)
  local tmp = {}
  local count = 0
  local facets = {}
  local invalidCount = 0
  local invalidFacets = {}
  local mgm = self.context.IManagement
  -- Inverte o �ndice para facilitar a busca
  for _, facet in ipairs(allFacets) do
    tmp[facet.interface_name] = facet
  end
  -- Verifica se n�o requisitou uma faceta que n�o implementa
  if filter then
    for name in pairs(filter) do
      if not tmp[name] then
        invalidFacets[name] = true
        invalidCount = invalidCount + 1
      end
    end
  end
  -- Verifica as autoriza��es
  for name, facet in pairs(tmp) do
    if not IgnoredFacets[name] and ((not filter) or filter[name])
    then
      if not mgm:hasAuthorization(owner, name) then
        invalidFacets[name] = true
        invalidCount = invalidCount + 1
      elseif invalidCount == 0 then
        facets[facet.name] = "name"
        facets[facet.interface_name] = "interface_name"
        facets[facet.facet_ref] = "facet_ref"
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
--@return true caso a oferta tenha sido removida, ou false caso contr�rio.
--        e true caso a operacao tenha sido executada remotamente, ou false caso contr�rio
--        em algumas das replicas.
---
function RSFacet:unregister(identifier)
  local ret = self:rawUnregister(identifier, Openbus:getInterceptedCredential())
  if ret then
    local credential = Openbus:getInterceptedCredential()
    if credential then
       if credential.owner == "RegistryService" or
          credential.delegate == "RegistryService" then
          return ret, false
       end
    end

    local ftFacet = self.context.IFaultTolerantService
    if not ftFacet.ftconfig then
      Log:faulttolerance("[unregister] Faceta precisa ser inicializada antes de ser chamada.")
      Log:warn("[unregister] n�o foi poss�vel executar 'unregister' nas replicas")
      return ret, false
    end

    if #ftFacet.ftconfig.hosts.RS <= 1 then
      Log:faulttolerance("[unregister] Nenhuma replica para atualizar estado do cadastros de ofertas.")
      return ret, false
    end

    local i = 1
    local retRemote = true
    repeat
    if ftFacet.ftconfig.hosts.RS[i] ~= ftFacet.rsReference then
      local ret, succ, remoteRGS = oil.pcall(Utils.fetchService,
        Openbus:getORB(), ftFacet.ftconfig.hosts.RS[i],
        Utils.REGISTRY_SERVICE_INTERFACE)
      if ret and succ then
        --encontrou outra replica
        Log:faulttolerance("[unregister] Atualizando replica "
          .. ftFacet.ftconfig.hosts.RS[i] ..".")
        -- Recupera faceta IRegistryService da replica remota
        local orb = Openbus:getORB()
        local remoteRGSIC = remoteRGS:_component()
        remoteRGSIC = orb:narrow(remoteRGSIC, "IDL:scs/core/IComponent:1.0")
        local ok, remoteRGSFacet = oil.pcall(remoteRGSIC.getFacetByName,
          remoteRGSIC, "IRegistryService_v" .. Utils.OB_VERSION)
        if ok and remoteRGSFacet then
          remoteRGSFacet = orb:narrow(remoteRGSFacet,
            Utils.REGISTRY_SERVICE_INTERFACE)
            oil.newthread(function()
                local succ, ret = oil.pcall(
                  remoteRGSFacet.unregister, remoteRGSFacet,
                  identifier)
                end)
        else
           Log:faulttolerance("[unregister] Faceta da replica nao encontrada.")
           retRemote = false
        end -- fim ok facet IRegistryService
      end -- fim succ, encontrou replica
    end -- fim , nao eh a mesma replica
    i = i + 1
    until i > #ftFacet.ftconfig.hosts.RS
    Log:faulttolerance("[unregister] Replicas atualizadas quanto ao estado para a operacao [unregister]")
  end -- fim ret da execucao local

  return ret, retRemote
end

---
--M�todo interno respons�vel por efetivamente remover uma oferta de servi�o.
--
--@param identifier A identifica��o da oferta de servi�o.
--@param credential Credencial do membro que efetuou o registro ou
--  nil se for uma remo��o for�ada pelo administrador do barramento.
--
--@return true caso a oferta tenha sido removida, ou false caso contr�rio.
---
function RSFacet:rawUnregister(identifier, credential)

  Log:registry("Removendo oferta "..identifier)
  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warn("Oferta a remover com id "..identifier.." n�o encontrada")
    return false
  end
  if credential then
    if credential.identifier ~= offerEntry.credential.identifier then
      Log:warn("Oferta a remover("..identifier..
        ") n�o registrada com a credencial do chamador")
      return false
    end
  else
    credential = offerEntry.credential
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
    local orb = Openbus:getORB()
    self.offersByCredential[credential.identifier] = nil
    Log:registry("�ltima oferta da credencial: remove credencial do observador")
    local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle,
      orb, self.context.IComponent, "AccessControlServiceReceptacle",
      "IAccessControlService_v" .. Utils.OB_VERSION, Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
    if status and acsFacet then
      acsFacet:removeCredentialFromObserver(self.observerId,
        credential.identifier)
    else
      -- erro ja foi logado, so adiciona que nao pode remover
      Log:error("N�o foi poss�vel remover credencial")
    end
  end

  self.offersDB:delete(offerEntry)
  Log:registry("Oferta "..identifier.." com credencial "..
        credential.identifier .. " removida.")
  return true
end

---
--Atualiza a oferta de servi�o associada ao identificador especificado. Apenas
--as propriedades da oferta podem ser atualizadas (nessa vers�o, substituidas).
--
--@param identifier O identificador da oferta.
--@param properties As novas propriedades da oferta.
--
--@exception UnauthorizedFacets Exce��o contendo a lista de facetas
--que o membro n�o tem autoriza��o.
--
--@exception ServiceOfferNonExistent O membro n�o possui nenhuma oferta
--relacionada com o identificador informado.
---
function RSFacet:update(identifier, properties)
  Log:registry("Atualizando oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warn("Oferta a atualizar com id "..identifier.." n�o encontrada")
    error(Openbus:getORB():newexcept {
      "IDL:tecgraf/openbus/core/v1_05/registry_service/ServiceOfferNonExistent:1.0",
    })
  end

  local credential = Openbus:getInterceptedCredential()
  if credential.identifier ~= offerEntry.credential.identifier then
    Log:warn("Oferta a atualizar("..identifier..
                ") n�o registrada com a credencial do chamador")
    error(Openbus:getORB():newexcept {
      "IDL:tecgraf/openbus/core/v1_05/registry_service/ServiceOfferNonExistent:1.0",
    })
  end

  local indexedProperties = self:createPropertyIndex(properties,
    offerEntry.offer.member)

  -- Atualiza as propriedades da oferta de servi�o
  offerEntry.facets = self:getAuthorizedFacets(
    offerEntry.offer.member, credential, indexedProperties)
  offerEntry.offer.properties = properties
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
      selectedOffersEntries[i].authorizedFacets =
        Utils.marshalHashFacets(offerEntry.facets)
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
        selectedOffersEntries[i].authorizedFacets =
          Utils.marshalHashFacets(offerEntry.facets)
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
          selectedOffersEntries[i].authorizedFacets =
            Utils.marshalHashFacets(offerEntry.facets)
          i = i + 1
        end
      end
    end
    Log:registry("Com crit�rio, encontrei "..#selectedOffersEntries..
      " ENTRADAS de ofertas que implementam as facetas discriminadas.")
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
  Log:registry("Reconectando o Servi�o de Registro.")
  Openbus:connectByCertificate(self.context._componentId.name,
    self.privateKeyFile, self.accessControlServiceCertificateFile)

  if not Openbus:isConnected() then
    Log:error("Falha ao reconectar no ACS.")
    return false
  end

  local acsFacet = Openbus:getAccessControlService()
  -- atualiza a refer�ncia junto ao servi�o de controle de acesso
  -- conecta-se com o controle de acesso:   [ACS]--( 0--[RS]
  local acsIComp = Openbus:getACSIComponent()
  local acsIRecep =  acsIComp:getFacetByName("IReceptacles")
  acsIRecep = Openbus.orb:narrow(acsIRecep, "IDL:scs/core/IReceptacles:1.0")
  local status, conns = oil.pcall(acsIRecep.connect, acsIRecep,
    "RegistryServiceReceptacle", self.context.IComponent )
  if not status then
    Log:error("Falha ao conectar o servi�o de Registro no recept�culo: " ..
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
    if not acsFacet:addCredentialToObserver(self.observerId, credentialId) then
      Log:registry("Ofertas de "..credentialId.." ser�o removidas")
      table.insert(invalidCredentials, credential)
    else
      Log:registry("Ofertas de "..credentialId.." ser�o mantidas")
    end
  end
  for _, credential in ipairs(invalidCredentials) do
    self:credentialWasDeleted(credential)
  end

  Log:registry("servi�o de registro foi reconectado")
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
    Log:faulttolerance("[updateConnectionState] Atualiza estado do RGS quanto ao [".. command .."].")
    local ftFacet = self.context.IFaultTolerantService
    if not ftFacet.ftconfig then
        Log:faulttolerance("[updateConnectionState] Faceta precisa ser inicializada antes de ser chamada.")
        Log:warn("[updateConnectionState] n�o foi poss�vel atualizar estado quanto ao [".. command .."]")
        return
    end

    if # ftFacet.ftconfig.hosts.RS <= 1 then
        Log:faulttolerance("[updateConnectionState] Nenhuma replica para atualizar estado quanto ao [".. command .."].")
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
                Log:faulttolerance("[updateConnectionState] Atualizando replica ".. ftFacet.ftconfig.hosts.RS[i] ..".")
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
                     Log:faulttolerance("[updateConnectionState] Replica ".. ftFacet.ftconfig.hosts.RS[i] .." atualizada quanto ao [".. command .."].")
                end
            else
                Log:faulttolerance("[updateConnectionState] Replica ".. ftFacet.ftconfig.hosts.RS[i] .." n�o est� dispon�vel e n�o pode ser atualizada quanto ao [".. command .."].")
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
  Log:faulttolerance("[updateStatus] Atualiza estado das ofertas.")
  if not self.ftconfig then
    Log:faulttolerance("[updateStatus] Faceta precisa ser inicializada antes de ser chamada.")
    Log:faultolerance("[warn][updateStatus] N�o foi poss�vel executar 'updatestatus'")
    return false
  end

  if #self.ftconfig.hosts.RS <= 1 then
    Log:faulttolerance("[updateStatus] Nenhuma replica para atualizar ofertas.")
    return false
  end


  return self:updateOffersStatus(facets, criteria)
end

function FaultToleranceFacet:updateOffersStatus(facets, criteria)
  Log:faulttolerance("[updateOffersStatus] Buscando ofertas nas replicas exceto em ".. self.rsReference)
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

            local memberProtected = orb:newproxy(addOfferEntry.offer.member, "protected")
            local succ, metaInterface = memberProtected:getFacetByName("IMetaInterface")
            if succ and metaInterface then
              metaInterface = orb:narrow(metaInterface, "IDL:scs/core/IMetaInterface:1.0")
              local facets = metaInterface:getFacets()
              for _, facet in ipairs(facets) do
                if addOfferEntry.facets[facet.name] or
                   addOfferEntry.facets[interface_name] then
                  addOfferEntry.facets[facet.facet_ref] = "facet_ref"
                end
              end
            end

            --Recupera o indice das propriedades inseridas pelo RGS
            addOfferEntry.properties =
              Utils.convertToReceiveIndexedProperties(offerEntryFound.properties)
            --Refazendo indice das propriedades
            for _, property in ipairs(addOfferEntry.offer.properties) do
              if not addOfferEntry.properties[property.name] then
                addOfferEntry.properties[property.name] = {}
              end
              for _, val in ipairs(property.value) do
                  addOfferEntry.properties[property.name][val] = true
              end
            end

            -- verifica se ja existem localmente
            Log:faulttolerance("[updateOffersStatus] Verificando se a oferta ["
              .. addOfferEntry.identifier .. "] ja existe localmente ...")
            for _, offerEntry in pairs(rgs.offersByIdentifier) do
              --se ja existir, nao adiciona
              local sameOfferDescription =
                    Utils.equalsOfferEntries(addOfferEntry, offerEntry, orb)
              if addOfferEntry.identifier == offerEntry.identifier and
                 sameOfferDescription then
              --Existe entrada completa igual, nao insere
                insert = false
                Log:faulttolerance("[updateOffersStatus] ... SIM, a oferta ["..
                  addOfferEntry.identifier .. "] ja existe localmente.")
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
                      Log:faulttolerance("[updateOffersStatus] ... SIM, a oferta ["..
                        addOfferEntry.identifier .. "] ja existe localmente e ser� ATUALIZADA.")
                      break
                    end
                  end
              end
            end
            if insert then
              Log:faulttolerance("[updateOffersStatus] ... NAO, a oferta ["
                .. addOfferEntry.identifier
                .. "] nao existe localmente e sera inserida.")
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
    Log:faulttolerance("[updateOffersStatus] Quantidade de ofertas inseridas/atualizadas:["
      .. tostring(count) .."].")
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
  self.context.IFaultTolerantService:init()

  -- Verifica se � o primeiro startup
  if not rs.initialized then
    Log:registry("servi�o de registro est� inicializando")
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
    Log:registry("servi�o de registro j� foi inicializado")
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
     Log:registry("Observador notificado para credencial "..
       credential.identifier)
     self.registryService:credentialWasDeleted(credential)
   end
 }
 rs.observer = orb:newservant(observer, "RegistryServiceCredentialObserver",
   Utils.CREDENTIAL_OBSERVER_INTERFACE)
 rs.observerId = accessControlService:addObserver(rs.observer, {})
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
 mgm.acsmgm = acsIComp:getFacetByName("IManagement_v" .. Utils.OB_VERSION)
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
 local acsIComp = Openbus:getACSIComponent()
 local acsIRecep =  acsIComp:getFacetByName("IReceptacles")
 acsIRecep = Openbus.orb:narrow(acsIRecep, "IDL:scs/core/IReceptacles:1.0")
 local status, conns = oil.pcall(acsIRecep.connect, acsIRecep,
   "RegistryServiceReceptacle", self.context.IComponent )
 if not status then
   Log:error("Falha ao conectar o servi�o de Registro no recept�culo: " ..
     conns[1])
   return false
 end

 Log:registry("servi�o de registro iniciado")
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
  local orb = Openbus:getORB()
  if rs.observerId then
    local status, acsFacet =  oil.pcall(Utils.getReplicaFacetByReceptacle,
      orb, self.context.IComponent, "AccessControlServiceReceptacle",
      "IAccessControlService_v" .. Utils.OB_VERSION, Utils.ACCESS_CONTROL_SERVICE_INTERFACE)
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

  Log:registry("servi�o de registro finalizado")

  orb:deactivate(rs)
  orb:deactivate(self.context.IManagement)
  orb:deactivate(self.context.IFaultTolerantService)
  orb:deactivate(self.context.IComponent)
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
      succ, err = self.acsmgm:getSystemDeployment(auth.id)
    else -- type == "ATUser"
      succ, err = self.acsmgm:getUser(auth.id)
    end
    if succ then
      self.authorizations[auth.id] = auth
    else
      if err[1] == SystemDeploymentNonExistentException or
         err[1] == UserNonExistentException
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
    Log:error(format("Interface '%s' j� cadastrada.", ifaceId))
    error{InterfaceIdentifierAlreadyExistsException}
  end
  self.interfaces[ifaceId] = true
  local succ, msg = self.ifaceDB:save(ifaceId, ifaceId)
  if not succ then
    Log:error(format("Falha ao salvar a interface '%s': %s",
      ifaceId, msg))
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
    local succ, member = self.acsmgm:getSystemDeployment(id)
    if not succ then
      if member[1] ~= SystemDeploymentNonExistentException then
        error(member)  -- Exce��o desconhecida, repassando
      end
      type = "ATUser"
      succ, member = self.acsmgm:getUser(id)
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
    Log:error(format("Falha ao remover autoriza��o  '%s': %s", id, msg))
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
    Log:error(format("N�o h� autoriza��o  para '%s'.", id))
    error{AuthorizationNonExistentException}
  end
  self.authorizations[id] = nil
  local succ, msg = self.authDB:remove(id)
  if not succ then
    Log:error(format("Falha ao remover autoriza��o '%s': %s", id, msg))
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
  local ifaces = {}
  local offers = self.context.IRegistryService.offersByIdentifier
  for id, offer in pairs(offers) do
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
      }
      ifaces = {}
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
        }
        ifaces = {}
      end
    end
  end
  return array
end

---
-- Recupera do  registro as  ofertas que cont�m  que interfaces  que o
-- membro n�o est� autorizado a ofertar.
--
-- @return Array contendo as ofertas.
--
function ManagementFacet:getUnauthorizedInterfaces()
  self:checkPermission()
  local array = {}
  local ifaces = {}
  local offers = self.context.IRegistryService.offersByIdentifier
  for id, offer in pairs(offers) do
    local owner = offer.credential.owner
    for facet, type in pairs(offer.facets) do
      if type == "interface_name" and not self:hasAuthorization(owner, facet) then
        ifaces[#ifaces+1] = facet
      end
    end
    if #ifaces > 0 then
      array[#array+1] = {
        id = id,
        member = offer.credential.owner,
        interfaces = ifaces,
      }
      ifaces = {}
    end
  end
  return array
end

---
-- Recupera do registro as ofertas de um membro que cont�m que
-- interfaces sem autoriza��o para serem ofertadas.
--
-- @param member Identificador do membro do barramento.
--
-- @return Array contendo as ofertas.
--
function ManagementFacet:getUnauthorizedInterfacesByMember(member)
  self:checkPermission()
  local array = {}
  local ifaces = {}
  local offers = self.context.IRegistryService.offersByIdentifier
  for id, offer in pairs(offers) do
    local owner = offer.credential.owner
    if owner == member then
      for facet, type in pairs(offer.facets) do
        if type == "interface_name" and not self:hasAuthorization(owner, facet) then
          ifaces[#ifaces+1] = facet
        end
      end
      if #ifaces > 0 then
        array[#array+1] = {
          id = id,
          member = offer.credential.owner,
          interfaces = ifaces,
        }
        ifaces = {}
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

  Log:faulttolerance("[updateManagementStatus] Atualiza estado das interfaces e autorizacoes para o comando[".. command .."].")
  local ftFacet = self.context.IFaultTolerantService
  if not ftFacet.ftconfig then
    Log:faulttolerance("[updateManagementStatus] Faceta precisa ser inicializada antes de ser chamada.")
    Log:warn("[updateManagementStatus] n�o foi poss�vel executar 'updateManagementStatus'")
    return false
  end

  if #ftFacet.ftconfig.hosts.RS <= 1 then
    Log:faulttolerance("[updateManagementStatus] Nenhuma replica para atualizar estado das interfaces e autorizacoes.")
    return false
  end

  local i = 1
  repeat
    if ftFacet.ftconfig.hosts.RS[i] ~= ftFacet.rsReference then
      local ret, succ, remoteRGS = oil.pcall(Utils.fetchService,
        Openbus:getORB(), ftFacet.ftconfig.hosts.RS[i],
        Utils.REGISTRY_SERVICE_INTERFACE)
      if succ then
        --encontrou outra replica
        Log:faulttolerance("[updateManagementStatus] Atualizando replica "
          .. ftFacet.ftconfig.hosts.RS[i] ..".")
        -- Recupera faceta IManagement da replica remota
        local remoteRGSIC = remoteRGS:_component()
        remoteRGSIC = orb:narrow(remoteRGSIC, "IDL:scs/core/IComponent:1.0")
        local orb = Openbus:getORB()
        local ok, remoteMgmFacet = oil.pcall(remoteRGSIC.getFacetByName,
          remoteRGSIC, "IManagement_v" .. Utils.OB_VERSION)

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

          Log:faulttolerance("[updateManagementStatus] Replica ".. ftFacet.ftconfig.hosts.RS[i] .." atualizada quanto ao estado das interfaces e autorizacoes para o comando[".. command .."].")
        end -- fim ok facet IManagement
      else
        Log:faulttolerance("[updateManagementStatus] Replica ".. ftFacet.ftconfig.hosts.RS[i] .." n�o est� dispon�vel e n�o pode ser atualizada quanto quanto ao estado das interfaces e autorizacoes para o comando[".. command .."].")
      end -- fim succ, encontrou replica
    end -- fim , nao eh a mesma replica
    i = i + 1
  until i > #ftFacet.ftconfig.hosts.RS
end
