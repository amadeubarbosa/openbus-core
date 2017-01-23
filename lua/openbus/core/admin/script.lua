local _G = require "_G"
local assert = _G.assert
local error = _G.error
local ipairs = _G.ipairs
local pairs = _G.pairs
local pcall = _G.pcall
local select = _G.select
local setmetatable = _G.setmetatable
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type

local array = require "table"
local concat = array.concat
local sort = array.sort

local string = require "string"
local match = string.match

local math = require "math"
local inf = math.huge

local io = require "io"
local flush = io.flush
local read = io.read
local write = io.write

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
local sysex = require "openbus.util.sysex"
local NO_PERMISSION = sysex.NO_PERMISSION
local is_OBJECT_NOT_EXIST = sysex.is_OBJECT_NOT_EXIST

local assistant = require "openbus.assistant2"
local newassistant = assistant.create

local coreidl = require "openbus.core.idl"
local coresrvtypes = coreidl.types.services
local logintypes = coresrvtypes.access_control
local offertypes = coresrvtypes.offer_registry
local loginconst = coreidl.const.services.access_control
local accexp = coreidl.throw.services.access_control
local is_MissingCertificate = accexp.is_MissingCertificate

local admidl = require "openbus.core.admin.idl"
local loadadmidl = admidl.loadto
local admintypes = admidl.types.services.access_control.admin.v1_0
local conftypes  = admidl.types.services.admin.v1_0
local authotypes = admidl.types.services.offer_registry.admin.v1_0

local msg = require "openbus.util.messages"


local ExceptionMessages = {
  [sysexrepid.TRANSIENT] = msg.BusCurrentlyInaccessible,
  [sysexrepid.COMM_FAILURE] = msg.BusCommunicationFailure,
  [sysexrepid.OBJECT_NOT_EXIST] = msg.DefinitionRemovedFromBus,
  [sysexrepid.NO_PERMISSION] = {
    [loginconst.InvalidCredentialCode] = msg.InvalidCredential,
    [loginconst.InvalidChainCode] = msg.InvalidChain,
    [loginconst.InvalidLoginCode] = msg.InvalidLogin,
    [loginconst.UnverifiedLoginCode] = msg.UnverifiedLogin,
    [loginconst.UnknownBusCode] = msg.UnknownBus,
    [loginconst.InvalidPublicKeyCode] = msg.InvalidPublicKey,
    [loginconst.NoCredentialCode] = msg.NoCredential,
    [loginconst.NoLoginCode] = msg.NoLogin,
    [loginconst.InvalidRemoteCode] = msg.InvalidRemote,
    [loginconst.UnavailableBusCode] = msg.UnavailableBus,
    [loginconst.InvalidTargetCode] = msg.InvalidTarget,
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
  write(message)
  flush()
  return read(message == "Password: " and "*?" or "*l")
end



local PrintableSet = class()

function PrintableSet:__tostring()
  local res = {}
  local index = 0
  for item in pairs(self) do
    index = index+1
    res[index] = tostring(item)
  end
  sort(res)
  return concat(res, "\n")
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
  ["openbus.component.facet"] = "facets",
  ["openbus.component.interface"] = "interfaces",
}
local PropertyAliases = {}
for name, alias in pairs(ReservedProperties) do
  PropertyAliases[alias] = name
end
local ListAliases = {
  facets = true,
  interfaces = true,
}

local function makePropList(props)
  for alias, name in pairs(PropertyAliases) do
    local value = props[alias]
    if value ~= nil then
      if ListAliases[alias] == nil then
        props[#props+1] = {name=name,value=value}
      else
        for value in pairs(value) do
          props[#props+1] = {name=name,value=value}
        end
      end
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
  for alias in pairs(ListAliases) do
    self[alias] = PrintableSet()
  end
  for index, prop in ipairs(self.properties) do
    local alias = ReservedProperties[prop.name]
    if alias ~= nil then
      if ListAliases[alias] then
        self[alias][prop.value] = index
      elseif self[alias] == nil then
        self[alias] = prop.value
      end
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



function RegisteredEntity:__tostring()
  return self.id.." ("..self.name..")"
end

function RegisteredEntity:category()
  return EntityCategory(self.ref:_get_category())
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



local OpenBusORB
local OpenBusContext

local function createConnection(busref)
  local host, port = match(busref, "^(.+):(%d+)$")
  port = tonumber(port)
  local conn
  if host == nil or port > 65535 then
    local busior = assert(readfile(busref, "r"))
    busref = OpenBusORB:newproxy(busior, nil, "::scs::core::IComponent")
    conn = newassistant{
      orb = OpenBusORB,
      busref = busref,
    }
  else
    conn = newassistant{
      orb = OpenBusORB,
      bushost = host,
      busport = port,
    }
  end
  return conn
end

local function setDefaultConnection(conn)
  conn = OpenBusContext:setDefaultConnection(conn and conn.connection)
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

local function admServGetter(name, idlmod)
  local repid = idlmod[name]
  return function ()
    local conn = getCurrentConnection()
    if conn == nil or conn.connection.login == nil then
      NO_PERMISSION{
        completed = "COMPLETED_NO",
        minor = loginconst.NoLoginCode,
      }
    end
    return OpenBusORB:narrow(conn.connection.bus:getFacetByName(name), repid)
  end
end
local getConfiguration = admServGetter("Configuration", conftypes)
local getCertificateRegistry = admServGetter("CertificateRegistry", admintypes)
local getInterfaceRegistry = admServGetter("InterfaceRegistry", authotypes)
local getEntityRegistry = admServGetter("EntityRegistry", authotypes)

local function resolveCategory(category)
  if type(category) == "string" then
    category = getEntityRegistry():getEntityCategory(category)
    if category ~= nil then
      category = EntityCategory(category:describe())
    end
  elseif not isinstanceof(category, EntityCategory) then
    error("invalid entity category, got "..type(category))
  end
  return category
end

local function resolveEntity(entity)
  if type(entity) == "string" then
    entity = getEntityRegistry():getEntity(entity)
    if entity ~= nil then
      entity = RegisteredEntity(entity:describe())
    end
  elseif not isinstanceof(entity, RegisteredEntity) then
    error("invalid entity, got "..type(entity))
  end
  return entity
end


local script = {}

function script.setorb(orb)
  local old = OpenBusORB
  loadadmidl(orb)
  OpenBusORB = orb
  OpenBusContext = OpenBusORB.OpenBusContext
  return old
end

--script.setconn = setDefaultConnection
--script.getconn = getCurrentConnection

function script.login(busref, entity, secret, domain)
  local conn = createConnection(busref)
  if secret ~= nil and domain == nil then
    conn:loginByCertificate(entity, assert(readprivatekey(secret)))
  else
    conn:loginByPassword(entity, secret or gettext("Password: "),
                                 domain or gettext("Domain: "))
  end
  conn = setDefaultConnection(conn)
  if conn ~= nil then
    conn:logout()
  end
end

function script.whoami()
  local conn = getCurrentConnection()
  if conn ~= nil then
    local login = conn.login
    if login ~= nil then
      return LoginInfo(login)
    end
  end
end

function script.quit()
  local conn = getCurrentConnection()
  if conn ~= nil then
    conn:logout()
  end
  OpenBusORB:shutdown()
  suspend()
end

function script.shutdown()
  local conn = getCurrentConnection()
  if conn ~= nil then
    conn.connection.bus:shutdown()
  end
end

function script.logins(entity)
  if isinstanceof(entity, LoginInfo) then entity = entity.entity end
  local logins = OpenBusContext:getLoginRegistry()
  local list = (entity == nil)
    and logins:getAllLogins()
    or logins:getEntityLogins(entity)
  return makelist(list, LoginInfo)
end

function script.kick(id)
  if isinstanceof(id, LoginInfo) then id = id.id end
  OpenBusContext:getLoginRegistry():invalidateLogin(id)
end

function script.offers(properties)
  local offers = OpenBusContext:getOfferRegistry()
  local list = (properties == nil)
    and offers:getAllServices()
    or offers:findServices(makePropList(properties))
  return makelist(list, ServiceOffer)
end

function script.deloffer(offer)
  if type(offer) == "string" then
    local props = {{name="openbus.offer.id",value=offer}}
    offer = OpenBusContext:getOfferRegistry():findServices(props)[1]
    if offer == nil then
      return false
    end
  end
  local ok, errmsg = pcall(offer.ref.remove, offer.ref)
  if not ok then
    if not is_OBJECT_NOT_EXIST(errmsg) then
      error(errmsg)
    end
    return false
  end
  return true
end

function script.certents()
  local certs = getCertificateRegistry()
  return makelist(certs:getEntitiesWithCertificate())
end

function script.delcert(entity)
  local certs = getCertificateRegistry()
  return certs:removeCertificate(entity)
end

function script.setcert(entity, certificate)
  local certs = getCertificateRegistry()
  certs:registerCertificate(entity, certificate)
  return true
end

function script.getcert(entity)
  local certs = getCertificateRegistry()
  local ok, result = pcall(certs.getCertificate, certs, entity)
  if not ok then
    if not is_MissingCertificate(result) then
      error(result)
    end
    result = nil
  end
  return result
end

function script.categories()
  local entities = getEntityRegistry()
  return makelist(entities:getEntityCategories(), EntityCategory)
end

script.getcategory = resolveCategory

function script.setcategory(catid, name)
  local category = resolveCategory(catid)
  if category == nil then
    local entities = getEntityRegistry()
    category = entities:createEntityCategory(catid, name)
    return EntityCategory(category:describe())
  end
  category.ref:setName(name)
  return category
end

function script.delcategory(category)
  category = resolveCategory(category)
  if category == nil then
    return nil
  end
  category.ref:remove()
  return category
end

function script.entities(...)
  local entities = getEntityRegistry()
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

script.getentity = resolveEntity

function script.setentity(id, name)
  local entity = resolveEntity(id) or error("entity not registered")
  entity.ref:setName(name)
  return entity
end

function script.delentity(entity)
  entity = resolveEntity(entity)
  if entity == nil then
    return nil, "not found"
  end
  entity.ref:remove()
  return entity
end

function script.ifaces()
  return makelist(getInterfaceRegistry():getInterfaces())
end

function script.addiface(iface)
  return getInterfaceRegistry():registerInterface(iface)
end

function script.deliface(iface)
  return getInterfaceRegistry():removeInterface(iface)
end

function script.reloadconf()
  return getConfiguration():reloadConfigsFile()
end

function script.grantadmin(entities)
  return getConfiguration():grantAdminTo(entities)
end

function script.revokeadmin(entities)
  return getConfiguration():revokeAdminFrom(entities)
end

function script.admins()
  return getConfiguration():getAdmins()
end

function script.addpasswordvalidator(spec)
  return getConfiguration():addPasswordValidator(spec)
end

function script.delpasswordvalidator(spec)
  return getConfiguration():delPasswordValidator(spec)
end

function script.passwordvalidators()
  return getConfiguration():getPasswordValidators()
end

function script.addtokenvalidator(spec)
  return getConfiguration():addTokenValidator(spec)
end

function script.deltokenvalidator(spec)
  return getConfiguration():delTokenValidator(spec)
end

function script.tokenvalidators()
  return getConfiguration():getTokenValidators()
end

function script.maxchannels(max)
  if max ~= nil then
    return getConfiguration():setMaxChannels(max)
  else
    return getConfiguration():getMaxChannels()
  end
end

function script.maxcachesize(max)
  if max ~= nil then
    return getConfiguration():setMaxCacheSize(max)
  else
    return getConfiguration():getMaxCacheSize()
  end
end

function script.callstimeout(timeout)
  if timeout ~= nil then
    return getConfiguration():setCallsTimeout(timeout)
  else
    return getConfiguration():getCallsTimeout()
  end
end

function script.oilloglevel(level)
  if level ~= nil then
    return getConfiguration():setOilLogLevel(level)
  else
    return getConfiguration():getOilLogLevel()
  end
end

function script.loglevel(level)
  if level ~= nil then
    return getConfiguration():setLogLevel(level)
  else
    return getConfiguration():getLogLevel()
  end
end

argchecker.module(script, {
  login = { "string", "string", "nil|string", "nil|string" },
  whoami = {},
  quit = {},
  shutdown = {},

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

  reloadconf = {},
  
  grantadmin = { "table" },
  revokeadmin = { "table" },
  admins = {},

  addpasswordvalidator = { "string" },
  delpasswordvalidator = { "string" },
  passwordvalidators = {},

  addtokenvalidator = { "string" },
  deltokenvalidator = { "string" },
  tokenvalidators = {},
  
  maxchannels = { "nil|number" },

  maxcachesize = { "nil|number" },

  oilloglevel = { "nil|number" },
  loglevel = { "nil|number" },
})

argchecker.class(EntityCategory, {
  entities = {},
  addentity = { "string" , "string"},
})

argchecker.class(RegisteredEntity, {
  category = {},
  grant = { "string" },
  revoke = { "string" },
  ifaces = {},
})



return script
