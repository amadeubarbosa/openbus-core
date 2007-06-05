-----------------------------------------------------------------------------
-- Faceta que disponibiliza a funcionalidade básica do serviço de registro
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "uuid"

local oop = require "loop.base"

local log = require "openbus.common.Log"

RegistryService = oop.class{}

function RegistryService:__init(accessControlService, picurrent)
  self = oop.rawnew(self, {
    offersByIdentifier = {}, -- repositório id -> oferta
    offersByType = {},	     -- repositório tipo -> id -> oferta
    offersByCredential = {}, -- repositório credencial -> id -> oferta
    picurrent = picurrent,
    accessControlService = accessControlService
  })
  return self
end

--
-- Registra uma nova oferta de serviço
-- A oferta de serviço é representada por uma tabela com os campos:
--   type: tipo da oferta (string)
--   description: descrição (textual) da oferta
--   properties: lista de propriedades associadas à oferta (opcional)
--               cada propriedade é um par nome/valor (lista de strings)
--   member: referência para o membro que faz a oferta
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

  -- Índice de ofertas por identificador
  self.offersByIdentifier[identifier] = offerEntry

  -- Índice de ofertas por tipo
  local type = offerEntry.offer.type
  if not self.offersByType[type] then
    log:service("Primeira oferta do tipo "..type)
    self.offersByType[type] = {}
  end
  self.offersByType[type][identifier] = offerEntry

  -- Índice de ofertas por credencial
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

-- Constrói um conjunto com os valores das propriedades, para acelerar a busca
-- procedimento válido enquanto propriedade for lista de strings !!!
function RegistryService:createPropertyIndex(offerProperties, member)
  local properties = {}
  for _, property in ipairs(offerProperties) do
    properties[property.name] = {}
    for _, val in ipairs(property.value) do
      properties[property.name][val] = true
    end 
  end

  local memberName = member:getName()

  -- se não foi definida uma propriedade "facets", discriminando as facetas
  -- disponibilizadas, assume que todas as facetas do membro são oferecidas
  if not properties["facets"] then
    log:service("Oferta de serviço sem facetas para o membro "..memberName)
    local facet_descriptions = member:getFacets()
    if #facet_descriptions == 0 then
      log:service("Membro "..memberName.." não possui facetas")
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
-- Remove uma oferta de serviço
--
function RegistryService:unregister(identifier)
  log:service("Removendo oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    log:warning("Oferta a remover com id "..identifier.." não encontrada")
    return false
  end

  local credential = self.picurrent:getValue()
  if credential.identifier ~= offerEntry.credential.identifier then
    log:warning("Oferta a remover("..identifier..
                ") não registrada com a credencial do chamador")
    return false -- esse tipo de erro merece uma exceção!
  end

  -- Remove oferta do índice por identificador
  self.offersByIdentifier[identifier] = nil

  -- Remove oferta do índice por tipo
  local type = offerEntry.offer.type
  if self.offersByType[type] then
    self.offersByType[type][identifier] = nil
    if not next(self.offersByType[type]) then
      -- Não há mais ofertas desse tipo
      log:service("Última oferta do tipo "..type.." removida")
      self.offersByType[type] = nil
    end
  end

  -- Remove oferta do índice por credencial
  local credentialOffers = self.offersByCredential[credential.identifier]
  if credentialOffers then
    credentialOffers[identifier] = nil
  else
    log:service("Não há ofertas a remover com credencial "..
                credential.identifier)
    return true
  end
  if not next(credentialOffers) then
    -- Não há mais ofertas associadas à credencial
    self.offersByCredential[credential.identifier] = nil
    log:service("Última oferta da credencial: remove credencial do observador")
    self.accessControlService:removeCredentialFromObserver(self.observerId,
                                                         credential.identifier)
  end
  return true
end

--
-- Atualiza a oferta de serviço associada ao identificador especificado
-- Apenas as propriedades da oferta podem ser atualizadas
--   (nessa versão, substituidas)
--
function RegistryService:update(identifier, properties)
  log:service("Atualizando oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    log:warning("Oferta a atualizar com id "..identifier.." não encontrada")
    return false
  end

  local credential = self.picurrent:getValue()
  if credential.identifier ~= offerEntry.credential.identifier then
    log:warning("Oferta a atualizar("..identifier..
                ") não registrada com a credencial do chamador")
    return false -- esse tipo de erro merece uma exceção!
  end

  -- Atualiza as propriedades da oferta de serviço
  offerEntry.offer.properties = properties
  offerEntry.properties = self:createPropertyIndex(properties,
                                                   offerEntry.offer.member)
  return true
end

--
-- Busca por ofertas de serviço de um determinado tipo, que atendam aos
-- critérios (propriedades) especificados.
-- A especificação de critérios é opcional.
--
function RegistryService:find(type, criteria)
  log:service("Procurando oferta com tipo "..type)

  local selectedOffers = {}
  local candidateOfferEntries = self.offersByType[type]
  if candidateOfferEntries and next(candidateOfferEntries) then
    log:service("Há ofertas para o tipo")
    -- Se não há critérios, retorna todas as ofertas
    if #criteria == 0 then
      for id, offerEntry in pairs(candidateOfferEntries) do
        table.insert(selectedOffers, offerEntry.offer)
        log:service("Sem critério, encontrei "..#selectedOffers.." ofertas")
      end
    else
      -- Há critérios a verificar
      for id, offerEntry in pairs(candidateOfferEntries) do
        if self:meetsCriteria(criteria, offerEntry.properties) then
          table.insert(selectedOffers, offerEntry.offer)
        end
      end
     log:service("Com critério, encontrei "..#selectedOffers.." ofertas")
    end
  else
    log:service("Não há ofertas para o tipo "..type)
  end

  return selectedOffers
end

--
-- Verifica se uma oferta atende aos critérios de busca
--
function RegistryService:meetsCriteria(criteria, offerProperties)
  for _, criterion in ipairs(criteria) do
    local offerProperty = offerProperties[criterion.name]
    if offerProperty then
      for _, val in ipairs(criterion.value) do
        if not offerProperty[val] then
          return false -- oferta não tem valor em seu conjunto
        end
      end
    else
      return false -- oferta não tem propriedade com esse nome
    end
  end
  return true
end

--
-- Notificação de deleção de credencial
-- As ofertas de serviço relacionadas deverão ser removidas
--
function RegistryService:credentialWasDeleted(credential)
  log:service("Remover ofertas da credencial deletada "..credential.identifier)
  local credentialOffers = self.offersByCredential[credential.identifier]
  self.offersByCredential[credential.identifier] = nil

  if credentialOffers then
    for identifier, offerEntry in pairs(credentialOffers) do
      self.offersByIdentifier[identifier] = nil
      log:service("Removida oferta "..identifier.." do índice por id")

      local type = offerEntry.offer.type
      if self.offersByType[type] then
        self.offersByType[type][identifier] = nil
        log:service("Removida oferta "..identifier..
                     " do índice por tipo "..type)
        if not next(self.offersByType[type]) then -- fim das ofertas desse tipo
          log:service("Última oferta do tipo "..type.." removida")
          self.offersByType[type] = nil
        end
      end
    end
  else
    log:service("Não havia ofertas da credencial "..credential.identifier)
  end

  -- Remove a credencial do conjunto observado
  self.accessControlService:removeCredentialFromObserver(self.observerId,
                                                         credential.identifier)
end
--
-- Gera uma identificação de oferta de serviço
--
function RegistryService:generateIdentifier()
    return uuid.new("time")
end

--
-- Finaliza o serviço
--
function RegistryService:shutdown()
  if self.observerId then
    self.observer:_deactivate()
  end
end
