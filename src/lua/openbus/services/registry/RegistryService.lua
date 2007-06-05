-----------------------------------------------------------------------------
-- Faceta que disponibiliza a funcionalidade b�sica do servi�o de registro
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
require "uuid"

local oop = require "loop.base"

local log = require "openbus.common.Log"

RegistryService = oop.class{}

function RegistryService:__init(accessControlService, picurrent)
  self = oop.rawnew(self, {
    offersByIdentifier = {}, -- reposit�rio id -> oferta
    offersByType = {},	     -- reposit�rio tipo -> id -> oferta
    offersByCredential = {}, -- reposit�rio credencial -> id -> oferta
    picurrent = picurrent,
    accessControlService = accessControlService
  })
  return self
end

--
-- Registra uma nova oferta de servi�o
-- A oferta de servi�o � representada por uma tabela com os campos:
--   type: tipo da oferta (string)
--   description: descri��o (textual) da oferta
--   properties: lista de propriedades associadas � oferta (opcional)
--               cada propriedade � um par nome/valor (lista de strings)
--   member: refer�ncia para o membro que faz a oferta
--
function RegistryService:register(serviceOffer)
  local identifier = self:generateIdentifier()
  local credential = self.picurrent:getValue()

  local offerEntry = {
    offer = serviceOffer,
    properties = self:createPropertyIndex(serviceOffer.properties,
                                          serviceOffer.member),
    credential = credential,
    identifier = identifier
  }

  log:service("Registrando oferta com tipo "..serviceOffer.type..
              " id "..identifier)

  -- �ndice de ofertas por identificador
  self.offersByIdentifier[identifier] = offerEntry

  -- �ndice de ofertas por tipo
  local type = offerEntry.offer.type
  if not self.offersByType[type] then
    log:service("Primeira oferta do tipo "..type)
    self.offersByType[type] = {}
  end
  self.offersByType[type][identifier] = offerEntry

  -- �ndice de ofertas por credencial
  if not self.offersByCredential[credential.identifier] then
    log:service("Primeira oferta da credencial "..credential.identifier)
    self.offersByCredential[credential.identifier] = {}
  end
  self.offersByCredential[credential.identifier][identifier] = offerEntry

  -- A credencial deve ser observada, porque se for deletada as
  -- ofertas a ela relacionadas devem ser removidas
  if not self.observerId then
    local observer = {
      registryService = self,
      credentialWasDeleted = function(self, credential)
        log:service("Observador notificado para credencial "..
                    credential.identifier)
        self.registryService:credentialWasDeleted(credential)
      end
    }
    self.observer = oil.newobject(observer,
                                  "IDL:openbusidl/acs/ICredentialObserver:1.0",
                                  "RegistryServiceCredentialObserver")
    self.observerId =
      self.accessControlService:addObserver(self.observer,
                                            {credential.identifier})
    log:service("Cadastrado observador para a credencial")
  else
    self.accessControlService:addCredentialToObserver(self.observerId,
                                                      credential.identifier)
    log:service("Adicionada credencial no observador")
  end

  return true, identifier
end

-- Constr�i um conjunto com os valores das propriedades, para acelerar a busca
-- procedimento v�lido enquanto propriedade for lista de strings !!!
function RegistryService:createPropertyIndex(offerProperties, member)
  local properties = {}
  for _, property in ipairs(offerProperties) do
    properties[property.name] = {}
    for _, val in ipairs(property.value) do
      properties[property.name][val] = true
    end 
  end

  local memberName = member:getName()

  -- se n�o foi definida uma propriedade "facets", discriminando as facetas
  -- disponibilizadas, assume que todas as facetas do membro s�o oferecidas
  if not properties["facets"] then
    log:service("Oferta de servi�o sem facetas para o membro "..memberName)
    local facet_descriptions = member:getFacets()
    if #facet_descriptions == 0 then
      log:service("Membro "..memberName.." n�o possui facetas")
    else
      log:service("Membro "..memberName.." possui facetas")
      properties["facets"] = {}
      for _,facet in ipairs(facet_descriptions) do
        properties["facets"][facet.name] = true
      end
    end
  end
  return properties
end

-- 
-- Remove uma oferta de servi�o
--
function RegistryService:unregister(identifier)
  log:service("Removendo oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    log:warning("Oferta a remover com id "..identifier.." n�o encontrada")
    return false
  end

  local credential = self.picurrent:getValue()
  if credential.identifier ~= offerEntry.credential.identifier then
    log:warning("Oferta a remover("..identifier..
                ") n�o registrada com a credencial do chamador")
    return false -- esse tipo de erro merece uma exce��o!
  end

  -- Remove oferta do �ndice por identificador
  self.offersByIdentifier[identifier] = nil

  -- Remove oferta do �ndice por tipo
  local type = offerEntry.offer.type
  if self.offersByType[type] then
    self.offersByType[type][identifier] = nil
    if not next(self.offersByType[type]) then
      -- N�o h� mais ofertas desse tipo
      log:service("�ltima oferta do tipo "..type.." removida")
      self.offersByType[type] = nil
    end
  end

  -- Remove oferta do �ndice por credencial
  local credentialOffers = self.offersByCredential[credential.identifier]
  if credentialOffers then
    credentialOffers[identifier] = nil
  else
    log:service("N�o h� ofertas a remover com credencial "..
                credential.identifier)
    return true
  end
  if not next(credentialOffers) then
    -- N�o h� mais ofertas associadas � credencial
    self.offersByCredential[credential.identifier] = nil
    log:service("�ltima oferta da credencial: remove credencial do observador")
    self.accessControlService:removeCredentialFromObserver(self.observerId,
                                                         credential.identifier)
  end
  return true
end

--
-- Atualiza a oferta de servi�o associada ao identificador especificado
-- Apenas as propriedades da oferta podem ser atualizadas
--   (nessa vers�o, substituidas)
--
function RegistryService:update(identifier, properties)
  log:service("Atualizando oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    log:warning("Oferta a atualizar com id "..identifier.." n�o encontrada")
    return false
  end

  local credential = self.picurrent:getValue()
  if credential.identifier ~= offerEntry.credential.identifier then
    log:warning("Oferta a atualizar("..identifier..
                ") n�o registrada com a credencial do chamador")
    return false -- esse tipo de erro merece uma exce��o!
  end

  -- Atualiza as propriedades da oferta de servi�o
  offerEntry.offer.properties = properties
  offerEntry.properties = self:createPropertyIndex(properties,
                                                   offerEntry.offer.member)
  return true
end

--
-- Busca por ofertas de servi�o de um determinado tipo, que atendam aos
-- crit�rios (propriedades) especificados.
-- A especifica��o de crit�rios � opcional.
--
function RegistryService:find(type, criteria)
  log:service("Procurando oferta com tipo "..type)

  local selectedOffers = {}
  local candidateOfferEntries = self.offersByType[type]
  if candidateOfferEntries and next(candidateOfferEntries) then
    log:service("H� ofertas para o tipo")
    -- Se n�o h� crit�rios, retorna todas as ofertas
    if #criteria == 0 then
      for id, offerEntry in pairs(candidateOfferEntries) do
        table.insert(selectedOffers, offerEntry.offer)
        log:service("Sem crit�rio, encontrei "..#selectedOffers.." ofertas")
      end
    else
      -- H� crit�rios a verificar
      for id, offerEntry in pairs(candidateOfferEntries) do
        if self:meetsCriteria(criteria, offerEntry.properties) then
          table.insert(selectedOffers, offerEntry.offer)
        end
      end
     log:service("Com crit�rio, encontrei "..#selectedOffers.." ofertas")
    end
  else
    log:service("N�o h� ofertas para o tipo "..type)
  end

  return selectedOffers
end

--
-- Verifica se uma oferta atende aos crit�rios de busca
--
function RegistryService:meetsCriteria(criteria, offerProperties)
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

--
-- Notifica��o de dele��o de credencial
-- As ofertas de servi�o relacionadas dever�o ser removidas
--
function RegistryService:credentialWasDeleted(credential)
  log:service("Remover ofertas da credencial deletada "..credential.identifier)
  local credentialOffers = self.offersByCredential[credential.identifier]
  self.offersByCredential[credential.identifier] = nil

  if credentialOffers then
    for identifier, offerEntry in pairs(credentialOffers) do
      self.offersByIdentifier[identifier] = nil
      log:service("Removida oferta "..identifier.." do �ndice por id")

      local type = offerEntry.offer.type
      if self.offersByType[type] then
        self.offersByType[type][identifier] = nil
        log:service("Removida oferta "..identifier..
                     " do �ndice por tipo "..type)
        if not next(self.offersByType[type]) then -- fim das ofertas desse tipo
          log:service("�ltima oferta do tipo "..type.." removida")
          self.offersByType[type] = nil
        end
      end
    end
  else
    log:service("N�o havia ofertas da credencial "..credential.identifier)
  end

  -- Remove a credencial do conjunto observado
  self.accessControlService:removeCredentialFromObserver(self.observerId,
                                                         credential.identifier)
end
--
-- Gera uma identifica��o de oferta de servi�o
--
function RegistryService:generateIdentifier()
    return uuid.new("time")
end

--
-- Finaliza o servi�o
--
function RegistryService:shutdown()
  if self.observerId then
    self.observer:_deactivate()
  end
end
