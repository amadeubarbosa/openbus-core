-- $Id$

local _G = require "_G"
local assert = _G.assert
local ipairs = _G.ipairs
local pairs = _G.pairs
local rawset = _G.rawset

local cothread = require "cothread"
local time = cothread.now

local math = require "math"
local max = math.max

local uuid = require "uuid"
local newid = uuid.new

local lce = require "lce"
local readcertificate = lce.x509.readfromderstring
local encrypt = lce.cipher.encrypt
local decrypt = lce.cipher.decrypt

local Publisher = require "loop.object.Publisher"

local Timer = require "cothread.Timer"

local oo = require "openbus.util.oo"
local class = oo.class
local sysex = require "openbus.util.sysex"
local log = require "openbus.util.logger"

local idl = require "openbus.core.idl"
local assert = idl.serviceAssertion
local throw = idl.throw.services.access_control
local types = idl.types.services.access_control
local const = idl.const.services.access_control

local msg = require "openbus.core.services.messages"
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
	self.database = data.database
	self.certificateDB = assert(self.database:gettable("Certificates"))
	
	local access = data.access
	local admins = data.admins
	access:setGrantedUsers(self.__type, "registerCertificate", admins)
	access:setGrantedUsers(self.__type, "getCertificate", admins)
	access:setGrantedUsers(self.__type, "removeCertificate", admins)
end

function CertificateRegistry:getPublicKey(entity)
	local certificate, errmsg = self.certificateDB:getentry(entity)
	if certificate ~= nil then
		return assert(assert(readcertificate(certificate)):getpublickey())
	elseif errmsg ~= nil then
		assert(nil, errmsg)
	end
end

-- IDL operations

function CertificateRegistry:registerCertificate(entity, certificate)
	log:admin(msg.RegisterEntityCertificate:tag{entity=entity})
	local certobj, errmsg = readcertificate(certificate)
	if not certobj then
		throw.InvalidCertificate{error=errmsg}
	end
	local pubkey, errmsg = certobj:getpublickey()
	if not pubkey then
		throw.InvalidCertificate{error=errmsg}
	end
	assert(self.certificateDB:setentry(entity, certificate))
end

function CertificateRegistry:getCertificate(entity)
	log:admin(msg.RecoverEntityCertificate:tag{entity=entity})
	local certificate, errmsg = self.certificateDB:getentry(entity)
	if certificate == nil then
		if errmsg ~= nil then
			throw.ServiceFailure{message=errmsg}
		end
		throw.MissingCertificate{entity=entity}
	end
	return certificate
end

function CertificateRegistry:removeCertificate(entity)
	log:admin(msg.RemoveEntityCertificate:tag{entity=entity})
	local db = self.certificateDB
	if db:getentry(entity) ~= nil then
		assert(db:removeentry(entity))
	end
end

------------------------------------------------------------------------------
-- Faceta LoginManager
------------------------------------------------------------------------------

local SelfLogin = {
	id = newid("new"),
	entity = idl.const.BusId,
	leaseRenewed = inf,
}

local function renewLogin(login)
	login.leaseRenewed = time()
end



local LoginByCertificate = class{ __type = types.LoginByCertificate }

function LoginByCertificate:cancel()
	local manager = self.manager
	manager.orb:deactivate(self)
	manager.pendingChallenges[self] = nil
end

function LoginByCertificate:login(answer)
	self:cancel()
	local manager = self.manager
	local entity = self.entity
	local decoded, errmsg = decrypt(manager.privateKey, answer)
	if decoded == nil then
		throw.WrongEncoding{errmsg=errmsg or "no error message provided"}
	end
	if decoded ~= self.secret then
		throw.AccessDenied{entity=entity}
	end
	local login = manager.activeLogins:newLogin(entity, true)
	renewLogin(login)
	log:request(msg.LoginByCertificate:tag{
		login = login.id,
		entity = entity,
	})
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
	local access = data.access
	access.logins = self
	access.login = SelfLogin
	access:setGrantedUsers(self.__type, "loginByPassword", "any")
	access:setGrantedUsers(self.__type, "startLoginByCertificate", "any")
	access:setGrantedUsers(LoginByCertificate.__type, "*", "any")
	
	-- initialize attributes
	self.access = access
	self.database = data.database
	self.certificate = data.certificate
	self.privateKey = data.privateKey
	self.passwordValidators = data.validators
	self.leaseTime = data.leaseTime
	self.expirationGap = data.expirationGap
	self.activeLogins = Logins{
		database = self.database,
		publisher = self.publisher,
	}
	self.pendingChallenges = {}
	
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
				log:action(msg.LoginByCertificateExpired:tag{entity=process.entity})
				process:cancel()
			end
		end
	end
	self.sweepTimer:enable()
end

function AccessControl:shutdown()
	self.sweepTimer:disable()
end

function AccessControl:getLoginEntry(id)
	return self.activeLogins:getLogin(id)
end

-- IDL operations

function AccessControl:loginByPassword(entity, password)
	if entity ~= SelfLogin.entity then
		local decoded, errmsg = decrypt(self.privateKey, password)
		if decoded == nil then
			throw.WrongEncoding{errmsg=errmsg or "no error message provided"}
		end
		for _, validator in ipairs(self.passwordValidators) do
			local valid, errmsg = validator.validate(entity, decoded)
			if valid then
				local login = self.activeLogins:newLogin(entity)
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
	end
	throw.AccessDenied{entity=entity}
end

function AccessControl:startLoginByCertificate(entity)
	local publickey = CertificateRegistry:getPublicKey(entity)
	if publickey == nil then
		throw.MissingCertificate{entity=entity}
	end
	local logger = LoginByCertificate{
		manager = self,
		entity = entity,
		secret = newid("new"),
	}
	self.pendingChallenges[logger] = time()
	log:request(msg.LoginByCertificateInitiated:tag{ entity = entity })
	return logger, assert(encrypt(publickey, logger.secret))
end

function AccessControl:logout()
	local chain = self.access:getCallerChain()
	local id = chain[#chain].id
	local login = self.activeLogins:getLogin(id)
	login:remove()
	log:request(msg.LogoutPerformed:tag{login=id,entity=login.entity})
end

function AccessControl:renew()
	local chain = self.access:getCallerChain()
	local id = chain[#chain].id
	local login = self.activeLogins:getLogin(id)
	renewLogin(login)
	log:request(msg.LoginRenewed:tag{login=id,entity=login.entity})
	return self.leaseTime
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
	local login = self.logins.activeLogins:getLogin(id)
	if login ~= nil then
		self.observer:watchLogin(login)
		return true
	end
	return false
end

function Subscription:forgetLogin(id)
	local login = self.logins.activeLogins:getLogin(id)
	if login ~= nil then
		self.observer:forgetLogin(login)
	end
end

function Subscription:watchLogins(ids)
	local logins = self.logins.activeLogins
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
	local result = {}
	local logins = self.logins.activeLogins
	for id in self.observer:iWatchedLoginIds() do
		result[#result+1] = logins:getLogin(id)
	end
	return result
end

function Subscription:remove()
	self.observer:remove()
end



LoginRegistry = {
	__type = types.LoginRegistry,
	__objkey = const.LoginRegistryFacet,
}

-- local operations

function LoginRegistry:__init(data)
	local access = data.access
	local admins = data.admins
	access:setGrantedUsers(self.__type, "getAllLogins", admins)
	access:setGrantedUsers(self.__type, "getEntityLogins", admins)
	access:setGrantedUsers(self.__type, "terminateLogin", admins)
	-- initialize attributes
	self.access = access
	-- register itself to receive logout notifications
	rawset(AccessControl.publisher, self, self)
	-- restaura servants dos observadores persistidos
	local orb = access.orb
	local logins = AccessControl.activeLogins
	for id, observer in logins:iObservers() do
		local subscription = Subscription{ id=id, logins=logins }
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

function LoginRegistry:observerRemoved(observer)
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
	local logins = {}
	for id, login in AccessControl.activeLogins:iLogins() do
		if login.entity == entity then
			logins[#logins+1] = login
		end
	end
	return logins
end

function LoginRegistry:terminateLogin(id)
	local login = AccessControl.activeLogins:getLogin(id)
	if login ~= nil then
		login:remove()
		log:request(msg.LogoutForced:tag{login=id,entity=login.entity})
		return true
	end
	return false
end

function LoginRegistry:getLoginInfo(id)
	local login = AccessControl.activeLogins:getLogin(id)
	if login ~= nil then
		return login
	elseif id == SelfLogin.id then
		return SelfLogin
	end
	throw.InvalidLogins{loginIds={id}}
end

function LoginRegistry:getValidity(ids)
	local logins = AccessControl.activeLogins
	local leaseTime = AccessControl.leaseTime
	local expirationGap = AccessControl.expirationGap
	local now = time()
	local validity = {}
	for index, id in ipairs(ids) do
		local login = logins:getLogin(id)
		if login ~= nil then
			validity[index] = max(expirationGap, leaseTime-(now-login.leaseRenewed))
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
	local chain = self.access:getCallerChain()
	local login = logins:getLogin(chain[#chain].id)
	local observer = login:newObserver(callback)
	local subscription = Subscription{ id=observer.id, logins=logins }
	self.subscriptionOf[observer.id] = subscription
	return subscription
end



return {
	CertificateRegistry = CertificateRegistry,
	AccessControl = AccessControl,
	LoginRegistry = LoginRegistry,
}
