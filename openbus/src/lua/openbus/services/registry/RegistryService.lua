-- $Id$

local os = os
local table = table

local loadfile = loadfile
local assert = assert
local pairs = pairs
local ipairs = ipairs
local next = next
local error = error

local luuid = require "uuid"
local oil = require "oil"

local OffersDB = require "openbus.services.registry.OffersDB"
local ClientInterceptor = require "openbus.common.ClientInterceptor"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"
local ServiceConnectionManager =
    require "openbus.common.ServiceConnectionManager"

local Log = require "openbus.common.Log"

local IComponent = require "scs.core.IComponent"

local oop = require "loop.simple"

---
--Componente (membro) respons�vel pelo Servi�o de Registro.
---
module("openbus.services.registry.RegistryService")

oop.class(_M, IComponent)

---
--Cria um Servi�o de Registro.
--
--@param name O nome do componente.
--@param config As configura��es do componente.
--
--@return O Servi�o de Registro.
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
  Log:service("Pedido de startup para servi�o de registro")

  -- Se � o primeiro startup, deve instanciar ConnectionManager e
  -- instalar interceptadores
  if not self.initialized then
    Log:service("Servi�o de registro est� inicializando")
    local credentialManager = CredentialManager()
    self.connectionManager =  ServiceConnectionManager(
        self.config.accessControlServerHost, credentialManager,
        self.config.privateKeyFile,
        self.config.accessControlServiceCertificateFile)

    -- obt�m a refer�ncia para o Servi�o de Controle de Acesso
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
    Log:service("Servi�o de registro j� foi inicializado")
  end

  -- Inicializa o reposit�rio de ofertas
  self.offersByIdentifier = {}   -- id -> oferta
  self.offersByType = {}         -- tipo -> id -> oferta
  self.offersByCredential = {}  -- credencial -> id -> oferta

  -- autentica o servi�o, conectando-o ao barramento
  local success = self.connectionManager:connect(self.componentId.name,
      function() self.wasReconnected(self) end)
  if not success then
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- atualiza a refer�ncia junto ao servi�o de controle de acesso
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
    -- somente recupera ofertas de credenciais v�lidas
    if self.accessControlService:isValid(offerEntry.credential) then
      self:addOffer(offerEntry)
    else
      Log:service("Oferta de "..offerEntry.credential.identifier.." descartada")
      self.offersDB:delete(offerEntry)
    end
  end

  self.started = true
  Log:service("Servi�o de registro iniciado")
end

---
--Registra uma nova oferta de servi�o. A oferta de servi�o � representada por
--uma tabela com os campos:
--   type: tipo da oferta (string)
--   description: descri��o (textual) da oferta
--   properties: lista de propriedades associadas � oferta (opcional)
--               cada propriedade � um par nome/valor (lista de strings)
--   member: refer�ncia para o membro que faz a oferta
--
--@param serviceOffer A oferta de servi�o.
--
--@return true e o identificador do registro da oferta em caso de sucesso, ou
--false caso contr�rio.
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

  Log:service("Registrando oferta com tipo "..serviceOffer.type..
              " id "..identifier)

  self:addOffer(offerEntry)
  self.offersDB:insert(offerEntry)

  return true, identifier
end

---
--Adiciona uma oferta ao reposit�rio.
--
--@param offerEntry A oferta.
---
function addOffer(self, offerEntry)

  -- �ndice de ofertas por identificador
  self.offersByIdentifier[offerEntry.identifier] = offerEntry

  -- �ndice de ofertas por tipo
  local type = offerEntry.offer.type
  if not self.offersByType[type] then
    Log:service("Primeira oferta do tipo "..type)
    self.offersByType[type] = {}
  end
  self.offersByType[type][offerEntry.identifier] = offerEntry

  -- �ndice de ofertas por credencial
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
--Constr�i um conjunto com os valores das propriedades, para acelerar a busca.
--OBS: procedimento v�lido enquanto propriedade for lista de strings !!!
--
--@param offerProperties As propriedades da oferta de servi�o.
--@param member O membro dono das propriedades.
--
--@return As propriedades da oferta em uma tabela cuja chave � o nome da
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

  local memberName = member:getComponentId().name

  -- se n�o foi definida uma propriedade "facets", discriminando as facetas
  -- disponibilizadas, assume que todas as facetas do membro s�o oferecidas
  if not properties["facets"] then
    Log:service("Oferta de servi�o sem facetas para o membro "..memberName)
    local metaInterface = member:getFacetByName("IMetaInterface")
    if metaInterface then
      metaInterface = oil.narrow(metaInterface,
          "IDL:scs/core/IMetaInterface:1.0")
      local facet_descriptions = metaInterface:getFacets()
      if #facet_descriptions == 0 then
        Log:service("Membro "..memberName.." n�o possui facetas")
      else
        Log:service("Membro "..memberName.." possui facetas")
        properties["facets"] = {}
        for _,facet in ipairs(facet_descriptions) do
          properties["facets"][facet.name] = true
        end
      end
    end
  end
  return properties
end

---
--Remove uma oferta de servi�o.
--
--@param identifier A identifica��o da oferta de servi�o.
--
--@return true caso a oferta tenha sido removida, ou false caso contr�rio.
---
function unregister(self, identifier)
  Log:service("Removendo oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warning("Oferta a remover com id "..identifier.." n�o encontrada")
    return false
  end

  local credential = self.serverInterceptor:getCredential()
  if credential.identifier ~= offerEntry.credential.identifier then
    Log:warning("Oferta a remover("..identifier..
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
      Log:service("�ltima oferta do tipo "..type.." removida")
      self.offersByType[type] = nil
    end
  end

  -- Remove oferta do �ndice por credencial
  local credentialOffers = self.offersByCredential[credential.identifier]
  if credentialOffers then
    credentialOffers[identifier] = nil
  else
    Log:service("N�o h� ofertas a remover com credencial "..
                credential.identifier)
    return true
  end
  if not next(credentialOffers) then
    -- N�o h� mais ofertas associadas � credencial
    self.offersByCredential[credential.identifier] = nil
    Log:service("�ltima oferta da credencial: remove credencial do observador")
    self.accessControlService:removeCredentialFromObserver(self.observerId,
                                                         credential.identifier)
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
function update(self, identifier, properties)
  Log:service("Atualizando oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warning("Oferta a atualizar com id "..identifier.." n�o encontrada")
    return false
  end

  local credential = self.serverInterceptor:getCredential()
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
--Busca por ofertas de servi�o de um determinado tipo, que atendam aos
--crit�rios (propriedades) especificados. A especifica��o de crit�rios
--� opcional.
--
--@param type O tipo da oferta.
--@param criteria Os crit�rios da busca.
--
--@return As ofertas de servi�o que correspondem aos crit�rios.
---
function find(self, type, criteria)
  Log:service("Procurando oferta com tipo "..type)

  local selectedOffers = {}
  local candidateOfferEntries = self.offersByType[type]
  if candidateOfferEntries and next(candidateOfferEntries) then
    Log:service("H� ofertas para o tipo")
    -- Se n�o h� crit�rios, retorna todas as ofertas
    if #criteria == 0 then
      for id, offerEntry in pairs(candidateOfferEntries) do
        table.insert(selectedOffers, offerEntry.offer)
        Log:service("Sem crit�rio, encontrei "..#selectedOffers.." ofertas")
      end
    else
      -- H� crit�rios a verificar
      for id, offerEntry in pairs(candidateOfferEntries) do
        if self:meetsCriteria(criteria, offerEntry.properties) then
          table.insert(selectedOffers, offerEntry.offer)
        end
      end
     Log:service("Com crit�rio, encontrei "..#selectedOffers.." ofertas")
    end
  else
    Log:service("N�o h� ofertas para o tipo "..type)
  end

  return selectedOffers
end

---
--Verifica se uma oferta atende aos crit�rios de busca
--
--@param criteria Os crit�rios da busca.
--@param offerProperties As propriedades da oferta.
--
--@return true caso a oferta atenda aos crit�rios, ou false caso contr�rio.
---
function meetsCriteria(self, criteria, offerProperties)
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
function credentialWasDeleted(self, credential)
  Log:service("Remover ofertas da credencial deletada "..credential.identifier)
  local credentialOffers = self.offersByCredential[credential.identifier]
  self.offersByCredential[credential.identifier] = nil

  if credentialOffers then
    for identifier, offerEntry in pairs(credentialOffers) do
      self.offersByIdentifier[identifier] = nil
      Log:service("Removida oferta "..identifier.." do �ndice por id")

      local type = offerEntry.offer.type
      if self.offersByType[type] then
        self.offersByType[type][identifier] = nil
        Log:service("Removida oferta "..identifier..
                     " do �ndice por tipo "..type)
        if not next(self.offersByType[type]) then -- fim das ofertas desse tipo
          Log:service("�ltima oferta do tipo "..type.." removida")
          self.offersByType[type] = nil
        end
      end
      self.offersDB:delete(offerEntry)
    end
  else
    Log:service("N�o havia ofertas da credencial "..credential.identifier)
  end
end

---
--Gera uma identifica��o de oferta de servi�o.
--
--@return O identificador de oferta de servi�o.
---
function generateIdentifier()
    return luuid.new("time")
end

---
--Procedimento ap�s reconex�o do servi�o.
---
function wasReconnected(self)
 Log:service("Servi�o de registro foi reconectado")
 -- atualiza a refer�ncia junto ao servi�o de controle de acesso
  self.accessControlService:setRegistryService(self)

  -- registra novamente o observador de credenciais
  self.observerId =
    self.accessControlService:addObserver(self.observer, {})
 Log:service("Observador recadastrado")

  -- Mantem no repositorio apenas ofertas com credenciais v�lidas
  local offerEntries = self.offersByIdentifier
  local credentials = {}
  for _, offerEntry in pairs(offerEntries) do
    credentials[offerEntry.credential.identifier] = offerEntry.credential
  end
  local invalidCredentials = {}
  for credentialId, credential in pairs(credentials) do
    if not self.accessControlService:addCredentialToObserver(self.observerId,
                                                            credentialId) then
      Log:service("Ofertas de "..credentialId.." ser�o removidas")
      table.insert(invalidCredentials, credential)
    else
      Log:service("Ofertas de "..credentialId.." ser�o mantidas")
    end
  end
  for _, credential in ipairs(invalidCredentials) do
    self:credentialWasDeleted(credential)
  end
end

---
--Finaliza o servi�o.
--
--@see scs.core.IComponent#shutdown
---
function shutdown(self)
  Log:service("Pedido de shutdown para servi�o de registro")
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

  Log:service("Servi�o de registro finalizado")
end
