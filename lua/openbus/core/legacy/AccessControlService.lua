------------------------------------------------------------------------------
-- OpenBus 1.5 Support
-- $Id: 
------------------------------------------------------------------------------

local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local pairs = _G.pairs
local pcall = _G.pcall
local setmetatable = _G.setmetatable
local type = _G.type

local cothread = require "cothread"
local time = cothread.now

local hash = require "lce.hash"
local sha256 = hash.sha256

local log = require "openbus.util.logger"
local oo = require "openbus.util.oo"
local class = oo.class

local idl = require "openbus.core.legacy.idl"
local types = idl.types.access_control_service
local ILeaseProvider = types.ILeaseProvider
local IAccessControlService = types.IAccessControlService

local newidl = require "openbus.core.idl"
local InvalidLogins = newidl.types.services.access_control.InvalidLogins

local msg = require "openbus.core.services.messages"
local facets = require "openbus.core.services.AccessControl"

-- Faceta ILeaseProvider -----------------------------------------------------

local function convert(credential)
  credential.id, credential.identifier = credential.identifier, nil
  return credential
end

local ILeaseProvider = {
  __facet = "ILeaseProvider_v1_05",
  __type = ILeaseProvider,
  __objkey = "LP_v1_05",
}

function ILeaseProvider:renewLease(credential)
  local control = facets.AccessControl
  local login = control.activeLogins:getLogin(credential.identifier)
  if login ~= nil then
    login.deadline = time()+control.leaseTime+control.expirationGap
    log:request(msg.LoginRenewed:tag{login=login.id,entity=login.entity})
    return true, control.leaseTime
  end
  return false, 0
end

-- Faceta IAccessControlService ----------------------------------------------

local IAccessControlService = {
  __facet = "IAccessControlService_v1_05",
  __type = IAccessControlService,
  __objkey = "ACS_v1_05",
}

function IAccessControlService:__init(data)
  self.lastChallengeOf = setmetatable({}, { __mode = "v" })
  local access = data.access
  local admins = data.admins
  access:setGrantedUsers(self.__type, "loginByPassword", "any")
  access:setGrantedUsers(self.__type, "loginByCertificate", "any")
  access:setGrantedUsers(self.__type, "getChallenge", "any")
  access:setGrantedUsers(self.__type, "isValid", "any")
  access:setGrantedUsers(self.__type, "areValid", "any")
  access:setGrantedUsers(self.__type, "getEntryCredential", admins)
  access:setGrantedUsers(self.__type, "getAllEntryCredential", admins)
end

-- Login Support

local NullCredential = {identifier="",owner="",delegate=""}
local NullLeaseTime = 0

function IAccessControlService:loginByPassword(id, pwrd)
  local control = facets.AccessControl
  local access = control.access
  local pubkey = control.buskey
  local encoder = access.orb:newencoder()
  encoder:put({data=pwrd,hash=sha256(pubkey)}, control.LoginAuthInfo)
  local encrypted, errmsg = access.buskey:encrypt(encoder:getdata())
  if encrypted ~= nil then
    local ok, login, lease = pcall(control.loginByPassword, control,
                                   id, control.buskey, encrypted)
    if ok then
      local credential = {
        identifier = login.id,
        owner = login.entity,
        delegate = "",
      }
      return true, credential, lease
    else
      log:exception(msg.UnableToPerformLoginByPassword:tag{entity=id,error=login})
    end
  else
    log:exception(msg.UnableToEncryptLoginByPasswordData:tag{entity=id,error=errmsg})
  end
  return false, NullCredential, NullLeaseTime
end

function IAccessControlService:getChallenge(id)
  local control = facets.AccessControl
  local ok, logger, challenge = pcall(control.startLoginByCertificate, control,
                                      id)
  if ok then
    self.lastChallengeOf[id] = logger
    return challenge
  end
  log:exception(msg.UnableToStartLoginByCertificate:tag{entity=id,error=logger})
  return ""
end

function IAccessControlService:loginByCertificate(id, answer)
  local logger = self.lastChallengeOf[id]
  if logger ~= nil then
    local control = facets.AccessControl
    local access = control.access
    local secret, errmsg = access.prvkey:decrypt(answer)
    if secret ~= nil then
      local pubkey = control.buskey
      local encoder = access.orb:newencoder()
      encoder:put({data=secret,hash=sha256(pubkey)},
                  control.LoginAuthInfo)
      local encrypted, errmsg = access.buskey:encrypt(encoder:getdata())
      if encrypted ~= nil then
        local ok, login, lease = pcall(logger.login, logger,
                                       pubkey, encrypted)
        if ok then
          local credential = {
            identifier = login.id,
            owner = login.entity,
            delegate = "",
          }
          return true, credential, lease
        else
          log:exception(msg.UnableToPerformLoginByCertificate:tag{entity=id,error=login})
        end
      else
        log:exception(msg.UnableToEncryptLoginByCertificateData:tag{entity=id,error=errmsg})
      end
    else
      log:exception(msg.UnableToDecodeAnswerToChallenge:tag{entity=id,error=errmsg})
    end
  else
    log:exception(msg.NoChallengeFoundForLoginByCertificate:tag{entity=id})
  end
  return false, NullCredential, NullLeaseTime
end

function IAccessControlService:logout(credential)
  local control = facets.AccessControl
  local login = control:getLoginEntry(credential.identifier)
  if login ~= nil then
    local ok, errmsg = pcall(login.remove, login)
    if ok then
      log:request(msg.LogoutPerformed:tag{login=login.id,entity=login.entity})
      return true
    end
    log:exception(msg.UnableToLogout:tag{login=login.id,entity=login.entity})
  else
    log:exception(msg.AttemptToLogoutInvalidLogin:tag{login=credential.identifier})
  end
  return false
end

function IAccessControlService:isValid(credential)
  local control = facets.AccessControl
  local login = control:getLoginEntry(credential.identifier)
  if login ~= nil then
    return time() < login.deadline
       and (credential.delegate == "" or login.allowLegacyDelegate)
  else
    return credential.identifier == control.login.id 
       and credential.delegate == ""
  end
  return false
end

function IAccessControlService:areValid(credentials)
  for index, credential in ipairs(credentials) do
    credentials[index] = self:isValid(credential)
  end
  return credentials
end

-- Credential Observation Support

function IAccessControlService:addObserver(observer, loginIds)
  local subscription = facets.LoginRegistry:subscribeObserver(observer, true)
  subscription:watchLogins(loginIds)
  return subscription.id
end

function IAccessControlService:addCredentialToObserver(obsId, loginId)
  local subscription = facets.LoginRegistry.subscriptionOf[obsId]
  if subscription ~= nil then
    local ok, res = pcall(subscription.watchLogin, subscription, loginId)
    if type(res) == "table" and res._repid ~= InvalidLogins then
      error(res)
    end
    return ok and res
  end
  return false
end

function IAccessControlService:removeObserver(obsId)
  local subscription = facets.LoginRegistry.subscriptionOf[obsId]
  if subscription ~= nil then
    subscription:remove()
    return true
  end
  return false
end

function IAccessControlService:removeCredentialFromObserver(obsId, loginId)
  local subscription = facets.LoginRegistry.subscriptionOf[obsId]
  if subscription ~= nil then
    if subscription.observer.watched[loginId] == nil then
      return false
    end
    subscription:forgetLogin(loginId)
    return true
  end
  return false
end

-- Fault Tolerancy Support

local emptyEntry = {
  aCredential = {
    identifier = "",
    owner = "",
    delegate = "",
  },
  certified = false,
  observers = {},
  observedBy = {}
}

local function credentialEntry(login)
  if login == nil then return emptyEntry end
  local observers = {}
  local observedBy = {}
  for observer in login:iObservers() do
    observer[#observer+1] = observer.id
  end
  for observer in login:iWatchers() do
    observedBy[#observedBy+1] = observer.id
  end
  return {
    aCredential = {
      identifier = login.id,
      owner = login.entity,
      delegate = "",
    },
    certified = login.allowLegacyDelegate,
    observers = observers,
    observedBy = observedBy,
  }
end

function IAccessControlService:getEntryCredential(cred)
  local login = facets.AccessControl.activeLogins:getLogin(cred.identifier)
  return credentialEntry(login)
end

function IAccessControlService:getAllEntryCredential()
  local entries = {}
  for id, login in facets.AccessControl.activeLogins:iLogins() do
    entries[#entries+1] = credentialEntry(login)
  end
  return entries
end

-- Faceta IFaultTolerantService ----------------------------------------------

local IFaultTolerantService = {
  __facet = "IFaultTolerantService_v1_05",
  __type = idl.typesFT.IFaultTolerantService,
  __objkey = "FTACS_v1_05",
}

function IFaultTolerantService:init()
  -- intentionally blank
end

function IFaultTolerantService:isAlive()
  -- intentionally blank
  return false
end

function IFaultTolerantService:setStatus(isAlive)
  -- intentionally blank
end

function IFaultTolerantService:kill()
  -- intentionally blank
end

function IFaultTolerantService:updateStatus(param)
  -- intentionally blank
  return false
end

-- Exported Module -----------------------------------------------------------

return {
  ILeaseProvider = ILeaseProvider,
  IAccessControlService = IAccessControlService,
  IFaultTolerantService = IFaultTolerantService,
}
