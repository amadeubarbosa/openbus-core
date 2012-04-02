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

local idl = require "openbus.core.legacy.idl"
local types = idl.types.access_control_service
local throw = idl.throw.access_control_service
local newidl = require "openbus.core.idl"
local newtypes = newidl.types.services.access_control
local newconst = newidl.const.services.access_control

local msg = require "openbus.core.services.messages"
local facets = require "openbus.core.services.AccessControl"

-- Faceta ILeaseProvider -----------------------------------------------------

local function convert(credential)
  credential.id, credential.identifier = credential.identifier, nil
  return credential
end

local ILeaseProvider = {
  __type = types.ILeaseProvider,
  __objkey = "LP_v1_05",
}

function ILeaseProvider:renewLease(credential)
  local manager = facets.AccessControl
  local login = manager.activeLogins:getLogin(credential.identifier)
  if login ~= nil then
    login.leaseRenewed = time()
    log:request(msg.LoginRenewed:tag{login=id,entity=login.entity})
    return true, manager.leaseTime
  end
  return false, 0
end

-- Faceta IAccessControlService ----------------------------------------------

local IAccessControlService = {
  __type = types.IAccessControlService,
  __objkey = "ACS_v1_05",
}

function IAccessControlService:__init(data)
  self.lastChallengeOf = setmetatable({}, { __mode = "v" })
  local access = data.access
  access:setGrantedUsers(self.__type, "loginByPassword", "any")
  access:setGrantedUsers(self.__type, "loginByCertificate", "any")
  access:setGrantedUsers(self.__type, "getChallenge", "any")
  access:setGrantedUsers(self.__type, "isValid", "any")
  access:setGrantedUsers(self.__type, "areValid", "any")
end

-- Login Support

local NullCredential = {identifier="",owner="",delegate=""}
local NullLeaseTime = 0

function IAccessControlService:loginByPassword(id, pwrd)
  local manager = facets.AccessControl
  local ok, login, lease = pcall(manager.loginByPassword, manager, id, pwrd)
  if ok then
    local credential = {
      identifier = login.id,
      owner = login.entity,
      delegate = "",
    }
    return true, credential, lease
  end
  return false, NullCredential, NullLeaseTime
end

function IAccessControlService:getChallenge(id)
  local manager = facets.AccessControl
  local ok, logger, challenge = pcall(manager.startLoginByPassword,manager,id)
  if ok then
    self.lastChallengeOf[id] = logger
    return challenge
  end
  return ""
end

function IAccessControlService:loginByCertificate(id, answer)
  local logger = self.lastChallengeOf[id]
  local ok, login, lease = pcall(logger.login, logger, answer)
  if ok then
    local credential = {
      identifier = login.id,
      owner = login.entity,
      delegate = "",
    }
    return true, credential, lease
  end
  return false, NullCredential, NullLeaseTime
end

function IAccessControlService:logout(credential)
  local manager = facets.AccessControl
  local login = manager:getLoginEntry(credential.identifier)
  if login ~= nil and pcall(login.remove, login) then
    log:request(msg.LogoutPerformed:tag{login=id,entity=login.entity})
    return true
  end
  return false
end

function IAccessControlService:isValid(credential)
  local login = facets.AccessControl:getLoginEntry(credential.identifier)
  return (login ~= nil)
     and (login.entity == credential.owner)
     and (time()-login.leaseRenewed < self.leaseTime)
end

function IAccessControlService:areValid(credentials)
  for index, credential in ipairs(credentials) do
    credentials[index] = self:isValid(credential)
  end
  return credentials
end

-- Credential Observation Support

function IAccessControlService:addObserver(observer, credentials)
  local subscription = facets.LoginRegistry:subscribe(observer)
  subscription:watchLogins(credentials)
  return subscription.id
end

function IAccessControlService:addCredentialToObserver(obsId, credId)
  local subscription = facets.LoginRegistry.subscriptionOf[obsId]
  return subscription:watchLogin(credId)
end

function IAccessControlService:removeObserver(obsId)
  local subscription = facets.LoginRegistry.subscriptionOf[obsId]
  return subscription:remove()
end

function IAccessControlService:removeCredentialFromObserver(obsId, credId)
  local subscription = facets.LoginRegistry.subscriptionOf[obsId]
  return subscription:forgetLogin(credId)
end

-- Fault Tolerancy Support

local function credentialEntry(credential)
  local observers = {}
  local observedBy = {}
  for observer in credential:iObservers() do
    observer[#observer+1] = observer.id
  end
  for observer in credential:iWatchers() do
    observedBy[#observedBy+1] = observer.id
  end
  return {
    aCredential = {
      id = credential.id,
      owner = credential.owner,
      delegate = "",
    },
    certified = credential.certified,
    observers = observers,
    observedBy = observedBy,
  }
end

function IAccessControlService:getEntryCredential(cred)
  local credentials = facets.AccessControl.activeCredentials
  return credentialEntry(credentials:getCredential(cred.id))
end

function IAccessControlService:getAllEntryCredential()
  local credentials = facets.AccessControl.activeCredentials
  local entries = {}
  for id, credential in credentials:iCredentials() do
    entries[#entries+1] = credentialEntry(credential)
  end
  return entries
end

-- Faceta IFaultTolerantService ----------------------------------------------

local IFaultTolerantService = {
  __type = idl.typesFT.IFaultTolerantService,
  __objkey = "FTACS_v1_05",
}

function IFaultTolerantService:init()
  -- intentionally blank
end

function IFaultTolerantService:isAlive()
  return false
end

function IFaultTolerantService:setStatus(isAlive)
  -- intentionally blank
end

function IFaultTolerantService:kill()
  self.context.IComponent:shutdown()
end

function IFaultTolerantService:updateStatus(param)
  return false
end

-- Exported Module -----------------------------------------------------------

return {
  ILeaseProvider = ILeaseProvider,
  IAccessControlService = IAccessControlService,
  IFaultTolerantService = IFaultTolerantService,
}
