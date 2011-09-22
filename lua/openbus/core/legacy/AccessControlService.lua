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

local sysex = require "openbus.util.sysex"

local idl = require "openbus.core.legacy.idl"
local types = idl.types.access_control_service
local throw = idl.throw.access_control_service
local newidl = require "openbus.core.idl"
local newtypes = newidl.types.services.access_control
local newconst = newidl.const.services.access_control

local msg = require "openbus.core.services.messages"
local facets = require "openbus.core.services.AccessControl"

-- Faceta IManagement --------------------------------------------------------

local IManagement = {
	__type = types.IManagement,
	__objkey = "MGM_v1_05",
}

function IManagement:startup(data)
	local access = data.access
	local admins = data.admins
	-- systems
	access:setGrantedUsers(self.__type,"addSystem",admins)
	access:setGrantedUsers(self.__type,"removeSystem",admins)
	access:setGrantedUsers(self.__type,"setSystemDescription",admins)
	-- deployments
	access:setGrantedUsers(self.__type,"addSystemDeployment",admins)
	access:setGrantedUsers(self.__type,"removeSystemDeployment",admins)
	access:setGrantedUsers(self.__type,"setSystemDeploymentDescription",admins)
	access:setGrantedUsers(self.__type,"setSystemDeploymentCertificate",admins)
	-- users
	access:setGrantedUsers(self.__type,"addUser",admins)
	access:setGrantedUsers(self.__type,"removeUser",admins)
	access:setGrantedUsers(self.__type,"setUserName",admins)
	
	self.access = access
end

-- private operations

local function assertParam(cond)
	if not cond then
		sysex.BAD_PARAM{ completed = "NO" }
	end
end

local function getRegistry(self)
	local rgs = self.context:getConnected("RegistryServiceReceptacle")
	if rgs == nil then
		log:misconfig(msg.RegistryServiceReceptacleNotConnected)
		sysex.NO_RESOURCES{ completed = "NO" }
	end
	local registry = rgs:getFacetByName(newconst.EntityRegistryFacetName)
	if registry == nil then
		log:misconfig(msg.RegistryServiceReceptacleWrongConnection)
		sysex.NO_RESOURCES{ completed = "NO" }
	end
end

local function getSystem(self, id)
	assertParam(id ~= "Users")
	local category = getRegistry(self):getEntityCategory(id)
	if category == nil or id == "Users" then
		throw.SystemNonExistent{id=id}
	end
	return category
end

local function getSysDeploy(self, id)
	local entity = getRegistry(self):getEntity(id)
	if entity == nil or entity.category.id == "Users" then
		throw.SystemDeploymentNonExistent{id=id}
	end
	return entity
end

local function getUser(self, id)
	local entity = getRegistry(self):getEntity(id)
	if entity == nil or entity.category.id ~= "Users" then
		throw.UserNonExistent{id=id}
	end
	return entity
end

-- System Support

function IManagement:addSystem(id, description)
	assertParam(id ~= "Users")
	local entities = getRegistry(self)
	local existing = entities:getEntityCategory(id)
	if existing ~= nil then
		throw.SystemAlreadyExists{id=id,description=existing.name}
	end
	return entities:createEntityCategory(id, description)
end

function IManagement:removeSystem(id)
	local category = getSystem(self,id)
	for entity in category:iEntities() do
		throw.SystemInUse{id=id,deploymentId=entity.id}
	end
	category:remove()
end

function IManagement:setSystemDescription(id, description)
	getSystem(self,id):setName(description)
end

function IManagement:getSystem(id)
	return { id = id, description = getSystem(self,id).name }
end

function IManagement:getSystems()
	local systems = {}
	for index, category in ipairs(getRegistry(self):getEntityCategories()) do
		if category.id ~= "Users" then
			systems[#systems+1] = {id=category.id,description=category.name}
		end
	end
	return systems
end

-- System Deployment Support

function IManagement:addSystemDeployment(id, sysId, description, certificate)
	assertParam(sysId ~= "Users")
	local entities = getRegistry(self)
	-- assert ID is not taken
	local existing = entities:getEntity(id)
	if existing ~= nil then
		assertParam(existing.category.id ~= "Users") -- no collision with users
		throw.SystemDeploymentAlreadyExists{id=id,description=existing.name}
	end
	-- find the system
	local category = entities:getEntityCategory(sysId)
	if category == nil then
		throw.SystemNonExistent{id=sysId}
	end
	-- atomic registration of system deployment with certificate
	local deploy = entities:registerEntity(id, description)
	local certificates = facets.CertificateRegistry
	local ok, ex = pcall(certificates.registerCertificate, certificates,
	                     id, certificate)
	if not ok then
		deploy:remove()
	end
end

function IManagement:removeSystemDeployment(id)
	getSysDeploy(self,id):remove()
end

function IManagement:getSystemDeploymentCertificate(id)
	throw.SystemDeploymentNonExistent()
end

function IManagement:setSystemDeploymentCertificate(id, certificate)
	local certificates = facets.CertificateRegistry
	local ok, ex = pcall(certificates.registerCertificate, certificates,
	                     id, certificate)
	if not ok and ex._repid == newtypes.InvalidCertificate then
		throw.InvalidCertificate{}
	end
end

function IManagement:setSystemDeploymentDescription(id, description)
	getSysDeploy(self,id):setName(description)
end

function IManagement:getSystemDeployment(id)
	local deploy = getSysDeploy(self,id)
	return { id=id, systemId=deploy.category.id, description=deploy.name }
end

function IManagement:getSystemDeployments()
	local deploys = {}
	for _, entity in ipairs(getRegistry(self):getEntities()) do
		local categoryId = entity.category:_get_id()
		if categoryId ~= "Users" then
			deploys[#deploys+1] = {
				id = entity.id,
				systemId = categoryId,
				description = entity.name,
			}
		end
	end
  return deploys
end

function IManagement:getSystemDeploymentBySystemId(sysId)
	assertParam(sysId ~= "Users")
	local deploys = {}
	local category = getRegistry(self):getEntityCategory(sysId)
	if category ~= nil then
		for _, entity in ipairs(category:getEntities()) do
			deploys[#deploys+1] = {
				id = entity.id,
				systemId = sysId,
				description = entity.name,
			}
		end
	end
	return deploys
end

-- User Management Support

function IManagement:addUser(id, name)
	local entities = getRegistry(self)
	local existing = entities:getEntity(id)
	if existing ~= nil then
		assertParam(existing.category.id == "Users")
		throw.UserAlreadyExists{id=id,name=existing.name}
	end
	local category = entities:getEntityCategory("Users")
	if category == nil then
		category = entities:createEntityCategory("Users",
		                                         "Usuários do Openbus 1.5")
	end
	category:newEntity(id, name)
end

function IManagement:removeUser(id)
	getUser(self,id):remove()
end

function IManagement:setUserName(id, name)
	getUser(self,id):setName(name)
end

function IManagement:getUser(id)
	return { id = id, name = getUser(self,id).name }
end

function IManagement:getUsers()
	local users = {}
	local category = getRegistry(self):getEntityCategory("Users")
	if category ~= nil then
		for _, entity in ipairs(category:getEntities()) do
			users[#users+1] = { id=entity.id, name=entity.name }
		end
	end
  return users
end

-- Automatic Inheritance of Caller Rights through Delegation -----------------

local function endDelegation(access, ...)
	access:restoreOwnRights()
	return ...
end

for key, value in pairs(IManagement) do
	if key ~= "startup" and type(value) == "function" then
		IManagement[key] = function(self, ...)
			local access = self.access
			access:inheritCallerRights()
			return endDelegation(access, value(self, ...))
		end
	end
end

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

function IAccessControlService:startup(data)
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
	local login = manager.activeLogins:getLogin(credential.identifier)
	if login ~= nil and pcall(login.remove, login) then
		log:request(msg.LogoutPerformed:tag{login=id,entity=login.entity})
		return true
	end
	return false
end

function IAccessControlService:isValid(credential)
	local login = facets.AccessControl:getLoginInfo(credential.identifier)
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
	IManagement = IManagement,
	ILeaseProvider = ILeaseProvider,
	IAccessControlService = IAccessControlService,
	IFaultTolerantService = IFaultTolerantService,
}
