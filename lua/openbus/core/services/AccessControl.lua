-- $Id$

local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local pairs = _G.pairs
local pcall = _G.pcall
local rawset = _G.rawset
local type = _G.type
local xpcall = _G.xpcall

local coroutine = require "coroutine"
local newthread = coroutine.create

local array = require "table"
local concat = array.concat

local string = require "string"
local repeatstring = string.rep

local math = require "math"
local ceil = math.ceil
local inf = math.huge
local min = math.min

local cothread = require "cothread"
local time = cothread.now
local running = cothread.running
local runthread = cothread.next
local schedule = cothread.schedule
local unschedule = cothread.unschedule
local waituntil = cothread.defer

local debug = require "debug"
local traceback = debug.traceback

local uuid = require "uuid"
local newid = uuid.new

local hash = require "lce.hash"
local sha256 = hash.sha256
local pubkey = require "lce.pubkey"
local decodepublickey = pubkey.decodepublic
local x509 = require "lce.x509"
local decodecertificate = x509.decode

local log = require "openbus.util.logger"
local oo = require "openbus.util.oo"
local class = oo.class
local sysex = require "openbus.util.sysex"
local BAD_PARAM = sysex.BAD_PARAM
local server = require "openbus.util.server"
local blockencrypt = server.blockencrypt

local idl = require "openbus.core.idl"
local assert = idl.serviceAssertion
local BusEntity = idl.const.BusEntity
local BusLogin = idl.const.BusLogin
local EncryptedBlockSize = idl.const.EncryptedBlockSize
local ServiceFailureId = idl.types.services.ServiceFailure
local ServiceFailure = idl.throw.services.ServiceFailure
local accexp = idl.throw.services.access_control
local UnknownDomain = accexp.UnknownDomain
local AccessDenied = accexp.AccessDenied
local TooManyAttempts = accexp.TooManyAttempts
local InvalidToken = accexp.InvalidToken
local InvalidLogins = accexp.InvalidLogins
local InvalidPublicKey = accexp.InvalidPublicKey
local MissingCertificate = accexp.MissingCertificate
local WrongEncoding = accexp.WrongEncoding
local acctyp = idl.types.services.access_control
local AccessControlType = acctyp.AccessControl
local LoginAuthInfo = acctyp.LoginAuthenticationInfo
local LoginObsType = acctyp.LoginObserver
local LoginObsSubType = acctyp.LoginObserverSubscription
local LoginProcessType = acctyp.LoginProcess
local LoginRegistryType = acctyp.LoginRegistry

local mngidl = require "openbus.core.admin.idl"
local mngexp = mngidl.throw.services.access_control.admin.v1_0
local InvalidCertificate = mngexp.InvalidCertificate
local mngtyp = mngidl.types.services.access_control.admin.v1_0
local CertificateRegistryType = mngtyp.CertificateRegistry

local msg = require "openbus.core.services.messages"
local Logins = require "openbus.core.services.LoginDB"
local PasswordAttempts = require "openbus.core.services.PasswordAttempts"
local coreutil = require "openbus.core.services.util"
local assertCaller = coreutil.assertCaller

local MaxEncryptionSize = EncryptedBlockSize-11
local MaxEncryptionData = repeatstring("\255", MaxEncryptionSize)

local lsqlite = require "lsqlite3"

------------------------------------------------------------------------------
-- Faceta CertificateRegistry
------------------------------------------------------------------------------

local function getkeyerror(key)
  local result, errmsg = key:encrypt(MaxEncryptionData)
  if result == nil then
    return msg.UnableToEncryptWithKey:tag{error=errmsg}
  end
  if #result ~= EncryptedBlockSize then
    return msg.WrongKeySize:tag{actual=#result,expected=EncryptedBlockSize}
  end
end



local CertificateRegistry = { __type = CertificateRegistryType }

-- local operations

function CertificateRegistry:__init(data)
  self.database = data.database
  -- setup operation access
  local certificates = {}
  for entry in self.database.pstmts.getCertificate:nrows() do
     certificates[entry.entity] = entry.certificate
  end
  self.certificates = certificates
  local access = data.access
  local admins = data.admins
  access:setGrantedUsers(self.__type, "registerCertificate", admins)
  access:setGrantedUsers(self.__type, "removeCertificate", admins)
  access:setGrantedUsers(self.__type, "getCertificate", admins)
  access:setGrantedUsers(self.__type, "getEntitiesWithCertificate", admins)
end

function CertificateRegistry:getPublicKey(entity)
  local certificate = self:getCertificate(entity)
  if certificate ~= nil then
    return assert(assert(decodecertificate(certificate)):getpubkey())
  elseif errmsg ~= nil then
    assert(nil, errmsg)
  end
end

-- IDL operations

function CertificateRegistry:registerCertificate(entity, certificate)
  if entity == "" then
    BAD_PARAM{ completed = "COMPLETED_NO", minor = 0 }
  end
  local certobj, errmsg = decodecertificate(certificate)
  if not certobj then
    InvalidCertificate{entity=entity,message=errmsg}
  end
  local pubkey, errmsg = certobj:getpubkey()
  if not pubkey then
    InvalidCertificate{entity=entity,message=errmsg}
  end
  errmsg = getkeyerror(pubkey)
  if errmsg ~= nil then
    InvalidCertificate{entity=entity,message=errmsg}
  end
  log:admin(msg.RegisterEntityCertificate:tag{entity=entity})
  if not self.certificates[entity] then
    assert(self.database:pexec("addCertificate", certificate, entity))
  else
    assert(self.database:pexec("setCertificate", certificate, entity))
  end
  self.certificates[entity] = certificate
end

function CertificateRegistry:getCertificate(entity)
  local certificate = self.certificates[entity]
  if not certificate then
    MissingCertificate{entity=entity}
  end
  return certificate
end

function CertificateRegistry:getEntitiesWithCertificate()
  local entities = {}
  for entity in pairs(self.certificates) do
     entities[#entities+1] = entity
  end
  return entities
end

function CertificateRegistry:removeCertificate(entity)
  if self.certificates[entity] then
    log:admin(msg.RemoveEntityCertificate:tag{entity=entity})
    local delCertificate = self.database.pstmts.delCertificate
    delCertificate:bind_values(entity)
    delCertificate:step()
    delCertificate:reset()
    self.certificates[entity] = nil
    return true
  end
  return false
end

------------------------------------------------------------------------------
-- Faceta AccessControl
------------------------------------------------------------------------------

local function renewLogin(self, login)
  login.deadline = time() + self.leaseTime + self.expirationGap
end

local function checkaccesskey(pubkey)
  local result, errmsg = decodepublickey(pubkey)
  if result == nil then
    InvalidPublicKey{message=msg.UnableToDecodeKey:tag{error=errmsg}}
  end
  errmsg = getkeyerror(result)
  if errmsg ~= nil then
    InvalidPublicKey{message=errmsg}
  end
end



local LoginProcess = class{ __type = LoginProcessType }

function LoginProcess:cancel()
  local manager = self.manager
  manager.access.orb:deactivate(self)
  manager.pendingChallenges[self] = nil
end

function LoginProcess:login(pubkey, encrypted)
  self:cancel()
  checkaccesskey(pubkey)
  local entity = self.entity
  local manager = self.manager
  local access = manager.access
  local decrypted, errmsg = access.prvkey:decrypt(encrypted)
  if decrypted == nil then
    WrongEncoding{entity=entity,message=errmsg or "no error message"}
  end
  local decoder = access.orb:newdecoder(decrypted)
  local decoded = decoder:get(manager.LoginAuthInfo)
  if decoded.hash ~= assert(sha256(pubkey)) or decoded.data ~= self.secret then
    AccessDenied{entity=entity}
  end
  local login = manager.activeLogins:newLogin(entity, pubkey)
  renewLogin(manager, login)
  log:request(msg.LoginProcessConcluded:tag{login=login.id,entity=entity})
  return login, manager.leaseTime
end



local LoginRegistry -- forward declaration

local AccessControl = {
  __type = AccessControlType,
  login = {id=BusLogin, entity=BusEntity},
  pendingChallenges = {}
}

-- local operations

function AccessControl:__init(data)
  local db = data.database
  -- TODO   
  local getSettings = db.pstmts.getSettings
  getSettings:bind_values("BusId")
  local ret = getSettings:step()
  local busid
  if ret == lsqlite.ROW then
    busid = getSettings:get_value(0)
    getSettings:reset()
  end  
  if busid == nil then
    busid = newid("time")
    assert(db:pexec("addSettings", "BusId", busid))
    log:action(msg.AdoptingNewBusIdentifier:tag{bus=busid})
  else
    log:action(msg.RecoveredBusIdentifier:tag{bus=busid})
  end
  
  -- initialize attributes
  self.access = data.access
  self.certificate = data.certificate
  self.passwordValidators = data.passwordValidators
  self.tokenValidators = data.tokenValidators
  self.leaseTime = data.leaseTime
  self.expirationGap = data.expirationGap
  self.challengeTime = data.challengeTime
  self.sharedAuthTime = data.sharedAuthTime
  self.loginAttempts = PasswordAttempts{
    limit = data.passwordLimitedTries,
    period = data.passwordPenaltyTime,
  }
  self.validationAttempts = PasswordAttempts{
    mode = PasswordAttempts.modes.LeakyBucket,
    limit = data.passwordFailureLimit,
    period = data.passwordFailureLimit/data.passwordFailureRate,
  }
  self.activeLogins = Logins{ database = db }
  
  -- initialize access
  self.busid = busid
  local access = self.access
  local encodedkey = assert(access.prvkey:encode("public"))
  self.buskey = encodedkey -- TODO: this shall become a X.509 certificate
  access.AccessControl = self
  access.LoginRegistry = self
  access.login = self.login
  access.busid = busid
  access.buskey = assert(decodepublickey(encodedkey))
  access:setGrantedUsers(self.__type, "_get_busid", "any")
  access:setGrantedUsers(self.__type, "_get_certificate", "any")
  access:setGrantedUsers(self.__type, "loginByPassword", "any")
  access:setGrantedUsers(self.__type, "startLoginByCertificate", "any")
  access:setGrantedUsers(LoginProcess.__type, "*", "any")
  self.LoginAuthInfo = assert(access.orb.types:lookup_id(LoginAuthInfo))
  
  -- renova todas as credenciais persistidas
  for id, login in self.activeLogins:iLogins() do
    renewLogin(self, login)
    log:action(msg.PersistedLoginRenewed:tag{login=id,entity=login.entity})
  end
  
  -- timer de limpeza de credenciais não renovadas e desafios não respondidos
  runthread(newthread(function()
    local nextDeadline = time() + self.leaseTime + self.expirationGap
      
    repeat
      self.sweeper = running()
      waituntil(nextDeadline)
      self.sweeper = true
      
      local now = time()
      nextDeadline = now + self.leaseTime + self.expirationGap

      for id, login in self.activeLogins:iLogins() do
        local deadline = login.deadline
        if deadline > now then
          nextDeadline = min(nextDeadline, deadline)
        else
          log:action(msg.LoginExpired:tag{
            login = login.id,
            entity = login.entity,
          })
          local ok, ex = pcall(login.remove, login) -- catch I/O errors
          if not ok and (type(ex)~="table" or ex._repid~=ServiceFailureId) then
            error(ex)
          end
        end
      end
      
      -- cancela autenicação via desafio cujo tempo tenha espirado
      for process, deadline in pairs(self.pendingChallenges) do
        if deadline > now then
          nextDeadline = min(nextDeadline, deadline)
        else
          log:action(msg.LoginProcessExpired:tag{entity=process.entity})
          process:cancel()
        end
      end
    until self.sweeper == false
  end))
end

function AccessControl:shutdown()
  local sweeper = self.sweeper
  if sweeper and sweeper ~= true then -- sweeper is sleeping
    unschedule(sweeper)
  end
  self.sweeper = false -- indicate no sweeper shall run anymore
  log:admin(msg.AccessControlShutDown)
end

function AccessControl:getLoginEntry(id)
  return self.activeLogins:getLogin(id)
end

function AccessControl:encodeChain(chain, target)
  chain.bus = self.busid
  chain.target = target
  local access = self.access
  local encoder = access.orb:newencoder()
  encoder:put(chain, access.types.CallChain)
  local encoded = encoder:getdata()
  return {
    encoded = encoded,
    signature = assert(access.prvkey:sign(assert(sha256(encoded)))),
  }
end

-- IDL operations

function AccessControl:loginByPassword(entity, domain, pubkey, encrypted)
  if entity ~= self.login.entity then
    checkaccesskey(pubkey)
    local access = self.access
    local decrypted, errmsg = access.prvkey:decrypt(encrypted)
    if decrypted == nil then
      WrongEncoding{entity=entity,message=errmsg or "no error message"}
    end
    local decoder = access.orb:newdecoder(decrypted)
    local decoded = decoder:get(self.LoginAuthInfo)
    if decoded.hash == assert(sha256(pubkey)) then
      local sourceid = access.callerAddressOf[running()].host
      local loginAttempts = self.loginAttempts
      local allowed, wait = loginAttempts:allow(sourceid)
      if not allowed then
        log:exception(msg.TooManyFailedLogins:tag{sourceid=sourceid,wait=wait})
        TooManyAttempts{ domain = "ADDRESS", penaltyTime = 1000*wait }
      end
      allowed, wait = loginAttempts:allow(entity)
      if not allowed then
        log:exception(msg.TooManyFailedEntityLogins:tag{entity=entity,wait=wait})
        TooManyAttempts{ domain = "ENTITY", penaltyTime = 1000*wait }
      end
      local validationAttempts = self.validationAttempts
      allowed, wait = validationAttempts:allow("validators")
      if not allowed then
        log:exception(msg.TooManyFailedValidations:tag{entity=entity,wait=wait})
        TooManyAttempts{ domain = "VALIDATOR", penaltyTime = 1000*wait }
      end
      local validator = self.passwordValidators[domain]
      if validator ~= nil then
        local ok, valid, errmsg = xpcall(validator.validate, traceback, entity, decoded.data)
        if not ok then
          ServiceFailure{
            message = msg.FailedPasswordValidation:tag{
              entity = entity,
              validator = validator.name,
              errmsg = valid,
            }
          }
        elseif valid then
          local login = self.activeLogins:newLogin(entity, pubkey)
          log:request(msg.LoginByPassword:tag{
            login = login.id,
            domain = domain,
            entity = entity,
            validator = validator.name,
          })
          renewLogin(self, login)
          loginAttempts:granted(entity)
          return login, self.leaseTime
        else
          log:exception(msg.FailedPasswordValidation:tag{
            domain = domain,
            entity = entity,
            validator = validator.name,
            errmsg = errmsg or msg.UnspecifiedValidationFailure,
          })
        end
        loginAttempts:denied(sourceid)
        loginAttempts:denied(entity)
        validationAttempts:denied("validators")
      else
        UnknownDomain{ domain = domain }
      end
    else
      log:exception(msg.WrongPublicKeyHash:tag{ entity = entity })
    end
  else
    log:exception(msg.RefusedLoginOfBusEntity:tag{ entity = entity })
  end
  AccessDenied{ entity = entity }
end

function AccessControl:startLoginByCertificate(entity)
  local publickey = CertificateRegistry:getPublicKey(entity)
  if publickey == nil then
    if entity ~= self.login.entity then
      MissingCertificate{entity=entity}
    end
    publickey = self.access.buskey
  end
  local secret = newid("random")
  local logger = LoginProcess{
    manager = self,
    entity = entity,
    secret = secret,
  }
  self.pendingChallenges[logger] = time()+self.challengeTime+self.expirationGap
  log:request(msg.LoginByCertificateInitiated:tag{ entity = entity })
  return logger, assert(publickey:encrypt(secret))
end

function AccessControl:startLoginBySharedAuth()
  local caller = self.access:getCallerChain().caller
  local login = self.activeLogins:getLogin(caller.id)
  local secret = newid("random")
  local logger = LoginProcess{
    manager = self,
    originator = login.id,
    entity = login.entity,
    secret = secret,
  }
  self.pendingChallenges[logger] = time()+self.sharedAuthTime+self.expirationGap
  log:request(msg.LoginBySharedAuthInitiated:tag{
    login = login.id,
    entity = login.entity,
  })
  return logger, assert(login.pubkey:encrypt(secret))
end

function AccessControl:logout()
  local caller = self.access:getCallerChain().caller
  local login = self.activeLogins:getLogin(caller.id)
  login:remove()
  log:request(msg.LogoutPerformed:tag{login=login.id,entity=login.entity})
end

function AccessControl:renew()
  local caller = self.access:getCallerChain().caller
  local login = self.activeLogins:getLogin(caller.id)
  renewLogin(self, login)
  log:request(msg.LoginRenewed:tag{login=login.id,entity=login.entity})
  return self.leaseTime
end

function AccessControl:signChainFor(target)
  return self:encodeChain(self.access:getCallerChain(), target)
end

local ImportedChain = class()
function ImportedChain:push(entity)
  local id = newid("time")
  self[#self+1] = {id=id, entity=entity}
  return id
end

function AccessControl:signChainByToken(encrypted, domain)
  local access = self.access
  local caller = access:getCallerChain().caller
  local decrypted, errmsg = blockencrypt(access.prvkey, "decrypt",
                                         EncryptedBlockSize, encrypted)
  if decrypted == nil then
    WrongEncoding{message=errmsg or "no error message"}
  end
  local validator = self.tokenValidators[domain]
  if validator ~= nil then
    local imported = ImportedChain()
    local ok, valid, errmsg = xpcall(validator.validate,
                                     traceback,
                                     caller.id,
                                     caller.entity,
                                     decrypted,
                                     imported)
    if not ok then
      ServiceFailure{
        message = msg.FailedTokenValidation:tag{
          validator = validator.name,
          errmsg = valid,
        }
      }
    elseif valid then
      local count = #imported
      if count > 0 then
        local last = imported[count]
        imported[count] = nil
        local chain = {
          originators = imported,
          caller = last,
        }
        return self:encodeChain(chain, caller.entity)
      end
      ServiceFailure{
        message = msg.ImportedChainWasEmpty:tag{ validator = validator.name },
      }
    elseif errmsg ~= nil then
      log:exception(msg.FailedTokenValidation:tag{
        validator = validator.name,
        errmsg = errmsg,
      })
    end
    InvalidToken{ message = errmsg }
  else
    UnknownDomain{ domain = domain }
  end
end

------------------------------------------------------------------------------
-- Faceta LoginRegistry
------------------------------------------------------------------------------

local function getObserver(observer, orb)
  local callback = observer.callback
  if callback == nil then
    callback = orb:newproxy(observer.ior, nil, LoginObsType)
    observer.callback = callback
  end
  return callback
end



local Subscription = class{ __type = LoginObsSubType }

-- local operations

function Subscription:__init()
  local id = self.id
  self.__objkey = "LoginObserver_v2.1:"..id
  self.observer = self.logins:getObserver(id, self.registry.access.orb)
end

-- IDL operations

function Subscription:_get_observer()
  return getObserver(self.observer, self.registry.access.orb)
end

function Subscription:describe()
  return { observer = self:_get_observer() }
end

function Subscription:watchLogin(id)
  local login = self.logins:getLogin(id)
  if login ~= nil then
    self.observer:watchLogin(login)
    return true
  end
  return false
end

function Subscription:forgetLogin(id)
  local login = self.logins:getLogin(id)
  if login ~= nil then
    self.observer:forgetLogin(login)
  end
end

function Subscription:watchLogins(ids)
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
    InvalidLogins{ loginIds = missing }
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
  local result = {}
  local logins = self.logins
  for id in self.observer:iWatchedLoginIds() do
    result[#result+1] = logins:getLogin(id)
  end
  return result
end

function Subscription:remove()
  self.observer:remove()
  self.registry.access.orb:deactivate(self)
end



LoginRegistry = { __type = LoginRegistryType }

-- local operations

function LoginRegistry:__init(data)
  -- initialize attributes
  self.access = data.access
  self.admins = data.admins -- for 'assertCaller'
  self.subscriptionOf = {}
  -- setup operation access
  local access = self.access
  access:setGrantedUsers(self.__type, "getAllLogins", data.admins)
  -- register itself to receive logout notifications
  local logins = AccessControl.activeLogins
  rawset(logins.publisher, self, self)
  -- restaura servants dos observadores persistidos
  local orb = access.orb
  for id, observer in logins:iObservers() do
    local subscription = Subscription{ id=id, logins=logins, registry=self }
    self.subscriptionOf[id] = subscription
    orb:newservant(subscription)
  end
end

function LoginRegistry:loginRemoved(login, observers)
  local orb = self.access.orb
  for observer in pairs(observers) do
    local callback = getObserver(observer, orb)
    schedule(newthread(function()
      local ok, errmsg = pcall(callback.entityLogout, callback, login)
      if not ok then
        log:exception(msg.LoginObserverException:tag{
          observer = observer.id,
          owner = observer.login,
          watched = login.id,
          errmsg = errmsg,
        })
      end
    end))
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
  local logins = {}
  for id, login in AccessControl.activeLogins:iLogins() do
    logins[#logins+1] = login
  end
  return logins
end

function LoginRegistry:getEntityLogins(entity)
  assertCaller(self, entity)
  local logins = {}
  for id, login in AccessControl.activeLogins:iLogins() do
    if login.entity == entity then
      logins[#logins+1] = login
    end
  end
  return logins
end

function LoginRegistry:invalidateLogin(id)
  local login = AccessControl.activeLogins:getLogin(id)
  if login ~= nil then
    local tag = assertCaller(self, login.entity)
    login:remove()
    log[tag](log, msg.LogoutForced:tag{
      login = id,
      entity = login.entity,
    })
    return true
  end
  return false
end

function LoginRegistry:getLoginInfo(id)
  local login = AccessControl.activeLogins:getLogin(id)
  if login ~= nil then
    return login, login.encodedkey
  elseif id == AccessControl.login.id then
    return AccessControl.login, AccessControl.buskey
  end
  InvalidLogins{loginIds={id}}
end

function LoginRegistry:getLoginValidity(id)
  if id == AccessControl.login.id then
    return AccessControl.leaseTime
  end
  local login = AccessControl.activeLogins:getLogin(id)
  if login ~= nil then
    local timeleft = login.deadline-time()
    if timeleft > 0 then
      return ceil(timeleft)
    end
    log:action(msg.LoginExpired:tag{
      login = login.id,
      entity = login.entity,
    })
    login:remove()
  end
  return 0
end

function LoginRegistry:subscribeObserver(callback)
  if callback == nil then
    BAD_PARAM{ completed = "COMPLETED_NO", minor = 0 }
  end
  local logins = AccessControl.activeLogins
  local caller = self.access:getCallerChain().caller
  local login = logins:getLogin(caller.id)
  local observer = login:newObserver(callback)
  local id = observer.id
  local subscription = Subscription{
    id = id,
    owner = login,
    logins = logins,
    registry = self,
  }
  self.subscriptionOf[id] = subscription
  return subscription
end



return {
  CertificateRegistry = CertificateRegistry,
  AccessControl = AccessControl,
  LoginRegistry = LoginRegistry,
}
