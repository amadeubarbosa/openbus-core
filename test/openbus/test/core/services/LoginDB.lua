local hash = require "lce.hash"
local sha256 = hash.sha256
local pubkey = require "lce.pubkey"
local newkey = pubkey.create

local oo = require "openbus.util.oo"
local database = require "openbus.util.database"
local LoginDB = require "openbus.core.services.LoginDB"
local idl = require "openbus.core.idl"
local EncryptedBlockSize = idl.const.EncryptedBlockSize

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

local key = newkey(EncryptedBlockSize):encode("public")

do
  local logins = LoginDB{
    database = assert(database.open("test.db")),
    orb = FakeORB,
  }
  
  local user = logins:newLogin("user", key)
  local deleg = logins:newLogin("delegator", key)
  
  local obs = user:newObserver(logins.orb:newproxy("userObs", nil, "IObserver"))
  obs:watchLogin(deleg)
  local selfObs = user:newObserver(logins.orb:newproxy("selfObs", nil, "IObserver"))
  selfObs:watchLogin(user)
  local dummyObs = user:newObserver(logins.orb:newproxy("dummyObs", nil, "IObserver"))
  dummyObs:watchLogin(deleg)
  dummyObs:forgetLogin(deleg)
  
  assertIterator({[selfObs] = true}, user:iWatchers())
  assertIterator({[obs] = true}, deleg:iWatchers())
  assertIterator({[deleg.id] = true}, obs:iWatchedLoginIds())
  assertIterator({[user.id] = true}, selfObs:iWatchedLoginIds())
  for id in dummyObs:iWatchedLoginIds() do error("failure") end
end

do
  local logins = LoginDB{
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
  for id, login in logins:iLogins() do
    -- check login
    local entity = login.entity
    if entity == "delegator" then
      assert(login.allowLegacyDelegate == true, "wrong stored login")
    else
      assert(login.allowLegacyDelegate == false, "wrong stored login")
    end
    -- check observers owned by this login
    local observers = assert(Data[login.entity], "unknown stored login")
    Data[login.entity] = nil
    for observer in login:iObservers() do
      local watched = assert(observers[observer.ior], "wrong login observer")
      observers[observer.ior] = nil
      for credId in observer:iWatchedLoginIds() do
        local watchedCred = logins:getLogin(credId)
        assert(watched[watchedCred.entity], "wrong watched login")
        watched[watchedCred.entity] = nil
      end
      assert(next(watched) == nil, "missing wached login")
    end
    assert(next(observers) == nil, "missing login observer")
    -- check observers watching this login
    local count = 0
    for observer in login:iWatchers() do
      if login.entity == "user" then
        assert(observer.ior == "selfObs", "wrong observation")
        count = count+1
      elseif login.entity == "delegator" then
        assert(observer.ior == "userObs", "wrong observation")
        count = count+1
      else
        error("inexistent observation")
      end
    end
    assert(count == 1, "duplicated observation")
  end
  assert(next(Data) == nil, "missing stored login")
end


do
  local logins = LoginDB{
    database = assert(database.open("test.db")),
    orb = FakeORB,
  }
  local Logins = {
    user = true,
    delegator = true,
  }
  local Observers = {
    userObs=true,
    selfObs=true,
    dummyObs=true,
  }
  for id, observer in logins:iObservers() do
    assert(Observers[observer.ior], "unknown stored login")
    Observers[observer.ior] = nil
    observer:remove()
  end
  for id, login in logins:iLogins() do
    -- check login
    assert(Logins[login.entity], "unknown stored login")
    Logins[login.entity] = nil
    login:remove()
    -- check observers owned by this login
    for observer in login:iObservers() do
      error("observer not removed")
    end
    -- check observers watching this login
    for observer in login:iWatchers() do
      error("observer not removed")
    end
  end
end

do
  local logins = LoginDB{
    database = assert(database.open("test.db")),
    orb = FakeORB,
  }
  for id, observer in logins:iObservers() do
    error("observer not removed")
  end
  for id, login in logins:iLogins() do
    error("login not removed")
  end
end

local idl = require "openbus.core.idl"
local function assertEx(errmsg, ...)
  local ok, ex, v1,v2,v3 = pcall(...)
  assert(not ok)
  assert(type(ex) == "table", ex)
  assert(ex._repid == idl.types.services.ServiceFailure)
  assert(ex.message:find(errmsg), ex.message)
  return ex, v1,v2,v3
end

do
  local lfs = require "lfs"
  assert(os.remove("test.db"))
end
