local _G = require "_G"
local print = _G.print
local pairs = _G.pairs
local pcall = _G.pcall
local select = _G.select
local tostring = _G.tostring

local uuid = require "uuid"
local newid = uuid.new

local pubkey = require "lce.pubkey"
local decodekey = pubkey.decodepublic

local Publisher = require "loop.object.Publisher"

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
    local db = self.base.database
    local success, errmsg
    if new == true then
      success, errmsg = assert(db:pexec("addWatchedLogin", id, loginId))
    else
      success, errmsg = assert(db:pexec("delWatchedLogin", id, loginId))
    end
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
  logins[self.login].observers[self] = true
  local stmt = base.database.pstmts.getWatchedLoginByObserver
  local observer_id = self.id
  stmt:bind_values(observer_id)
  local watched = {}
  for entry in stmt:nrows() do
    local id = entry.login
    watched[id] = true
    logins[id].watchers[self] = true
  end
  self.watched = watched
  base.observers[observer_id] = self
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
  local base = self.base
  local db = base.database
  assert(db:pexec("delLoginObserver", id))
  local logins = base.logins
  logins[self.login].observers[self] = nil
  for id in pairs(self.watched) do
    logins[id].watchers[self] = nil
  end
  base.observers[id] = nil
  self.base.publisher:loginObserverRemoved(self)
end


local Login = class()
 
function Login:__init()
  self.pubkey = assert(decodekey(self.encodedkey))
  self.base.logins[self.id] = self
  if self.watchers == nil then self.watchers = {} end
  if self.observers == nil then self.observers = {} end
end

function Login:newObserver(callback, legacy)
  local base = self.base
  local id = newid("time")
  local ior = tostring(callback)
  local login = self.id
  local data = {
    id = id,
    login = login,
    ior = ior,
    legacy = legacy or false,
  }
  local db = base.database
  assert(db:pexec("addLoginObserver", id, ior, (legacy and 1) or 0, login))
  data.callback = callback
  data.base = base
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
  local db = self.base.database
  assert(db:pexec("delLogin", id))
  self.base.logins[id] = nil
  -- notify all watchers
  self.base.publisher:loginRemoved(self, watchers)
end


local Database = class()

function Database:__init()
  self.logins = {}
  self.observers = {}
  self.publisher = Publisher(self.publisher)
  local db = self.database
  for entry in db.pstmts.getLogin:nrows() do
    entry.base = self
    entry.allowLegacyDelegate = (entry.allowLegacyDelegate == 1)
    Login(entry)
  end
  for entry in db.pstmts.getLoginObserver:nrows() do
    entry.base = self
    entry.legacy = (entry.legacy == 1)
    Observer(entry)
  end
end

function Database:newLogin(entity, encodedkey, allowLegacyDelegate)
  local id = newid("time")
  local data = {
    id = id,
    entity = entity,
    encodedkey = encodedkey,
    allowLegacyDelegate = allowLegacyDelegate or false
  }
  assert(self.database:pexec("addLogin", id, entity, encodedkey,
			     (allowLegacyDelegate and 1) or 0))
  data.base = self
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
