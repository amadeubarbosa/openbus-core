require "openbus.base"
local oo = require "openbus.util.oo"

local database = require "openbus.database"

local Credentials = require "core.services.accesscontrol.Credentials"

local Observer = oo.class()
function Observer:__tostring()
	return self.ior
end

local FakeORB = {
	newproxy = function(self, ior, kind, iface)
		local prx = self[ior]
		if prx == nil then
			prx = Observer{ior=ior}
			self[ior] = prx
		end
		return prx
	end,
}

local function assertIterator(expected, ...)
	for key, val in ... do
		assert(expected[key] == val)
		expected[key] = nil
	end
	assert(next(expected) == nil)
end

do
	local creds = Credentials{
		database = assert(database.open("test.db")),
		orb = FakeORB,
	}
	
	local user = creds:newCredential("user")
	local deleg = creds:newCredential("delegator", "delegatee", true)
	
	local obs = user:newObserver(creds.orb:newproxy("userObs", nil, "IObserver"))
	obs:watchCredential(deleg)
	local selfObs = user:newObserver(creds.orb:newproxy("selfObs", nil, "IObserver"))
	selfObs:watchCredential(user)
	local dummyObs = user:newObserver(creds.orb:newproxy("dummyObs", nil, "IObserver"))
	dummyObs:watchCredential(deleg)
	dummyObs:forgetCredential(deleg)
	
	assertIterator({[selfObs] = true}, user:iWatchers())
	assertIterator({[obs] = true}, deleg:iWatchers())
	assertIterator({[deleg.id] = true}, obs:iWatchedCredentialIds())
	assertIterator({[user.id] = true}, selfObs:iWatchedCredentialIds())
	for id in dummyObs:iWatchedCredentialIds() do error("failure") end
end

do
	local creds = Credentials{
		database = assert(database.open("test.db")),
		orb = FakeORB,
	}
	local Data = {
		user = {
			userObs = { delegator=true },
			selfObs = { user=true },
			dummyObs = {},
		},
		delegator = {},
	}
	for id, credential in creds:iCredentials() do
		-- check credential
		local owner = credential.owner
		if owner == "delegator" then
			assert(credential.delegate == "delegatee", "wrong stored credential")
			assert(credential.certified == true, "wrong stored credential")
		else
			assert(credential.delegate == "", "wrong stored credential")
			assert(credential.certified == nil, "wrong stored credential")
		end
		-- check observers owned by this credential
		local observers = assert(Data[credential.owner], "unknown stored credential")
		Data[credential.owner] = nil
		for observer in credential:iObservers() do
			local watched = assert(observers[observer.ior], "wrong credential observer")
			observers[observer.ior] = nil
			for credId in observer:iWatchedCredentialIds() do
				local watchedCred = creds:getCredential(credId)
				assert(watched[watchedCred.owner], "wrong watched credential")
				watched[watchedCred.owner] = nil
			end
			assert(next(watched) == nil, "missing wached credential")
		end
		assert(next(observers) == nil, "missing credential observer")
		-- check observers watching this credential
		local count = 0
		for observer in credential:iWatchers() do
			if credential.owner == "user" then
				assert(observer.ior == "selfObs", "wrong observation")
				count = count+1
			elseif credential.owner == "delegator" then
				assert(observer.ior == "userObs", "wrong observation")
				count = count+1
			else
				error("inexistent observation")
			end
		end
		assert(count == 1, "duplicated observation")
	end
	assert(next(Data) == nil, "missing stored credential")
end


do
	local creds = Credentials{
		database = assert(database.open("test.db")),
		orb = FakeORB,
	}
	local Credentials = {
		user = true,
		delegator = true,
	}
	local Observers = {
		userObs=true,
		selfObs=true,
		dummyObs=true,
	}
	for id, observer in creds:iObservers() do
		assert(Observers[observer.ior], "unknown stored credential")
		Observers[observer.ior] = nil
		observer:remove()
	end
	for id, credential in creds:iCredentials() do
		-- check credential
		assert(Credentials[credential.owner], "unknown stored credential")
		Credentials[credential.owner] = nil
		credential:remove()
		-- check observers owned by this credential
		for observer in credential:iObservers() do
			error("observer not removed")
		end
		-- check observers watching this credential
		for observer in credential:iWatchers() do
			error("observer not removed")
		end
	end
end

do
	local creds = Credentials{
		database = assert(database.open("test.db")),
		orb = FakeORB,
	}
	for id, observer in creds:iObservers() do
		error("observer not removed")
	end
	for id, credential in creds:iCredentials() do
		error("credential not removed")
	end
end

local idl = require "openbus.core.idl"
local function assertEx(errmsg, ...)
	local ok, ex, v1,v2,v3 = pcall(...)
	assert(not ok)
	assert(type(ex) == "table", ex)
	assert(ex[1] == idl.types.ServiceFailure)
	assert(ex.message:find(errmsg), ex.message)
	return ex, v1,v2,v3
end

do
	assert(lfs.rmdir("test.db/Credentials"))
	assert(io.open("test.db/Credentials", "w")):close()
	assertEx("'test%.db/Credentials' expected to be directory %(got file%)",
	         Credentials, {database=assert(database.open("test.db"))})
	assert(os.remove("test.db/Credentials"))
	
	assert(lfs.mkdir("test.db/Credentials"))
	local file = assert(io.open("test.db/Credentials/corrupted.lua", "w"))
	assert(file:write("illegal Lua code"))
	file:close()
	assertEx("unable to load file 'test%.db/Credentials/corrupted.lua' %(test.db/Credentials/corrupted.lua:1: '=' expected near 'Lua'%)",
	         Credentials, {database=assert(database.open("test.db"))})
	
	assert(os.execute("chmod 000 test.db/Credentials") == 0)
	assertEx("cannot open test%.db/Credentials/: Permission denied",
	         Credentials, {database=assert(database.open("test.db"))})
	assert(os.execute("chmod 755 test.db/Credentials") == 0)
	assert(os.remove("test.db/Credentials/corrupted.lua"))
end

do
	local creds = Credentials{
		database = assert(database.open("test.db")),
		orb = FakeORB,
	}
	local user = assert(creds:newCredential("user"))
	local obs = assert(user:newObserver(creds.orb:newproxy("obs", nil, "IObserver")))
	
	assert(os.execute("chmod 000 test.db/Credentials") == 0)
	
	obs:watchCredential(user)
	assertIterator({[obs] = true}, user:iObservers())
	assertIterator({[user.id] = true}, obs:iWatchedCredentialIds())
	
	assert(os.execute("chmod 000 test.db/Observers") == 0)
	
	assertEx("unable to replace file 'test%.db/Observers/[%x-]+.lua' %(with file /tmp/lua_%w+: Permission denied%)",
	         obs.forgetCredential, obs, user)
	assertIterator({[obs] = true}, user:iWatchers())
	assertIterator({[user.id] = true}, obs:iWatchedCredentialIds())
	
	assertEx("unable to replace file 'test%.db/Credentials/[%x-]+.lua' %(with file /tmp/lua_%w+: Permission denied%)",
	         creds.newCredential, creds, "fail")
	assertIterator({[user.id] = user}, creds:iCredentials())
	
	assertEx("unable to remove file 'test%.db/Observers/[%x-]+.lua' %(test%.db/Observers/[%x-]+.lua: Permission denied%)",
	         user.remove, user)
	assert(creds:getCredential(user.id) == user)
	assert(creds:getObserver(obs.id) == obs)
	assertIterator({[obs.id] = obs}, creds:iObservers())
	assertIterator({[user.id] = user}, creds:iCredentials())
	assertIterator({[obs] = true}, user:iObservers())
	
	assert(os.execute("chmod 755 test.db/Observers") == 0)
	obs:forgetCredential(user)
	for _ in user:iWatchers() do error("failure") end
	for _ in obs:iWatchedCredentialIds() do error("failure") end
	
	assert(os.execute("chmod 755 test.db/Credentials") == 0)
	user:remove()
	assert(creds:getCredential(user.id) == nil)
	assert(creds:getObserver(obs.id) == nil)
	for _ in creds:iObservers() do error("failure") end
	for _ in creds:iCredentials() do error("failure") end
end

do
	local lfs = require "lfs"
	assert(lfs.rmdir("test.db/Credentials"))
	assert(lfs.rmdir("test.db/Observers"))
	assert(lfs.rmdir("test.db"))
end
