local _G = require "_G"
local pairs = _G.pairs
local pcall = _G.pcall
local select = _G.select
local tostring = _G.tostring

local uuid = require "uuid"
local newid = uuid.new

local pubkey = require "lce.pubkey"
local decodekey = pubkey.decodepublic

local oo = require "openbus.util.oo"
local class = oo.class

local idl = require "openbus.core.idl"
local assert = idl.serviceAssertion


local function readTable(table, class, base)
	for id, data in table:ientries() do
		data.base = base
		data.table = table
		class(data)
	end
	return table
end

local function setWatchedOf(self, login, new)
	local loginId = login.id
	local watched = self.watched
	local old = watched[loginId]
	if new ~= old then
		-- start to change data in memory
		watched[loginId] = new
		-- try to update saved data
		local id = self.id
		local success, errmsg = self.table:setentry(id, {
			id = id,
			entity = self.entity,
			ior = self.ior,
			watched = watched,
		})
		if success then
			-- commit the changes in memory
			login.watchers[self] = new
		else
			-- rollback changes and raise error
			watched[loginId] = old
		end
		return success, errmsg
	end
	return true
end


local Observer = class()

function Observer:__init()
	local base = self.base
	local logins = base.logins
	logins[self.entity].observers[self] = true
	for id in pairs(self.watched) do
		logins[id].watchers[self] = true
	end
	base.observers[self.id] = self
end

function Observer:watchLogin(login)
	assert(setWatchedOf(self, login, true))
end

function Observer:forgetLogin(login)
	assert(setWatchedOf(self, login, nil))
end

function Observer:iWatchedLoginIds()
	return pairs(self.watched)
end

function Observer:watchesLoginId(id)
	return self.watched[id] ~= nil
end

function Observer:remove()
	local id = self.id
	assert(self.table:removeentry(id))
	local base = self.base
	local logins = base.logins
	logins[self.entity].observers[self] = nil
	for id in pairs(self.watched) do
		logins[id].watchers[self] = nil
	end
	base.observers[id] = nil
	self.base.publisher:observerRemoved(self)
end


local Login = class()
 
function Login:__init()
	self.pubkey = decodekey(self.encodedkey)
	self.base.logins[self.id] = self
	if self.watchers == nil then self.watchers = {} end
	if self.observers == nil then self.observers = {} end
end

function Login:newObserver(callback)
	local base = self.base
	local table = base.obsTab
	local id = newid("time")
	local data = {
		id = id,
		entity = self.id,
		watched = {},
		callback = callback,
		ior = tostring(callback),
	}
	assert(table:setentry(id, data))
	data.base = base
	data.table = table
	return Observer(data)
end

function Login:iObservers()
	return pairs(self.observers)
end

function Login:iWatchers()
	return pairs(self.watchers)
end

function Login:remove()
	-- collect all watchers and remove the login from they
	local watchers = {}
	for watcher in pairs(self.watchers) do
		watchers[watcher] = true
		watcher:forgetLogin(self)
	end
	-- remove all owned observers
	for observer in pairs(self.observers) do
		observer:remove()
	end
	-- remove this login
	local id = self.id
	assert(self.table:removeentry(id))
	self.base.logins[id] = nil
	-- notify all watchers
	self.base.publisher:loginRemoved(self, watchers)
end


local Database = class()

function Database:__init()
	self.logins = {}
	self.observers = {}
	local db = self.database
	self.lgnTab = select(2, assert(pcall(readTable,
	                                     assert(db:gettable("Logins")),
	                                     Login,
	                                     self)))
	self.obsTab = select(2, assert(pcall(readTable,
	                                     assert(db:gettable("Observers")),
	                                     Observer,
	                                     self)))
end

function Database:newLogin(entity, encodedkey)
	local id = newid("time")
	local data = {
		id = id,
		entity = entity,
		encodedkey = encodedkey,
	}
	local table = self.lgnTab
	assert(table:setentry(id, data))
	data.base = self
	data.table = table
	return Login(data)
end

function Database:getLogin(id)
	return self.logins[id]
end

function Database:iLogins()
	return pairs(self.logins)
end

function Database:getObserver(id)
	return self.observers[id]
end

function Database:iObservers()
	return pairs(self.observers)
end

return Database


--[===[ This is a draft for a future implementation using SQLite3

local SQL_Schema = [[
CREATE TABLE IF NOT EXISTS Logins(
	id        TEXT(36) PRIMARY KEY,
	entity    TEXT NOT NULL)

CREATE TABLE IF NOT EXISTS Observers(
	id     TEXT(36) PRIMARY KEY,
	entity TEXT NOT NULL,
	ior    TEXT NOT NULL,
	FOREIGN KEY(entity) REFERENCES Logins(id))

CREATE TABLE IF NOT EXISTS ObservedLogins(
	login    TEXT(36) NOT NULL,
	observer TEXT(36) NOT NULL,
	PRIMARY KEY(login, observer),
	FOREIGN KEY(login) REFERENCES Logins(id),
	FOREIGN KEY(observer) REFERENCES Observers(id))
]]

local SQL_AddLogin = [[
INSERT INTO Logins VALUES (:id, :entity)
]]

local SQL_AddObserver = [[
INSERT INTO Observers VALUES (:id, :entity, :ior)
]]

local SQL_AddLoginToObserver = [[
INSERT INTO ObservedLogins VALUES (:login, :observer)
]]

local SQL_GetLogin = [[
SELECT entity
FROM Logins
WHERE id = $id
]]

local SQL_GetObserverIor = [[
SELECT ior
FROM Observers
WHERE id = $id
]]

local SQL_GetLoginObservers = [[
SELECT id, ior
FROM Observers JOIN ObservedLogins
WHERE observer = id AND login = $id
]]

local SQL_RemoveLogin = [[
DELETE FROM ObservedLogins WHERE login = $id
DELETE FROM ObservedLogins WHERE entity = (SELECT id FROM Observers WHERE entity = $id)
DELETE FROM Observers WHERE entity = $id
DELETE FROM Logins WHERE id = $id
]]

local SQL_RemoveObserver = [[
DELETE FROM ObservedLogins WHERE observer = $id
DELETE FROM Observers WHERE id = $id
]]

--]===]