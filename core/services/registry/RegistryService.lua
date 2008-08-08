-- $Id$

local os = os
local table = table

local loadfile = loadfile
local assert = assert
local pairs = pairs
local ipairs = ipairs
local error = error

local luuid = require "uuid"
local oil = require "oil"

local OffersDB = require "core.services.registry.OffersDB"
local ClientInterceptor = require "openbus.common.ClientInterceptor"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"
local ServerConnectionManager =
    require "openbus.common.ServerConnectionManager"

local Log = require "openbus.common.Log"

local IComponent = require "scs.core.IComponent"

local oop = require "loop.simple"

---
--Componente (membro) responsável pelo Serviço de Registro.
---
module("core.services.registry.RegistryService")

oop.class(_M, IComponent)

---
--Cria um Serviço de Registro.
--
--@param name O nome do componente.
--@param config As configurações do componente.
--
--@return O Serviço de Registro.
---
function __init(self, name, config)
  local component = IComponent:__init(name, 1)
  component.config = config
  return oop.rawnew(self, component)
end

---
--Inicia o componente.
--
--@see scs.core.IComponent#startup
---
function startup(self)
  Log:service("Pedido de startup para serviço de registro")

  -- Se é o primeiro startup, deve instanciar ConnectionManager e
  -- instalar interceptadores
  if not self.initialized then
    Log:service("Serviço de registro está inicializando")
    local credentialManager = CredentialManager()
    self.connectionManager =  ServerConnectionManager(
        self.config.accessControlServerHost, credentialManager,
        self.config.privateKeyFile,
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
      ClientInterceptor(interceptorsConfig, credentialManager))

    -- instala o interceptador servidor
    self.serverInterceptor = ServerInterceptor(interceptorsConfig, self.accessControlService)
    oil.setserverinterceptor(self.serverInterceptor)

    -- instancia mecanismo de persistencia
    self.offersDB = OffersDB(self.config.databaseDirectory)
    self.initialized = true
  else
    Log:service("Serviço de registro já foi inicializado")
  end

  -- Inicializa o repositório de ofertas
  self.offersByIdentifier = {}   -- id -> oferta
  self.offersByCredential = {}  -- credencial -> id -> oferta

  -- autentica o serviço, conectando-o ao barramento
  local success = self.connectionManager:connect(self.componentId.name,
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
      Log:service("Observador notificado para credencial "..
                  credential.identifier)
      self.registryService:credentialWasDeleted(credential)
    end
  }
  self.observer = oil.newservant(observer,
                                "IDL:openbusidl/acs/ICredentialObserver:1.0",
                                "RegistryServiceCredentialObserver")
  self.observerId =
    self.accessControlService:addObserver(self.observer, {})
  Log:service("Cadastrado observador para a credencial")

  -- recupera ofertas persistidas
  Log:service("Recuperando ofertas persistidas")
  local offerEntriesDB = self.offersDB:retrieveAll()
  for _, offerEntry in pairs(offerEntriesDB) do
    -- somente recupera ofertas de credenciais válidas
    if self.accessControlService:isValid(offerEntry.credential) then
      self:addOffer(offerEntry)
    else
      Log:service("Oferta de "..offerEntry.credential.identifier.." descartada")
      self.offersDB:delete(offerEntry)
    end
  end

  self.started = true
  Log:service("Serviço de registro iniciado")
end

---
--Registra uma nova oferta de serviço. A oferta de serviço  representada por
--uma tabela com os campos:
--   type: tipo da oferta (string)
--   description: descrição (textual) da oferta
--   properties: lista de propriedades associadas à oferta (opcional)
--               cada propriedade é um par nome/valor (lista de strings)
--   member: refeêrncia para o membro que faz a oferta
--
--@param serviceOffer A oferta de serviço.
--
--@return true e o identificador do registro da oferta em caso de sucesso, ou
--false caso contrário.
---
function register(self, serviceOffer)
  local identifier = self:generateIdentifier()
  local credential = self.serverInterceptor:getCredential()

  local offerEntry = {
    offer = serviceOffer,
    properties = self:createPropertyIndex(serviceOffer.properties,
                                          serviceOffer.member),
    credential = credential,
    identifier = identifier
  }

  Log:service("Registrando oferta com id "..identifier)

  self:addOffer(offerEntry)
  self.offersDB:insert(offerEntry)

  return true, identifier
end

---
--Adiciona uma oferta ao repositório.
--
--@param offerEntry A oferta.
---
function addOffer(self, offerEntry)

  -- Índice de ofertas por identificador
  self.offersByIdentifier[offerEntry.identifier] = offerEntry

  -- Índice de ofertas por credencial
  local credential = offerEntry.credential
  if not self.offersByCredential[credential.identifier] then
    Log:service("Primeira oferta da credencial "..credential.identifier)
    self.offersByCredential[credential.identifier] = {}
  end
  self.offersByCredential[credential.identifier][offerEntry.identifier] =
    offerEntry

  -- A credencial deve ser observada, porque se for deletada as
  -- ofertas a ela relacionadas devem ser removidas
  self.accessControlService:addCredentialToObserver(self.observerId,
                                                    credential.identifier)
  Log:service("Adicionada credencial no observador")
end

---
--Constrói um conjunto com os valores das propriedades, para acelerar a busca.
--OBS: procedimento válido enquanto propriedade for lista de strings !!!
--
--@param offerProperties As propriedades da oferta de serviço.
--@param member O membro dono das propriedades.
--
--@return As propriedades da oferta em uma tabela cuja chave é o nome da
--propriedade.
---
function createPropertyIndex(self, offerProperties, member)
  local properties = {}
  for _, property in ipairs(offerProperties) do
    properties[property.name] = {}
    for _, val in ipairs(property.value) do
      properties[property.name][val] = true
    end
  end

  local componentId = member:getComponentId()
  properties["component_id"] = {}
  properties["component_id"][componentId.name..":"..componentId.version] = true

  local memberName = componentId.name
  -- se não foi definida uma propriedade "facets", discriminando as facetas
  -- disponibilizadas, assume que todas as facetas do membro são oferecidas
  if not properties["facets"] then
    Log:service("Oferta de serviço sem facetas para o membro "..memberName)
    local metaInterface = member:getFacetByName("IMetaInterface")
    if metaInterface then
      metaInterface = oil.narrow(metaInterface,
          "IDL:scs/core/IMetaInterface:1.0")
      local facet_descriptions = metaInterface:getFacets()
      if #facet_descriptions == 0 then
        Log:service("Membro "..memberName.." não possui facetas")
      else
        Log:service("Membro "..memberName.." possui facetas")
        properties["facets"] = {}
        for _,facet in ipairs(facet_descriptions) do
          properties["facets"][facet.name] = true
        end
      end
    else
      Log:service("Membro "..memberName.." não disponibiliza a interface"..
          " IMetaInterface.")
    end
  end
  return properties
end

---
--Remove uma oferta de serviço.
--
--@param identifier A identificação da oferta de serviço.
--
--@return true caso a oferta tenha sido removida, ou false caso contrário.
---
function unregister(self, identifier)
  Log:service("Removendo oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warning("Oferta a remover com id "..identifier.." não encontrada")
    return false
  end

  local credential = self.serverInterceptor:getCredential()
  if credential.identifier ~= offerEntry.credential.identifier then
    Log:warning("Oferta a remover("..identifier..
                ") não registrada com a credencial do chamador")
    return false -- esse tipo de erro merece uma exceção!
  end

  -- Remove oferta do índice por identificador
  self.offersByIdentifier[identifier] = nil

  -- Remove oferta do índice por credencial
  local credentialOffers = self.offersByCredential[credential.identifier]
  if credentialOffers then
    credentialOffers[identifier] = nil
  else
    Log:service("Não há ofertas a remover com credencial "..
                credential.identifier)
    return true
  end
  if #credentialOffers == 0 then
    -- Não há mais ofertas associadas à credencial
    self.offersByCredential[credential.identifier] = nil
    Log:service("Última oferta da credencial: remove credencial do observador")
    self.accessControlService:removeCredentialFromObserver(self.observerId,
                                                         credential.identifier)
  end
  self.offersDB:delete(offerEntry)
  return true
end

---
--Atualiza a oferta de serviço associada ao identificador especificado. Apenas
--as propriedades da oferta podem ser atualizadas (nessa versão, substituidas).
--
--@param identifier O identificador da oferta.
--@param properties As novas propriedades da oferta.
--
--@return true caso a oferta seja atualizada, ou false caso contrário.
---
function update(self, identifier, properties)
  Log:service("Atualizando oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warning("Oferta a atualizar com id "..identifier.." não encontrada")
    return false
  end

  local credential = self.serverInterceptor:getCredential()
  if credential.identifier ~= offerEntry.credential.identifier then
    Log:warning("Oferta a atualizar("..identifier..
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

---
--Busca por ofertas de serviço de um determinado tipo, que atendam aos
--critérios (propriedades) especificados. A especificação de critrios
--é opcional.
--
--@param criteria Os critérios da busca.
--
--@return As ofertas de serviço que correspondem aos critérios.
---
function find(self, criteria)
  local selectedOffers = {}
  if #criteria == 0 then
    for _, offerEntry in pairs(self.offersByIdentifier) do
      table.insert(selectedOffers, offerEntry.offer)
    end
  else
    for _, offerEntry in pairs(self.offersByIdentifier) do
      if self:meetsCriteria(criteria, offerEntry.properties) then
        table.insert(selectedOffers, offerEntry.offer)
      end
    end
     Log:service("Com critério, encontrei "..#selectedOffers.." ofertas")
  end
  return selectedOffers
end

---
--Verifica se uma oferta atende aos critérios de busca
--
--@param criteria Os critérios da busca.
--@param offerProperties As propriedades da oferta.
--
--@return true caso a oferta atenda aos critérios, ou false caso contrário.
---
function meetsCriteria(self, criteria, offerProperties)
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

---
--Notificação de deleção de credencial. As ofertas de serviço relacionadas
--deverão ser removidas.
--
--@param credential A credencial removida.
---
function credentialWasDeleted(self, credential)
  Log:service("Remover ofertas da credencial deletada "..credential.identifier)
  local credentialOffers = self.offersByCredential[credential.identifier]
  self.offersByCredential[credential.identifier] = nil

  if credentialOffers then
    for identifier, offerEntry in pairs(credentialOffers) do
      self.offersByIdentifier[identifier] = nil
      Log:service("Removida oferta "..identifier.." do índice por id")
      self.offersDB:delete(offerEntry)
    end
  else
    Log:service("Não havia ofertas da credencial "..credential.identifier)
  end
end

---
--Gera uma identificação de oferta de serviço.
--
--@return O identificador de oferta de serviço.
---
function generateIdentifier()
    return luuid.new("time")
end

---
--Procedimento após reconexão do serviço.
---
function wasReconnected(self)
 Log:service("Serviço de registro foi reconectado")
 -- atualiza a referência junto ao serviço de controle de acesso
  self.accessControlService:setRegistryService(self)

  -- registra novamente o observador de credenciais
  self.observerId =
    self.accessControlService:addObserver(self.observer, {})
 Log:service("Observador recadastrado")

  -- Mantém no repositório apenas ofertas com credenciais válidas
  local offerEntries = self.offersByIdentifier
  local credentials = {}
  for _, offerEntry in pairs(offerEntries) do
    credentials[offerEntry.credential.identifier] = offerEntry.credential
  end
  local invalidCredentials = {}
  for credentialId, credential in pairs(credentials) do
    if not self.accessControlService:addCredentialToObserver(self.observerId,
                                                            credentialId) then
      Log:service("Ofertas de "..credentialId.." serão removidas")
      table.insert(invalidCredentials, credential)
    else
      Log:service("Ofertas de "..credentialId.." serão mantidas")
    end
  end
  for _, credential in ipairs(invalidCredentials) do
    self:credentialWasDeleted(credential)
  end
end

---
--Finaliza o serviço.
--
--@see scs.core.IComponent#shutdown
---
function shutdown(self)
  Log:service("Pedido de shutdown para serviço de registro")
  if not self.started then
    Log:error("Servico ja foi finalizado.")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  self.started = false

  -- Remove o observador
  if self.observerId then
    self.accessControlService:removeObserver(self.observerId)
    self.observer:_deactivate()
  end

  self.connectionManager:disconnect()

  Log:service("Serviço de registro finalizado")
end
