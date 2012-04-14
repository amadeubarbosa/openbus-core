-- $Id$

local _G = require "_G"
local ipairs = _G.ipairs
local pairs = _G.pairs
local rawset = _G.rawset

local cothread = require "cothread"
local time = cothread.now

local uuid = require "uuid"
local newid = uuid.new

local hash = require "lce.hash"
local sha256 = hash.sha256
local pubkey = require "lce.pubkey"
local decodepublickey = pubkey.decodepublic
local x509 = require "lce.x509"
local decodecertificate = x509.decode

local Publisher = require "loop.object.Publisher"

local Timer = require "cothread.Timer"

local oo = require "openbus.util.oo"
local class = oo.class
local sysex = require "openbus.util.sysex"
local log = require "openbus.util.logger"

local idl = require "openbus.core.idl"
local assert = idl.serviceAssertion
local srvex = idl.throw.services
local throw = idl.throw.services.access_control
local types = idl.types.services.access_control
local const = idl.const.services.access_control

local msg = require "openbus.core.services.messages"
local checks = require "openbus.core.services.callchecks"
local assertCaller = checks.assertCaller
local assertAdmin = checks.assertAdmin
local Logins = require "openbus.core.services.LoginDB"


------------------------------------------------------------------------------
-- Faceta CertificateRegistry
------------------------------------------------------------------------------

local CertificateRegistry = {
  __type = types.CertificateRegistry,
  __objkey = const.CertificateRegistryFacet,
}

-- local operations

function CertificateRegistry:__init(data)
  self.access = data.access
  self.admins = data.admins
  self.database = data.database
  self.certificateDB = assert(self.database:gettable("Certificates"))
end

function CertificateRegistry:getPublicKey(entity)
  local certificate, errmsg = self.certificateDB:getentry(entity)
  if certificate ~= nil then
    return assert(assert(decodecertificate(certificate)):getpubkey())
  elseif errmsg ~= nil then
    assert(nil, errmsg)
  end
end

-- IDL operations

function CertificateRegistry:registerCertificate(entity, certificate)
  assertAdmin(self)
  local certobj, errmsg = decodecertificate(certificate)
  if not certobj then
    throw.InvalidCertificate{message=errmsg}
  end
  local pubkey, errmsg = certobj:getpubkey()
  if not pubkey then
    throw.InvalidCertificate{message=errmsg}
  end
  log:admin(msg.RegisterEntityCertificate:tag{entity=entity})
  assert(self.certificateDB:setentry(entity, certificate))
end

function CertificateRegistry:getCertificate(entity)
  assertAdmin(self)
  local certificate, errmsg = self.certificateDB:getentry(entity)
  if certificate == nil then
    if errmsg ~= nil then
      srvex.ServiceFailure{message=errmsg}
    end
    throw.MissingCertificate{entity=entity}
  end
  return certificate
end

function CertificateRegistry:removeCertificate(entity)
  assertAdmin(self)
  local db = self.certificateDB
  if db:getentry(entity) ~= nil then
    log:admin(msg.RemoveEntityCertificate:tag{entity=entity})
    assert(db:removeentry(entity))
    return true
  end
  return false
end

------------------------------------------------------------------------------
-- Faceta LoginManager
------------------------------------------------------------------------------

local SelfLogin = {
  id = nil,
  entity = idl.const.BusEntity,
  leaseRenewed = inf,
}

local function renewLogin(login)
  login.leaseRenewed = time()
end



local LoginProcess = class{ __type = types.LoginProcess }

function LoginProcess:cancel()
  local manager = self.manager
  manager.access.orb:deactivate(self)
  manager.pendingChallenges[self] = nil
end

function LoginProcess:login(pubkey, encrypted)
  self:cancel()
  local entity = self.entity
  local manager = self.manager
  local access = manager.access
  local decrypted, errmsg = access.prvkey:decrypt(encrypted)
  if decrypted == nil then
    throw.WrongEncoding{errmsg=errmsg or "no error message provided"}
  end
  local decoder = access.orb:newdecoder(decrypted)
  local decoded = decoder:get(manager.LoginAuthenticationInfo)
  if decoded.hash ~= sha256(pubkey) or decoded.data ~= self.secret then
    throw.AccessDenied{entity=entity}
  end
  local login = manager.activeLogins:newLogin(entity, pubkey)
  renewLogin(login)
  log:request(msg.LoginProcessConcluded:tag{login=login.id,entity=entity})
  return login, manager.leaseTime
end



local LoginRegistry -- forward declaration

local AccessControl = {
  __type = types.AccessControl,
  __objkey = const.AccessControlFacet,
  
  leaseTime = 180,
  challengeTimeout = 180,
  publisher = Publisher(),
}

-- local operations

function AccessControl:__init(data)
  -- initialize attributes
  self.access = data.access
  self.database = data.database
  self.passwordValidators = data.validators
  self.leaseTime = data.leaseTime
  self.expirationGap = data.expirationGap
  self.pendingChallenges = {}
  self.activeLogins = Logins{
    database = self.database,
    publisher = self.publisher,
  }
  
  -- initialize access
  local busid = newid("time")
  SelfLogin.id = busid
  self.busid = busid
  local access = self.access
  local encodedkey = assert(access.prvkey:encode("public"))
  self.buskey = encodedkey
  access.AccessControl = self
  access.logins = self
  access.login = SelfLogin
  access.busid = busid
  access.buskey = decodepublickey(encodedkey)
  self.LoginAuthenticationInfo =
    assert(access.orb.types:lookup_id(types.LoginAuthenticationInfo))
  
  -- renova todas as credenciais persistidas
  for id, login in self.activeLogins:iLogins() do
    renewLogin(login)
  end
  
  -- timer de limpeza de credenciais não renovadas e desafios não respondidos
  self.sweepTimer = Timer{ rate = self.leaseTime }
  function self.sweepTimer.action()
    -- A operação 'login:remove()' pode resultar numa chamada remota de
    -- 'observer:entityLogout(login)' e durante essa chamada é possível que
    -- outra thread altere o 'activeLogins' o que interferiria na iteração
    -- 'activeLogins:iLogins()' de forma imprevisível. Por isso a remoção é
    -- feita em duas etapas:
    local now = time()
    local expirationTime = self.leaseTime + self.expirationGap
    -- coleta credenciais não renovadas a tempo
    local invalidLogins = {}
    for id, login in self.activeLogins:iLogins() do
      if now-login.leaseRenewed > expirationTime then
        invalidLogins[login] = true
      end
    end
    -- remove as credenciais coletadas
    for login in pairs(invalidLogins) do
      login:remove()
      log:action(msg.LoginExpired:tag{
        login = login.id,
        entity = login.entity,
      })
    end
    
    -- cancela autenicação via desafio cujo tempo tenha espirado
    local challengeTimeout = self.challengeTimeout
    for process, timeCreated in pairs(self.pendingChallenges) do
      if now-timeCreated > challengeTimeout then
        log:action(msg.LoginProcessExpired:tag{entity=process.entity})
        process:cancel()
      end
    end
  end
  self.sweepTimer:enable()
end

function AccessControl:shutdown()
  self.sweepTimer:disable()
  log:admin(msg.AccessControlShutDown:tag{entity=process.entity})
end

function AccessControl:getLoginEntry(id)
  return self.activeLogins:getLogin(id)
end

function AccessControl:encodeChain(target, callers)
  local access = self.access
  local encoder = access.orb:newencoder()
  encoder:put({target=target,callers=callers}, access.types.CallChain)
  local encoded = encoder:getdata()
  return {
    encoded = encoded,
    signature = assert(access.prvkey:sign(assert(sha256(encoded)))),
  }
end

-- IDL operations

function AccessControl:loginByPassword(entity, pubkey, encrypted)
  if entity ~= SelfLogin.entity then
    local decrypted, errmsg = self.access.prvkey:decrypt(encrypted)
    if decrypted == nil then
      throw.WrongEncoding{errmsg=errmsg or "no error message provided"}
    end
    local decoder = self.access.orb:newdecoder(decrypted)
    local decoded = decoder:get(self.LoginAuthenticationInfo)
    if decoded.hash == sha256(pubkey) then
      for _, validator in ipairs(self.passwordValidators) do
        local valid, errmsg = validator.validate(entity, decoded.data)
        if valid then
          local login = self.activeLogins:newLogin(entity, pubkey)
          log:request(msg.LoginByPassword:tag{
            login = login.id,
            entity = entity,
            validator = validator.name,
          })
          renewLogin(login)
          return login, self.leaseTime
        elseif errmsg ~= nil then
          log:exception(msg.FailedPasswordValidation:tag{
            entity = entity,
            validator = validator.name,
            errmsg = errmsg,
          })
        end
      end
    else
      log:exception(msg.WrongPublicKeyHash:tag{ entity = entity })
    end
  else
    log:exception(msg.RefusedLoginOfBusEntity:tag{ entity = entity })
  end
  throw.AccessDenied{entity=entity}
end

function AccessControl:startLoginByCertificate(entity)
  local publickey = CertificateRegistry:getPublicKey(entity)
  if publickey == nil then
    throw.MissingCertificate{entity=entity}
  end
  local logger = LoginProcess{
    manager = self,
    entity = entity,
    secret = newid("new"),
  }
  self.pendingChallenges[logger] = time()
  log:request(msg.LoginByCertificateInitiated:tag{ entity = entity })
  return logger, assert(publickey:encrypt(logger.secret))
end

function AccessControl:startLoginBySingleSignOn()
  local id = assertCaller(self).id
  local login = self.activeLogins:getLogin(id)
  local logger = LoginProcess{
    manager = self,
    entity = login.entity,
    secret = newid("new"),
  }
  self.pendingChallenges[logger] = time()
  log:request(msg.LoginBySingleSignOnInitiated:tag{
    login = login.id,
    entity = login.entity,
  })
  return logger, assert(login.pubkey:encrypt(logger.secret))
end

function AccessControl:logout()
  local id = assertCaller(self).id
  local login = self.activeLogins:getLogin(id)
  login:remove()
  log:request(msg.LogoutPerformed:tag{login=id,entity=login.entity})
end

function AccessControl:renew()
  local id = assertCaller(self).id
  local login = self.activeLogins:getLogin(id)
  renewLogin(login)
  log:request(msg.LoginRenewed:tag{login=id,entity=login.entity})
  return self.leaseTime
end

function AccessControl:signChainFor(target)
  assertCaller(self)
  if self.activeLogins:getLogin(target) == nil then
    sysex.NO_PERMISSION{minor=const.InvalidLoginCode,completed="COMPLETED_NO"}
  end
  return self:encodeChain(target, self.access:getCallerChain().callers)
end

------------------------------------------------------------------------------
-- Faceta LoginRegistry
------------------------------------------------------------------------------

local Subscription = class{ __type = types.LoginObserverSubscription }

-- local operations

function Subscription:__init()
  local id = self.id
  self.__objkey = id
  self.observer = self.logins:getObserver(id)
end

-- IDL operations

function Subscription:watchLogin(id)
  assertCaller(self.registry, self.observer.entity)
  local login = self.logins:getLogin(id)
  if login ~= nil then
    self.observer:watchLogin(login)
    return true
  end
  return false
end

function Subscription:forgetLogin(id)
  assertCaller(self.registry, self.observer.entity)
  local login = self.logins:getLogin(id)
  if login ~= nil then
    self.observer:forgetLogin(login)
  end
end

function Subscription:watchLogins(ids)
  assertCaller(self.registry, self.observer.entity)
  local logins = self.logins
  local missing = {}
  for index, id in ipairs(ids) do
    local login = logins:getLogin(id)
    if login == nil then
      missing[#missing+1] = id
    end
    ids[index] = login
  end
  if #missing > 0 then
    throw.InvalidLogins{ loginIds = missing }
  end
  local observer = self.observer
  for index, login in ipairs(ids) do
    observer:watchLogin(login)
  end
end

function Subscription:forgetLogins(ids)
  for _, id in ipairs(ids) do
    self:forgetLogin(id)
  end
end

function Subscription:getWatchedLogins()
  assertCaller(self.registry)
  local result = {}
  local logins = self.logins
  for id in self.observer:iWatchedLoginIds() do
    result[#result+1] = logins:getLogin(id)
  end
  return result
end

function Subscription:remove()
  assertCaller(self.registry, self.observer.entity)
  self.observer:remove()
end



LoginRegistry = {
  __type = types.LoginRegistry,
  __objkey = const.LoginRegistryFacet,
}

-- local operations

function LoginRegistry:__init(data)
  -- initialize attributes
  self.access = data.access
  self.admins = data.admins
  self.subscriptionOf = {}
  -- register itself to receive logout notifications
  rawset(AccessControl.publisher, self, self)
  -- restaura servants dos observadores persistidos
  local orb = self.access.orb
  local logins = AccessControl.activeLogins
  for id, observer in logins:iObservers() do
    local subscription = Subscription{
      id = id,
      logins = logins,
      registry = self,
    }
    self.subscriptionOf[id] = subscription
    orb:newservant(subscription)
  end
end

function LoginRegistry:loginRemoved(login, observers)
  local orb = self.access.orb
  for observer in pairs(observers) do
    local callback = observer.callback
    if callback == nil then
      callback = orb:newproxy(observer.ior, nil, types.LoginObserver)
    end
    local ok, errmsg = pcall(callback.entityLogout, callback, login)
    if not ok then
      log:exception(msg.LoginObserverException:tag{errmsg=errmsg})
    end
  end
end

function LoginRegistry:loginObserverRemoved(observer)
  local id = observer.id
  local subscription = self.subscriptionOf[id]
  self.subscriptionOf[id] = nil
  self.access.orb:deactivate(subscription)
end

-- IDL operations

function LoginRegistry:getAllLogins()
  assertAdmin(self)
  local logins = {}
  for id, login in AccessControl.activeLogins:iLogins() do
    logins[#logins+1] = login
  end
  return logins
end

function LoginRegistry:getEntityLogins(entity)
  assertAdmin(self)
  local logins = {}
  for id, login in AccessControl.activeLogins:iLogins() do
    if login.entity == entity then
      logins[#logins+1] = login
    end
  end
  return logins
end

function LoginRegistry:invalidateLogin(id)
  local caller = assertAdmin(self)
  local login = AccessControl.activeLogins:getLogin(id)
  if login ~= nil then
    login:remove()
    log:request(msg.LogoutForced:tag{
      login = id,
      entity = login.entity,
      adminlogin = caller.id,
      adminentity = caller.entity,
    })
    return true
  end
  return false
end

function LoginRegistry:getLoginInfo(id)
  assertCaller(self) --> TODO: is this really necessary?
  local login = AccessControl.activeLogins:getLogin(id)
  if login ~= nil then
    return login, login.encodedkey
  elseif id == SelfLogin.id then
    return SelfLogin, AccessControl.buskey
  end
  throw.InvalidLogins{loginIds={id}}
end

function LoginRegistry:getValidity(ids)
  assertCaller(self) --> TODO: is this really necessary?
  local logins = AccessControl.activeLogins
  local leaseTime = AccessControl.leaseTime
  local expirationGap = AccessControl.expirationGap
  local now = time()
  local validity = {}
  for index, id in ipairs(ids) do
    local login = logins:getLogin(id)
    if login ~= nil then
      validity[index] = expirationGap+leaseTime-(now-login.leaseRenewed)
    elseif id == SelfLogin.id then
      validity[index] = leaseTime
    else
      validity[index] = 0
    end
  end
  return validity
end

function LoginRegistry:subscribeObserver(callback)
  local logins = AccessControl.activeLogins
  local id = assertCaller(self).id
  local login = logins:getLogin(id)
  local observer = login:newObserver(callback)
  local subscription = Subscription{
    id = observer.id,
    logins = logins,
    registry = self,
  }
  self.subscriptionOf[observer.id] = subscription
  return subscription
end



return {
  CertificateRegistry = CertificateRegistry,
  AccessControl = AccessControl,
  LoginRegistry = LoginRegistry,
}
