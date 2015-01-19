local _G = require "_G"
local setmetatable = _G.setmetatable
local tostring = _G.tostring

local array = require "table"
local concat = array.concat

local math = require "math"
local inf = math.huge

local cothread = require "cothread"
local suspend = cothread.suspend

local giop = require "oil.corba.giop"
local sysexrepid = giop.SystemExceptionIDs

local oo = require "openbus.util.oo"
local class = oo.class
local isinstanceof = oo.isinstanceof

local server = require "openbus.util.server"
local readfile = server.readfrom
local readprivatekey = server.readprivatekey
local argcheck = require "openbus.util.argcheck"
local convertmodule = argcheck.convertmodule

local assistant = require "openbus.assistant2"
local newassistant = assistant.create

local coreidl = require "openbus.core.idl"
local coresrvtypes = coreidl.types.services
local logintypes = coresrvtypes.access_control
local offertypes = coresrvtypes.offer_registry
local minor = coreidl.const.services.access_control

local admidl = require "openbus.core.admin.idl"
local loadadmidl = admidl.loadto
local admintypes = admidl.types.services.access_control.admin.v1_0
local authotypes = admidl.types.services.offer_registry.admin.v1_0

local msg = require "openbus.util.messages"
local argcheck = require "openbus.util.argcheck"


local ExceptionMessages = {
  [sysexrepid.TRANSIENT] = msg.BusCurrentlyInaccessible,
  [sysexrepid.COMM_FAILURE] = msg.BusCommunicationFailure,
  [sysexrepid.OBJECT_NOT_EXIST] = msg.DefinitionRemovedFromBus,
  [sysexrepid.NO_PERMISSION] = {
    [minor.InvalidCredentialCode] = msg.InvalidCredential,
    [minor.InvalidChainCode] = msg.InvalidChain,
    [minor.InvalidLoginCode] = msg.InvalidLogin,
    [minor.UnverifiedLoginCode] = msg.UnverifiedLogin,
    [minor.UnknownBusCode] = msg.UnknownBus,
    [minor.InvalidPublicKeyCode] = msg.InvalidPublicKey,
    [minor.NoCredentialCode] = msg.NoCredential,
    [minor.NoLoginCode] = msg.NoLogin,
    [minor.InvalidRemoteCode] = msg.InvalidRemote,
    [minor.UnavailableBusCode] = msg.UnavailableBus,
    [minor.InvalidTargetCode] = msg.InvalidTarget,
  },

  [coresrvtypes.ServiceFailure] = msg.BusFailure,
  [coresrvtypes.UnauthorizedOperation] = msg.PermissionDenied,

  [logintypes.InvalidPublicKey] = msg.GeneratedAccessKeyRefused,
  [logintypes.WrongEncoding] = msg.WrongBusPublicKey,
  [logintypes.AccessDenied] = msg.AccessDenied,
  [logintypes.UnknownDomain] = msg.UnknownPasswordDomain,
  [logintypes.TooManyAttempts] = msg.TooManyWrongPasswordAttempts,
  [logintypes.MissingCertificate] = msg.NoAuthenticationCertificate,

  [offertypes.InvalidProperties] = msg.UnableToOverwriteAutomaticProperties,

  [admintypes.InvalidCertificate] = msg.InvalidCertificate,

  [authotypes.InvalidInterface] = msg.InvalidInterface,
  [authotypes.InterfaceInUse] = msg.InterfaceInUse,
  [authotypes.AuthorizationInUse] = msg.AuthorizationInUse,
  [authotypes.EntityAlreadyRegistered] = msg.EntityAlreadyRegistered,
  [authotypes.EntityCategoryInUse] = msg.EntityCategoryInUse,
}

local argchecker = {} do
  local function continuation(ok, ...)
    if not ok then
      local except = ...
      local message = ExceptionMessages[except._repid]
      if type(message) == "table" then
        message = message[except.minor]
        if message ~= nil then
          except = message
        end
      elseif message ~= nil then
        except = message--:tag{error = tostring(except)}
      end
      error(except, 2)
    end
    return ...
  end
  local function except2MessageWrap(module, typedefs)
    for name in pairs(typedefs) do
      local func = assert(module[name])
      module[name] = function (...)
        return continuation(pcall(func, ...))
      end
    end
  end
  for kind, convert in pairs{
    module = argcheck.convertmodule,
    class = argcheck.convertclass,
  } do
    argchecker[kind] = function (module, typedefs)
      except2MessageWrap(module, typedefs)
      convert(module, typedefs)
    end
  end
end



local function gettext(message)
  io.write(message)
  io.flush()
  return io.read(message == "Password: " and "*?" or "*l")
end



local PrintableList = class()

function PrintableList:__tostring()
  local res = {}
  for index, item in ipairs(self) do
    res[index] = tostring(item)
  end
  return concat(res, "\n")
end

local function makelist(list, class)
  if class ~= nil then
    for _, item in ipairs(list) do
      class(item)
    end
  end
  return PrintableList(list)
end



local LoginInfo = class()

function LoginInfo:__tostring()
  return self.id.." "..self.entity
end



local ReservedProperties = {
  ["openbus.offer.id"] = "id",
  ["openbus.offer.login"] = "login",
  ["openbus.offer.entity"] = "entity",
  ["openbus.offer.timestamp"] = "timestamp",
  ["openbus.offer.year"] = "year",
  ["openbus.offer.month"] = "month",
  ["openbus.offer.day"] = "day",
  ["openbus.offer.hour"] = "hour",
  ["openbus.offer.minute"] = "minute",
  ["openbus.offer.second"] = "second",
  ["openbus.component.name"] = "compname",
  ["openbus.component.version.major"] = "majorversion",
  ["openbus.component.version.minor"] = "minorversion",
  ["openbus.component.version.patch"] = "patchversion",
  ["openbus.component.platform"] = "platform",
}
local PropertyAliases = {}
for name, alias in pairs(ReservedProperties) do
  PropertyAliases[alias] = name
end

local function makePropList(props)
  for alias, name in pairs(PropertyAliases) do
    local value = props[alias]
    if value ~= nil then
      props[#props+1] = {name=name,value=value}
      props[alias] = nil
    end
  end
  return props
end

local OfferProperties = class()

function OfferProperties:__tostring()
  local result = {}
  for index, prop in ipairs(self) do
    result[index] = prop.name..": "..prop.value
  end
  return concat(result, ";\n")
end

local ServiceOffer = class()

--TODO:
--function ServiceOffer:refresh()
--end

function ServiceOffer:__init()
  for _, prop in ipairs(self.properties) do
    local alias = ReservedProperties[prop.name]
    if alias ~= nil then
      self[alias] = prop.value
    end
  end
  OfferProperties(self.properties)
end

function ServiceOffer:__tostring()
  local result = self.stringfied
  if result == nil then
    result = 
      self.id.." "..
      self.year.."-"..
      self.month.."-"..
      self.day.." "..
      self.hour..":"..
      self.minute..":"..
      self.second.." "..
      self.compname.." v"..
      self.majorversion.."."..
      self.minorversion.."."..
      self.patchversion.." ("..
      self.platform..") by "..
      self.entity
    self.stringfied = result
  end
  return result
end



local RegisteredEntity = class()

function RegisteredEntity:__tostring()
  return self.id.." ("..self.name..")"
end

function RegisteredEntity:grant(iface)
  return self.ref:grantInterface(iface)
end

function RegisteredEntity:revoke(iface)
  return self.ref:revokeInterface(iface)
end

function RegisteredEntity:ifaces()
  return makelist(self.ref:getGrantedInterfaces())
end



local EntityCategory = class()

function EntityCategory:__tostring()
  return self.id.." ("..self.name..")"
end

function EntityCategory:entities()
  return makelist(self.ref:getEntities(), RegisteredEntity)
end

function EntityCategory:addentity(id, name)
  return RegisteredEntity(self.ref:registerEntity(id, name):describe())
end




local module = {}

function module.create(OpenBusORB, Configs, env)
  local OpenBusContext = OpenBusORB.OpenBusContext

  do
    loadadmidl(OpenBusORB)
    local CoreServices = {
      CertificateRegistry = admintypes,
      InterfaceRegistry = authotypes,
      EntityRegistry = authotypes,
    }
    for name, idlmod in pairs(CoreServices) do
      OpenBusContext["get"..name] = function (self)
        local conn = self:getCurrentConnection()
        if conn == nil or conn.login == nil then
          sysexthrow.NO_PERMISSION{
            completed = "COMPLETED_NO",
            minor = loginconst.NoLoginCode,
          }
        end
        return self.orb:narrow(conn.bus:getFacetByName(name), idlmod[name])
      end
    end
  end

  local function setDefaultConnection(conn)
    conn = OpenBusContext:setDefaultConnection(conn.connection)
    if conn ~= nil then
      return conn.assistant
    end
  end

  local function getCurrentConnection()
    local conn = OpenBusContext:getCurrentConnection()
    if conn ~= nil then
      return conn.assistant
    end
  end

  local createConnection
  if Configs.iorfile ~= "" then
    local busior = assert(readfile(Configs.iorfile, "r"))
    local busref = OpenBusORB:newproxy(busior, nil, "::scs::core::IComponent")
    function createConnection()
      return newassistant{
        orb = OpenBusORB,
        busref = busref,
      }
    end
  else
    function createConnection()
      return newassistant{
        orb = OpenBusORB,
        bushost = Configs.host,
        busport = Configs.port,
      }
    end
  end

  local function resolveCategory(category)
    local entities = OpenBusContext:getEntityRegistry()
    if type(category) == "string" then
      category = entities:getEntityCategory(category)
      if category ~= nil then
        category = category:describe()
      end
    elseif not isinstanceof(category, EntityCategory) then
      error("invalid entity category, got "..type(category))
    end
    return category and EntityCategory(category)
  end

  local function resolveEntity(entity)
    local entities = OpenBusContext:getEntityRegistry()
    if type(entity) == "string" then
      entity = entities:getEntity(entity)
      if entity ~= nil then
        entity = entity:describe()
      end
    elseif not isinstanceof(entity, RegisteredEntity) then
      error("invalid entity, got "..type(entity))
    end
    return entity and RegisteredEntity(entity)
  end

  function env.login(entity, secret, domain)
    local conn = createConnection()
    if secret ~= nil and domain == nil then
      conn:loginByCertificate(entity, readprivatekey(secret))
    else
      conn:loginByPassword(entity, secret or gettext("Password: "),
                                   domain or gettext("Domain: "))
    end
    conn = setDefaultConnection(conn)
    if conn ~= nil then
      conn:logout()
    end
  end

  function env.whoami()
    conn = getCurrentConnection()
    if conn ~= nil then
      local login = conn.login
      if login ~= nil then
        return LoginInfo(login)
      end
    end
  end

  function env.quit()
    conn = getCurrentConnection()
    if conn ~= nil then
      conn:logout()
    end
    OpenBusORB:shutdown()
    suspend()
  end

  function env.logins(entity)
    if isinstanceof(entity, LoginInfo) then entity = entity.entity end
    local logins = OpenBusContext:getLoginRegistry()
    local list = (entity == nil)
      and logins:getAllLogins()
      or logins:getEntityLogins(entity)
    return makelist(list, LoginInfo)
  end

  function env.kick(id)
    if isinstanceof(id, LoginInfo) then id = id.id end
    OpenBusContext:getLoginRegistry():invalidateLogin(id)
  end

  function env.offers(properties)
    local offers = OpenBusContext:getOfferRegistry()
    local list = (properties == nil)
      and offers:getAllServices()
      or offers:findServices(makePropList(properties))
    return makelist(list, ServiceOffer)
  end

  function env.deloffer(offer)
    if type(offer) == "string" then
      local props = {{name="openbus.offer.id",value=id}}
      offer = OpenBusContext:getOfferRegistry():findServices(props)[1]
      if offer == nil then
        return nil, "not found"
      end
    end
    offer.ref:remove()
    return true
  end

  function env.certents()
    local certs = OpenBusContext:getCertificateRegistry()
    return makelist(certs:getEntitiesWithCertificate())
  end

  function env.delcert(entity)
    local certs = OpenBusContext:getCertificateRegistry()
    return certs:removeCertificate(entity)
  end

  function env.setcert(entity, path)
    local certificate = assert(readfile(path))
    local certs = OpenBusContext:getCertificateRegistry()
    return certs:registerCertificate(entity, certificate)
  end

  function env.getcert(entity)
    local certs = OpenBusContext:getCertificateRegistry()
    local ok, result = pcall(certs.getCertificate, certs, entity)
    if not ok then
      if not is_MissingCertificate(result) then
        error(result)
      end
      result = nil
    end
    return result
  end

  function env.categories(category)
    local entities = OpenBusContext:getEntityRegistry()
    return makelist(entities:getEntityCategories(), EntityCategory)
  end

  env.getcategory = resolveCategory

  function env.setcategory(category, name)
    category = resolveCategory(category)
    if category == nil then
      local entities = OpenBusContext:getEntityRegistry()
      category = entities:createEntityCategory(id, name)
      return EntityCategory(category:describe())
    end
    category.ref:setName(name)
    return category
  end

  function env.delcategory(category)
    category = resolveCategory(category)
    if category == nil then
      return nil, "not found"
    end
    category.ref:remove()
    return category
  end

  function env.entities(...)
    local entities = OpenBusContext:getEntityRegistry()
    local count = select("#", ...)
    local list
    if count == 0 then
      list = entities:getEntities()
    elseif count == 1 and (...) == "*" then
      list = entities:getAuthorizedEntities()
    else
      list = entities:getEntitiesByAuthorizedInterfaces{...}
    end
    return makelist(list, RegisteredEntity)
  end

  env.getentity = resolveEntity

  function env.setentity(id, name)
    local entity = resolveEntity(id) or error("entity not registered")
    entity.ref:setName(name)
    return entity
  end

  function env.delentity(entity)
    entity = resolveEntity(entity)
    if entity == nil then
      return nil, "not found"
    end
    entity.ref:remove()
    return entity
  end

  function env.ifaces(...)
    return makelist(OpenBusContext:getInterfaceRegistry():getInterfaces())
  end

  function env.addiface(iface)
    return OpenBusContext:getInterfaceRegistry():registerInterface(iface)
  end

  function env.deliface(iface)
    return OpenBusContext:getInterfaceRegistry():removeInterface(iface)
  end

  argchecker.module(env, {
    login = { "string", "nil|string", "nil|string" },
    whoami = {},
    quit = {},

    logins = { "nil|string|table" },
    kick = { "string|table" },

    offers = { "nil|table" },
    deloffer = { "string|table" },

    certents = {},
    getcert = { "string" },
    setcert = { "string", "string" },
    delcert = { "string" },

    categories = {},
    getcategory = { "string|table" },
    setcategory = { "string|table", "string" },
    delcategory = { "string|table" },

    entities = {},
    getentity = { "string|table" },
    setentity = { "string|table", "string" },
    delentity = { "string|table" },

    ifaces = {},
    addiface = { "string" },
    deliface = { "string" },
  })
end

argchecker.class(EntityCategory, {
  entities = {},
  addentity = { "string" , "string"},
})
argchecker.class(RegisteredEntity, {
  grant = { "string" },
  revoke = { "string" },
  ifaces = {},
})

return module

--[[

- Controle de Categoria
  * Adicionar categoria:
     --add-category=<id_categoria> --name=<nome>
  * Remover categoria:
     --del-category=<id_categoria>
  * Alterar o nome descritivo da categoria:
     --set-category=<id_categoria> --name=<nome>
  * Mostrar todas as categorias:
     --list-category
  * Mostrar informações sobre uma categoria:
     --list-category=<id_categoria>

- Controle de Entidade
  * Adicionar entidade:
     --add-entity=<id_entidade> --category=<id_categoria> --name=<nome>
  * Alterar descrição:
     --set-entity=<id_entidade> --name=<nome>
  * Remover entidade:
     --del-entity=<id_entidade>
  * Mostrar todas as entidades:
     --list-entity
  * Mostrar informações sobre uma entidade:
     --list-entity=<id_entidade>
  * Mostrar entidades de uma categoria:
     --list-entity --category=<id_categoria>

- Controle de Interface
  * Adicionar interface:
     --add-interface=<interface>
  * Remover interface:
     --del-interface=<interface>
  * Mostrar todas interfaces:
     --list-interface

- Controle de Autorização
  * Conceder autorização:
     --set-authorization=<id_entidade> --grant=<interface>
  * Revogar autorização:
     --set-authorization=<id_entidade> --revoke=<interface>
  * Mostrar todas as autorizações:
     --list-authorization
  * Mostrar autorizações da entidade:
     --list-authorization=<id_entidade>
  * Mostrar todas autorizações contendo as interfaces:
     --list-authorization --interface="<iface1> <iface2> ... <ifaceN>"


- Script
  * Executa script Lua com um lote de comandos:
     --script=<arquivo>
  * Desfaz a execução de um script Lua com um lote de comandos:
    --undo-script=<arquivo>

- Relatório
  * Monta um relatório sobre o estado atual do barramento:
    --report
-------------------------------------------------------------------------------

* Realiza o login por senha, aguardando a entrada da senha por linha de comando.
  busadmin --login=<entity> --password
  busconsole -e 'login"<entity>"'
* Realiza o login por senha.
  busadmin --login=<entity> --password=<password>
  busconsole -e 'login("<entity>", "<password>", "<domain>")'
* Realiza o login com chave privada.
  busadmin --login=<entity> --privatekey=<key file path>
  busconsole -e 'login("<entity>", "<key file path>")'

* Remove um login:
  busadmin --login=<entity> --del-login=<id_login>
  busconsole -e 'login"<entity>" kick"<id_login>"'
* Mostrar todos os logins:
  busadmin --login=<entity> --list-login
  busconsole -e 'login"<entity>" print(logins())'
* Mostrar todos os logins de uma entidade:
  busadmin --login=<entity> --list-login --entity=<id_entidade>
  busconsole -e 'login"<entity>" print(logins"<id_entidade>")'

* Remover oferta (lista e aguarda a entrada de um índice para remover a oferta):
  busadmin --login=<entity> --del-offer
  busconsole -e 'login"<entity>"
    list=offers()
    for i,o in ipairs(list) do print(i,o) end
    index=assert(tonumber(io.read()))
    deloffer(list[index])'
* Remover oferta da entidade (lista e aguarda a entrada de um índice para remover a oferta):
  busadmin --login=<entity> --del-offer --entity=<id_entidade>
  busconsole -e 'login"<entity>"
    list=offers{entity="<id_entidade>"}
    for i,o in ipairs(list) do print(i,o) end
    index=assert(tonumber(io.read()))
    deloffer(list[index])'
* Mostrar todas interfaces ofertadas:
  busadmin --login=<entity> --list-offer
  busconsole -e 'login"<entity>" print(offers())'
* Mostrar todas interfaces ofertadas por uma entidade:
  busadmin --login=<entity> --list-offer=<id_entidade>
  busconsole -e 'login"<entity>" print(offers{entity="<id_entidade>"})'
* Mostrar as propriedades da oferta (lista e aguarda a entrada de um índice para listar propriedades da oferta):
  busadmin --login=<entity> --list-props
  busconsole -e 'login"<entity>"
    list=offers()
    for i,o in ipairs(list) do print(i,o) end
    index=assert(tonumber(io.read()))
    print(list[index].properties)'
* Mostrar as propriedades da oferta por uma entidade (lista e aguarda a entrada de um índice para listar propriedades da oferta):
  busadmin --login=<entity> --list-props=<id_entidade>
  busconsole -e 'login"<entity>"
    list=offers{entity="<id_entidade>"}
    for i,o in ipairs(list) do print(i,o) end
    index=assert(tonumber(io.read()))
    print(list[index].properties)'

* Adiciona certificado da entidade:
  busadmin --login=<entity> --add-certificate=<id_entidade> --certificate=<certificado>
  busconsole -e 'login"<entity>" setcert("<id_entidade>", "<certificado>")'
* Remover certificado da entidade:
  busadmin --login=<entity> --del-certificate=<id_entidade>
  busconsole -e 'login"<entity>" delcert"<id_entidade>"'
* Mostrar entidades com um certificado cadastrado:
  busadmin --login=<entity> --list-certificate
  busconsole -e 'login"<entity>" print(certents())'

]]
