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

local luuid = require "uuid"
local oil = require "oil"
local orb = oil.orb

local TableDB  = require "openbus.util.TableDB"
local OffersDB = require "core.services.registry.OffersDB"
local Openbus  = require "openbus.Openbus"

local Log = require "openbus.util.Log"
local oop = require "loop.simple"

---
--Componente (membro) responsável pelo Serviço de Registro.
---
module("core.services.registry.RegistryService")

------------------------------------------------------------------------------
-- Faceta IRegistryService
------------------------------------------------------------------------------

RSFacet = oop.class{}

---
--Registra uma nova oferta de serviço. A oferta de serviço é representada por
--uma tabela com os campos:
--   properties: lista de propriedades associadas à oferta (opcional)
--               cada propriedade é um par nome/valor (lista de strings)
--   member: refeêrncia para o membro que faz a oferta
--
--@param serviceOffer A oferta de serviço.
--
--@return true e o identificador do registro da oferta em caso de sucesso, ou
--false caso contrário.
---
function RSFacet:register(serviceOffer)
  local identifier = self:generateIdentifier()
  local credential = Openbus:getInterceptedCredential()
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
    Log:service(format(
      "Membro '%s' (%s) não disponibiliza a interface IMetaInterface.",
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
function RSFacet:addOffer(offerEntry)

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
  local accessControlService = self.context.AccessControlServiceReceptacle
  accessControlService:addCredentialToObserver(self.observerId,
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
-- @result Índice de facetas disponíveis do membro.
--
function RSFacet:createFacetIndex(owner, memberName, allFacets)
  local count = 0
  local facets = {}
  local mgm = self.context.IManagement
  for _, facet in ipairs(allFacets) do
    if mgm:hasAuthorization(owner, facet.interface_name) then
      facets[facet.name] = true
      facets[facet.interface_name] = true
      count = count + 1
    end
  end
  Log:service(format("Membro '%s' (%s) possui %d faceta(s) autorizada(s).",
    memberName, owner, count))
  return facets
end

---
--Remove uma oferta de serviço.
--
--@param identifier A identificação da oferta de serviço.
--
--@return true caso a oferta tenha sido removida, ou false caso contrário.
---
function RSFacet:unregister(identifier)
  Log:service("Removendo oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warning("Oferta a remover com id "..identifier.." não encontrada")
    return false
  end

  local credential = Openbus:getInterceptedCredential()
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
  if not next (credentialOffers) then
    -- Não há mais ofertas associadas à credencial
    self.offersByCredential[credential.identifier] = nil
    Log:service("Última oferta da credencial: remove credencial do observador")
    local accessControlService = self.context.AccessControlServiceReceptacle
    accessControlService:removeCredentialFromObserver(self.observerId,
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
function RSFacet:update(identifier, properties)
  Log:service("Atualizando oferta "..identifier)

  local offerEntry = self.offersByIdentifier[identifier]
  if not offerEntry then
    Log:warning("Oferta a atualizar com id "..identifier.." não encontrada")
    return false
  end

  local credential = Openbus:getInterceptedCredential()
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
-- Atualiza as ofertas de facetas do membro.
--
-- @param owner Identificação do membro.
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
--Busca por ofertas de serviço que implementam as facetas descritas.
--Se nenhuma faceta for fornecida, todas as facetas são retornadas.
--
--@param facets As facetas da busca.
--
--@return As ofertas de serviço que foram encontradas.
---
function RSFacet:find(facets)
  local selectedOffers = {}
-- Se nenhuma faceta foi discriminada, todas as ofertas de serviço
-- são retornadas.
  if (#facets == 0) then
    for _, offerEntry in pairs(self.offersByIdentifier) do
      table.insert(selectedOffers, offerEntry.offer)
    end
  else
  -- Para cada oferta de serviço disponível, selecionar-se
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
     Log:service("Encontrei "..#selectedOffers.." ofertas "..
      "que implementam as facetas discriminadas.")
  end
  return selectedOffers
end

---
--Busca por ofertas de serviço que implementam as facetas descritas, e,
--que atendam aos critérios (propriedades) especificados.
--
--@param facets As facetas da busca.
--@param criteria Os critérios da busca.
--
--@return As ofertas de serviço que foram encontradas.
---
function RSFacet:findByCriteria(facets, criteria)
  local selectedOffers = {}
-- Se nenhuma faceta foi discriminada e nenhum critério foi
-- definido, todas as ofertas de serviço são retornadas.
  if (#facets == 0 and #criteria == 0) then
    for _, offerEntry in pairs(self.offersByIdentifier) do
      table.insert(selectedOffers, offerEntry.offer)
    end
  else
-- Para cada oferta de serviço disponível, seleciona-se
-- a oferta que implementa todas as facetas discriminadas,
-- e, possui todos os critérios especificados.
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
     Log:service("Com critério, encontrei "..#selectedOffers.." ofertas "..
      "que implementam as facetas discriminadas.")
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
function RSFacet:meetsCriteria(criteria, offerProperties)
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
function RSFacet:credentialWasDeleted(credential)
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
--Procedimento após reconexão do serviço.
---
function RSFacet:expired()
  Openbus:connectByCertificate(self.context._componentId.name,
      self.privateKeyFile, self.accessControlServiceCertificateFile)

  -- atualiza a referência junto ao serviço de controle de acesso
  local accessControlService = self.context.AccessControlServiceReceptacle
  accessControlService:setRegistryService(self)

  -- registra novamente o observador de credenciais
  self.observerId = accessControlService:addObserver(self.observer, {})
  Log:service("Observador recadastrado")

  -- Mantém no repositório apenas ofertas com credenciais válidas
  local offerEntries = self.offersByIdentifier
  local credentials = {}
  for _, offerEntry in pairs(offerEntries) do
    credentials[offerEntry.credential.identifier] = offerEntry.credential
  end
  local invalidCredentials = {}
  for credentialId, credential in pairs(credentials) do
    if not accessControlService:addCredentialToObserver(self.observerId,
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

  Log:service("Serviço de registro foi reconectado")
end

---
--Gera uma identificação de oferta de serviço.
--
--@return O identificador de oferta de serviço.
---
function RSFacet:generateIdentifier()
    return luuid.new("time")
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
  Log:service("Pedido de startup para serviço de registro")
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")

  local mgm = self.context.IManagement
  local rs = self.context.IRegistryService
  local config = rs.config

  -- Verifica se é o primeiro startup
  if not rs.initialized then
    Log:service("Serviço de registro está inicializando")
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
    Log:service("Serviço de registro já foi inicializado")
  end

  -- Inicializa o repositório de ofertas
  rs.offersByIdentifier = {}   -- id -> oferta
  rs.offersByCredential = {}  -- credencial -> id -> oferta

  -- autentica o serviço, conectando-o ao barramento
  if not Openbus:isConnected() then
    Openbus:connectByCertificate(self.context._componentId.name,
      rs.privateKeyFile, rs.accessControlServiceCertificateFile)
  end

  -- Cadastra callback para LeaseExpired
  Openbus:addLeaseExpiredCallback( rs )

  -- obtém a referência para o Serviço de Controle de Acesso
  local accessControlService = Openbus:getAccessControlService()
  if not accessControlService then
    error{"IDL:SCS/StartupFailed:1.0"}
  end
  local acsIComp = accessControlService:_component()
  acsIComp = orb:narrow(acsIComp, "IDL:scs/core/IComponent:1.0")

  -- conecta-se ao controle de acesso:   [ACS]--( 0--[RS]
  local acsIReceptacles =  acsIComp:getFacetByName("IReceptacles")
  acsIReceptacles = orb:narrow(acsIReceptacles, "IDL:scs/core/IReceptacles:1.0")
  local success, conId =
    oil.pcall(acsIReceptacles.connect, acsIReceptacles,
              "RegistryServiceReceptacle", self.context.IRegistryService )
  if not success then
    Log:error("Erro durante conexão do serviço ao Controle de Acesso.")
    Log:error(conId)
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- conecta-se com o controle de acesso:   [RS]--( 0--[ACS]
  local acsFacet = acsIComp:getFacetByName("IAccessControlService")
  acsFacet = orb:narrow(acsFacet,"IDL:openbusidl/acs/IAccessControlService:1.0")
  success, conId =
    oil.pcall(self.context.IReceptacles.connect, self.context.IReceptacles,
              "AccessControlServiceReceptacle", acsFacet)
  if not success then
    Log:error("Erro durante conexão com serviço de Controle de Acesso.")
    Log:error(conId)
    error{"IDL:SCS/StartupFailed:1.0"}
  end

  -- registra um observador de credenciais
  local observer = {
    registryService = rs,
    credentialWasDeleted = function(self, credential)
      Log:service("Observador notificado para credencial "..
                  credential.identifier)
      self.registryService:credentialWasDeleted(credential)
    end
  }
  rs.observer = orb:newservant(observer, "RegistryServiceCredentialObserver",
    "IDL:openbusidl/acs/ICredentialObserver:1.0"
  )
  rs.observerId =
    acsFacet:addObserver(rs.observer, {})
  Log:service("Cadastrado observador para a credencial")

  -- recupera ofertas persistidas
  Log:service("Recuperando ofertas persistidas")
  local offerEntriesDB = rs.offersDB:retrieveAll()
  for _, offerEntry in pairs(offerEntriesDB) do
    -- somente recupera ofertas de credenciais válidas
    if acsFacet:isValid(offerEntry.credential) then
      rs:addOffer(offerEntry)
    else
      Log:service("Oferta de "..offerEntry.credential.identifier.." descartada")
      rs.offersDB:delete(offerEntry)
    end
  end

  -- Referência à faceta de gerenciamento do ACS
  mgm.acsmgm = acsIComp:getFacetByName("IManagement")
  mgm.acsmgm = orb:narrow(mgm.acsmgm, "IDL:openbusidl/acs/IManagement:1.0")
  -- Administradores dos serviços
  mgm.admins = {}
  for _, name in ipairs(config.administrators) do
     mgm.admins[name] = true
  end
  -- ACS é sempre administrador
  mgm.admins.AccessControlService = true
  -- Inicializa a base de gerenciamento
  mgm.authDB = TableDB(DATA_DIR.."/rs_auth.db")
  mgm.ifaceDB = TableDB(DATA_DIR.."/rs_iface.db")
  mgm:loadData()

  rs.started = true
  self.context.IFaultTolerantService:setStatus(true)
  
  Log:service("Serviço de registro iniciado")
end

---
--Finaliza o serviço.
--
--@see scs.core.IComponent#shutdown
---
function shutdown(self)
  Log:service("Pedido de shutdown para serviço de registro")
  local rs = self.context.IRegistryService
  if not rs.started then
    Log:error("Servico ja foi finalizado.")
    error{"IDL:SCS/ShutdownFailed:1.0"}
  end
  rs.started = false

  -- Remove o observador
  if rs.observerId then
    self.context.AccessControlServiceReceptacle:removeObserver(rs.observerId)
    rs.observer:_deactivate()
  end

  if Openbus:isConnected() then
    Openbus:disconnect()
  end

  Log:service("Serviço de registro finalizado")
  
   orb:deactivate(rs)
   orb:deactivate(self.context.IManagement)
   orb:shutdown()
   Log:faulttolerance("Servico de Registro matou seu processo.")
end

--------------------------------------------------------------------------------
-- Faceta IManagement
--------------------------------------------------------------------------------

ManagementFacet = oop.class{}

---
-- Verifica se o usuário tem permissão para executar o método.
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
  -- Carrega as autorizações.
  -- Verificar junto ao ACS se as implantações ainda existem.
  local remove = {}
  data = assert(self.authDB:getValues())
  for _, auth in ipairs(data) do
    local succ, depl = self.acsmgm.__try:getSystemDeployment(auth.deploymentId)
    if not succ then
      if depl[1] == "IDL:openbusidl/acs/SystemDeploymentNonExistent:1.0" then
        remove[auth] = true
        Log:warn(format("Removendo autorizações de '%s': " ..
          "removida do Serviço de Controle de Acesso.", auth.deploymentId))
      else
        error(depl)  -- Exceção desconhecida, repassando
      end
    elseif depl.systemId ~= auth.systemId then
      remove[auth] = true
      Log:warn(format("Removendo autorizações de '%s': " ..
        " identificador de sistema difere.", auth.deploymentId))
    else
      self.authorizations[auth.deploymentId] = auth
    end
  end
  for auth in pairs(remove) do
    self.authDB:remove(auth.deploymentId)
  end
end

---
-- Cadastra um identificador de interface aceito pelo Serviço de Registro.
--
-- @param ifaceId Identificador de interface.
--
function ManagementFacet:addInterfaceIdentifier(ifaceId)
  self:checkPermission()
  if self.interfaces[ifaceId] then
    Log:error(format("Interface '%s' já cadastrada.", ifaceId))
    error{"IDL:openbusidl/rs/InterfaceIdentifierAlreadyExists:1.0"}
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
    Log:error(format("Interface '%s' não está cadastrada.", ifaceId))
    error{"IDL:openbusidl/rs/InterfaceIdentifierNonExistent:1.0"}
  end
  for _, auth in ipairs(self.authorizations) do
    if auth.authorized[ifaceId] then
      Log:error(format("Interface '%s' em uso.", ifaceId))
      error{"IDL:openbusidl/rs/InterfaceIdentifierInUse:1.0"}
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
-- @return Seqüência de identificadores de interface.
--
function ManagementFacet:getInterfaceIdentifiers()
  local array = {}
  for iface in pairs(self.interfaces) do
    array[#array+1] = iface
  end
  return array
end

---
-- Autoriza a implantação a exportar a interface.  O Serviço de Acesso
-- é consultado para verificar se a implantação está cadastrada.
--
-- @param deploymentId Identificador da implantação.
-- @param ifaceId Identificador da interface.
--
function ManagementFacet:grant(deploymentId, ifaceId)
  self:checkPermission()
  if not self.interfaces[ifaceId] then
    Log:error(format("Interface '%s' não cadastrada.", ifaceId))
    error{"IDL:openbusidl/rs/InterfaceIdentifierNonExistent:1.0"}
  end
  local auth = self.authorizations[deploymentId]
  if not auth then 
    -- Cria uma nova autorização: verificar junto ao ACS se implantação existe.
    local succ, depl = self.acsmgm.__try:getSystemDeployment(deploymentId)
    if not succ then
      Log:error(format("Implementação '%s' não cadastrada.",
        deploymentId))
      error{"IDL:openbusidl/rs/SystemDeploymentNonExistent:1.0"}
    end
    auth = {
      deploymentId = deploymentId,
      systemId = depl.systemId,
      authorized = {},
    }
    self.authorizations[deploymentId] = auth
  elseif auth and auth.authorized[ifaceId] then
    return
  end
  auth.authorized[ifaceId] = true
  local succ, msg = self.authDB:save(deploymentId, auth)
  if not succ then
    Log:error(format("Falha ao salvar autorização '%s': %s",
      deploymentId, msg))
  end
  self.context.IRegistryService:updateFacets(deploymentId)
end

---
-- Revoga a autorização para exportar a interface.
--
-- @param deploymentId Identificador da implantação.
-- @param ifaceId Identificador da interface.
--
function ManagementFacet:revoke(deploymentId, ifaceId)
  self:checkPermission()
  local auth = self.authorizations[deploymentId]
  if not auth then
    Log:error(format("Não há autorização para '%s'.", deploymentId))
    error{"IDL:openbusidl/rs/AuthorizationNonExistent:1.0"}
  elseif not self.interfaces[ifaceId] then
    Log:error(format("Interface '%s' não cadastrada.", ifaceId))
    error{"IDL:openbusidl/rs/InterfaceIdentifierNonExistent:1.0"}
  elseif auth.authorized[ifaceId] then
    local succ, msg
    auth.authorized[ifaceId] = nil
    -- Se não houver mais autorizações, remover a entrada
    if next(auth.authorized) then
      succ, msg = self.authDB:save(deploymentId, auth)
    else
      self.authorizations[deploymentId] = nil
      succ, msg = self.authDB:remove(deploymentId)
    end
    if not succ then
      Log:error(format("Falha ao remover autorização '%s': %s",
        deploymentId, msg))
    end
    self.context.IRegistryService:updateFacets(deploymentId)
  end
end

---
-- Remove a autorização da implantação.
--
-- @param deploymentId Identificador da implantação.
--
function ManagementFacet:removeAuthorization(deploymentId)
  self:checkPermission()
  if not self.authorizations[deploymentId] then
    Log:error(format("Não há autorização para '%s'.", deploymentId))
    error{"IDL:openbusidl/rs/AuthorizationNonExistent:1.0"}
  else
    self.authorizations[deploymentId] = nil
    local succ, msg = self.authDB:remove(deploymentId)
    if not succ then
      Log:error(format("Falha ao remover autorização '%s': %s",
        deploymentId, msg))
    end
    self.context.IRegistryService:updateFacets(deploymentId)
  end
end

---
-- Duplica a autorização, mas a lista de interfaces é retornada
-- como array e não como hash. Essa função é usada para exportar
-- a autorização.
--
-- @param auth Autorização a ser duplicada.
-- @return Cópia da autorização.
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
-- Verifica se a implantação é autorizada a exporta 
-- uma determinada interface.
--
-- @param deploymentId Identificador da implantação.
-- @param iface Interface a ser consultada (repID).
--
-- @return true se é autorizada, false caso contrário.
--
function ManagementFacet:hasAuthorization(deploymentId, iface)
  local auth = self.authorizations[deploymentId]
  return ((auth and auth.authorized[iface]) and true) or false
end

---
-- Recupera a autorização de uma implantação.
--
-- @param deploymentId Identificador da implantação.
--
-- @return Autorização da implantação.
--
function ManagementFacet:getAuthorization(deploymentId)
  local auth = self.authorizations[deploymentId]
  if not auth then
    Log:error(format("Não há autorização para '%s'.", deploymentId))
    error{"IDL:openbusidl/rs/AuthorizationNonExistent:1.0"}
  end
  return self:copyAuthorization(auth)
end

---
-- Recupera todas as autorizações cadastradas.
--
-- @return Seqüência de autorizações.
--
function ManagementFacet:getAuthorizations()
  local array = {}
  for _, auth in pairs(self.authorizations) do
    array[#array+1] = self:copyAuthorization(auth)
  end
  return array
end

---
-- Recupera as autorizações das implantações de um dado sistema.
--
-- @param systemId Identificador do sistema.
--
-- @return Seqüência de autorizações.
--
function ManagementFacet:getAuthorizationsBySystemId(systemId)
  local array = {}
  for _, auth in pairs(self.authorizations) do
    if systemId == auth.systemId then
      array[#array+1] = self:copyAuthorization(auth)
    end
  end
  return array
end

---
-- Recupera as autorizações que contêm \e todas as interfaces
-- fornecidas em seu conjunto de interfaces autorizadas.
--
-- @param systemId Identificador do sistema.
--
-- @return Seqüência de autorizações.
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
