-----------------------------------------------------------------------------
-- Componente (membro) responsável pelo Serviço de Registro
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
require "oil"
require "uuid"

require "openbus.Member"
require "openbus.services.registry.OffersDB"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local CredentialHolder = require "openbus.common.CredentialHolder"
local PICurrent = require "openbus.common.PICurrent"
local log = require "openbus.common.Log"
local ServiceConnectionManager = require "openbus.common.ServiceConnectionManager"

local oop = require "loop.simple"

RegistryService = oop.class({}, Member)

--
-- Constrói a implementação do componente
--
function RegistryService:__init(name)
  local obj = { name = name,
                config = RegistryServerConfiguration,
              }
  Member:__init(obj)
  return oop.rawnew(self, obj)
end

--
-- Inicia o componente
--
function RegistryService:startup()
  log:service("Pedido de startup para serviço de registro")

  -- Se é o primeiro startup, deve instanciar ConnectionManager e
  -- instalar interceptadores
  if not self.initialized then
    log:service("Serviço de registro está inicializando")
    local credentialHolder = CredentialHolder()
    self.connectionManager = 
      ServiceConnectionManager(self.config.accessControlServerHost,
        credentialHolder, self.config.privateKeyFile, 
        self.config.accessControlServiceCertificateFile)
  
    -- obtém a referência para o Serviço de Controle de Acesso
    self.accessControlService = self.connectionManager:getAccessControlService()
    if self.accessControlService == nil then
      error{"IDL:SCS/StartupFailed:1.0"}
    end

    -- instala o interceptador cliente
    local CONF_DIR = os.getenv("CONF_DIR")
    local interceptorsConfig = 
      assert(loadfile(CONF_DIR.."/advanced/RSInterceptorsConfiguration.lua"))()
    oil.setclientinterceptor(
      ClientInterceptor(interceptorsConfig, credentialHolder))

    -- instala o interceptador servidor
    self.picurrent = PICurrent()
    oil.setserverinterceptor(ServerInterceptor(interceptorsConfig, 
                                               self.picurrent,
                                               self.accessControlService))

    -- instancia mecanismo de persistencia
    self.offersDB = OffersDB(self.config.databaseDirectory)
    self.initialized = true
  else
    log:service("Serviço de registro já foi inicializado")
  end

  -- Inicializa o repositório de ofertas
  self.offersByIdentifier = {}   -- id -> oferta
  self.offersByType = {}         -- tipo -> id -> oferta
  self. offersByCredential = {}  -- credencial -> id -> oferta

  -- autentica o serviço, conectando-o ao barramento
  local success = self.connectionManager:connect(self.name,
    function() self.wasReconnected(self) end)
  if not success then
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- atualiza a referência junto ao serviço de controle de acesso
  self.accessControlService:setRegistryService(self)

  -- registra um observador de credenciais
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
    self.accessControlService:addObserver(self.observer, {})
  log:service("Cadastrado observador para a credencial")

  -- recupera ofertas persistidas
  log:service("Recuperando ofertas persistidas")
  local offerEntriesDB = self.offersDB:retrieveAll()
  for _, offerEntry in pairs(offerEntriesDB) do
    -- somente recupera ofertas de credenciais válidas
    if self.accessControlService:isValid(offerEntry.credential) then
      self:addOffer(offerEntry)
    else
      log:service("Oferta de "..offerEntry.credential.identifier.." descartada")
      self.offersDB:delete(offerEntry)
    end
  end

  self.started = true
  log:service("Serviço de registro iniciado")
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

  self:addOffer(offerEntry)
  self.offersDB:insert(offerEntry)

  return true, identifier
end

--
-- Adiciona uma oferta ao repositório
--
function RegistryService:addOffer(offerEntry)
  
  -- Índice de ofertas por identificador
  self.offersByIdentifier[offerEntry.identifier] = offerEntry

  -- Índice de ofertas por tipo
  local type = offerEntry.offer.type
  if not self.offersByType[type] then
    log:service("Primeira oferta do tipo "..type)
    self.offersByType[type] = {}
  end
  self.offersByType[type][offerEntry.identifier] = offerEntry

  -- Índice de ofertas por credencial
  local credential = offerEntry.credential
  if not self.offersByCredential[credential.identifier] then
    log:service("Primeira oferta da credencial "..credential.identifier)
    self.offersByCredential[credential.identifier] = {}
  end
  self.offersByCredential[credential.identifier][offerEntry.identifier] = 
    offerEntry

  -- A credencial deve ser observada, porque se for deletada as
  -- ofertas a ela relacionadas devem ser removidas
  self.accessControlService:addCredentialToObserver(self.observerId,
                                                    credential.identifier)
  log:service("Adicionada credencial no observador")
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
  self.offersDB:delete(offerEntry)
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
  self.offersDB:update(offerEntry)
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
      self.offersDB:delete(offerEntry)
    end
  else
    log:service("Não havia ofertas da credencial "..credential.identifier)
  end
end

--
-- Gera uma identificação de oferta de serviço
--
function RegistryService:generateIdentifier()
    return uuid.new("time")
end

--
-- Procedimento após reconexão do serviço
--
function RegistryService:wasReconnected()
 log:service("Serviço de registro foi reconectado")
 -- atualiza a referência junto ao serviço de controle de acesso
  self.accessControlService:setRegistryService(self)

  -- registra novamente o observador de credenciais
  self.observerId =
    self.accessControlService:addObserver(self.observer, {})
 log:service("Observador recadastrado")

  -- Mantem no repositorio apenas ofertas com credenciais válidas
  local offerEntries = self.offersByIdentifier
  local credentials = {}
  for _, offerEntry in pairs(offerEntries) do
    credentials[offerEntry.credential.identifier] = offerEntry.credential
  end
  local invalidCredentials = {}
  for credentialId, credential in pairs(credentials) do
    if not self.accessControlService:addCredentialToObserver(self.observerId,
                                                            credentialId) then
      log:service("Ofertas de "..credentialId.." serão removidas")
      table.insert(invalidCredentials, credential)
    else
      log:service("Ofertas de "..credentialId.." serão mantidas")
    end
  end
  for _, credential in ipairs(invalidCredentials) do
    self:credentialWasDeleted(credential)
  end
end

--
-- Finaliza o serviço
--
function RegistryService:shutdown()
  log:service("Pedido de shutdown para serviço de registro")
  if not self.started then
    log:error("Servico ja foi finalizado.")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false
 
  -- Remove o observador
  if self.observerId then
    self.accessControlService:removeObserver(self.observerId)
    self.observer:_deactivate()
  end

  self.connectionManager:disconnect()

  log:service("Serviço de registro finalizado")
end
