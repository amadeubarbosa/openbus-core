local table = require "loop.table"
local cached = require "loop.cached"
local checks = require "loop.test.checks"
local Fixture = require "loop.test.Fixture"
local Suite = require "loop.test.Suite"

local oil = require "oil"
local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local openbus = require "openbus"
local idl = require "openbus.core.idl"
local srvtypes = idl.types.services
local logintypes = srvtypes.access_control


-- Configurações --------------------------------------------------------------

require "openbus.test.core.services.utils"

local FakeLoginId = "Fake Login ID"
local isEmptyList = checks.like({n=0}, nil, {isomorphic=true})

-- Funções auxiliares ---------------------------------------------------------

local function isLoginSubscription(observer)
  return function (subs)
    checks.assert(subs:_is_a(logintypes.LoginObserverSubscription), checks.equal(true))
    return true
  end
end

local LoginsFixture = cached.class({}, IdentityFixture)

function LoginsFixture:getMyLogins()
  local set = {}
  for conn in pairs(self.connections) do
    local login = conn.login
    if login ~= nil then
      set[login.id] = login
    end
  end
  return set
end

function LoginsFixture:subscribeLoginObs()
  -- create new observer
  local observer = newObserver({ entityLogout = true }, self.openbus.context)
  -- subscribe a new observer and validate some of its operations
  local subscription = self.logins:subscribeObserver(observer)
  checks.assert(subscription, isLoginSubscription(observer))
  return subscription, observer
end

function LoginsFixture:setup(openbus)
  IdentityFixture.setup(self, openbus)
  local logins = self.logins
  if logins == nil then
    logins = openbus.context:getLoginRegistry()
    self.logins = logins
  end
end

-- Testes do LoginRegistry ----------------------------------------------------

return OpenBusFixture{
  Suite{
    AsUser = LoginsFixture{
      identity = "user",
      tests = makeSimpleTests{
        logins = {
          getAllLogins = {
            Unauthorized = {
              params = {},
              except = checks.like{_repid=srvtypes.UnauthorizedOperation},
            },
          },
          getEntityLogins = {
            Unauthorized = {
              params = { "fake" },
              except = checks.like{_repid=srvtypes.UnauthorizedOperation},
            },
          },
          invalidateLogin = {
            Invalid = {
              params = { FakeLoginId },
              result = { checks.equal(false) },
            },
          },
          getLoginInfo = {
            Invalid = {
              params = { FakeLoginId },
              except = checks.like{
                _repid = logintypes.InvalidLogins,
                loginIds = { FakeLoginId },
              },
            },
          },
          getLoginValidity = {
            Invalid = {
              params = { FakeLoginId },
              result = { checks.equal(0) },
            },
          },
          subscribeObserver = {
            Null = {
              params = { nil },
              except = checks.like{
                _repid = sysex.BAD_PARAM,
                completed = "COMPLETED_NO",
                minor = 0,
              },
            },
          },
        },
        GetInfoOfEntityLogins = function (fixture, openbus)
          local logins = fixture.logins
          local login = openbus.context:getCurrentConnection().login
          checks.assert(logins:getEntityLogins(user), checks.like({login}))
        end,
        GetInfoOfAllLogins = function (fixture)
          local logins = fixture.logins
          for id, login in pairs(fixture:getMyLogins()) do
            checks.assert(logins:getLoginInfo(id), checks.like(login))
          end
        end,
        GetValidityOfAllLogins = function (fixture)
          local logins = fixture.logins
          for id in pairs(fixture:getMyLogins()) do
            checks.assert(logins:getLoginValidity(id), checks.greater(0))
          end
        end,
        InvalidateLogin = function (fixture)
          local conn = fixture:newConn("user")
          local login = conn.login.id
          local logins = fixture.logins
          checks.assert(logins:invalidateLogin(login), checks.equal(true))
          checks.assert(logins:getLoginValidity(login), checks.equal(0))
          local ok, err = pcall(logins.getLoginInfo, logins, login)
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{
            _repid = logintypes.InvalidLogins,
            loginIds = { login },
          })
        end,
        InvalidateLoginUnauthorized = function (fixture)
          local conn = fixture:newConn("system")
          local login = conn.login.id
          local logins = fixture.logins
          local ok, err = pcall(logins.invalidateLogin, logins, login)
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{
            _repid = srvtypes.UnauthorizedOperation,
          })
        end,
        InvalidObserverWatchingOtherLogin = function (fixture)
          local logins = fixture.logins
          local observer = {}
          local subscription = logins:subscribeObserver(observer)
          checks.assert(subscription, isLoginSubscription(observer))
          local conn = fixture:newConn("user")
          checks.assert(subscription:watchLogin(conn.login.id), checks.equal(true))
          conn:logout()
          -- CORBA Error should happen in the BUS side and can`t be checked here.
          -- The CORBA error is either NO_PERMISSION or NO_IMPLEMENT depending
          -- whether the notification arrives after or before the 'teardown'.
        end,
        InvalidObserverWatchingOwnLogin = function (fixture, openbus)
          local conn = fixture:newConn("user")
          openbus.context:setDefaultConnection(conn)
          local logins = fixture.logins
          local observer = {}
          local subscription = logins:subscribeObserver(observer)
          checks.assert(subscription, isLoginSubscription(observer))
          checks.assert(subscription:watchLogin(conn.login.id), checks.equal(true))
          conn:logout()
          -- CORBA Error should happen in the BUS side and can`t be checked here.
          -- The CORBA error is always NO_PERMISSION.
        end,
        EmptyObserver = function (fixture, openbus)
          local subs = fixture:subscribeLoginObs()
          -- try add fake logins
          checks.assert(subs:watchLogin(FakeLoginId), checks.equal(false))
          local ok, err = pcall(subs.watchLogins, subs, {FakeLoginId})
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{
            _repid = logintypes.InvalidLogins,
            loginIds = { FakeLoginId },
          })
          checks.assert(subs:getWatchedLogins(), isEmptyList)
          -- try forget logins that are not observed
          local login = openbus.context:getCurrentConnection().login.id
          subs:forgetLogin(FakeLoginId)
          subs:forgetLogin(login)
          subs:forgetLogins{FakeLoginId, login}
          checks.assert(subs:getWatchedLogins(), isEmptyList)
        end,
        ObserverOfOtherLogin = function (fixture, openbus)
          local subscription, observer = fixture:subscribeLoginObs()
          -- watch a new login that will be logged out later
          local conn = fixture:newConn("system")
          local login = conn.login
          checks.assert(subscription:watchLogin(login.id), checks.equal(true))
          checks.assert(subscription:getWatchedLogins(), checks.like{login})
          -- logout the created login
          checks.assert(conn:logout(), checks.equal(true))
          -- wait for the notification
          local notified = observer:_wait("entityLogout")
          checks.assert(notified, checks.like(login))
        end,
        ObserverOfOwnLogin = function (fixture, openbus)
          -- assume new login that can be logged out later
          local conn = fixture:newConn("user")
          local context = openbus.context
          context:setCurrentConnection(conn)
          -- create new observer with the new login
          local subscription, observer = fixture:subscribeLoginObs()
          -- watch the new login
          local login = conn.login
          checks.assert(subscription:watchLogin(login.id), checks.equal(true))
          checks.assert(subscription:getWatchedLogins(), checks.like{login})
          -- logout the created login
          checks.assert(conn:logout(), checks.equal(true))
          -- wait for the notification
          local notified = observer:_wait("entityLogout")
          checks.assert(notified, checks.like(login))
        end,
        ObserverOfTerminatedLogin = function (fixture, openbus)
          local subscription, observer = fixture:subscribeLoginObs()
          -- watch a new login that will be terminated later
          local conn = fixture:newConn("system")
          local login = conn.login
          checks.assert(subscription:watchLogin(login.id), checks.equal(true))
          checks.assert(subscription:getWatchedLogins(), checks.like{login})
          -- terminate the created login
          local context = openbus.context
          local admin = fixture:newConn("admin")
          local bak = context:setCurrentConnection(admin)
          checks.assert(fixture.logins:invalidateLogin(login.id), checks.equal(true))
          context:setCurrentConnection(bak)
          -- wait for the notification
          local notified = observer:_wait("entityLogout")
          checks.assert(notified, checks.like(login))
        end,
        ObserverOfOwnTermination = function (fixture, openbus)
          -- assume new login that can be terminated later
          local conn = fixture:newConn("user")
          local context = openbus.context
          context:setCurrentConnection(conn)
          -- create new observer with the new login
          local subscription, observer = fixture:subscribeLoginObs()
          -- watch the new login
          local login = conn.login
          checks.assert(subscription:watchLogin(login.id), checks.equal(true))
          checks.assert(subscription:getWatchedLogins(), checks.like{login})
          -- terminate the created login
          context:setCurrentConnection(nil)
          checks.assert(fixture.logins:invalidateLogin(login.id), checks.equal(true))
          -- wait for the notification
          local notified = observer:_wait("entityLogout")
          checks.assert(notified, checks.like(login))
        end,
        ObserverOfMultipleLogins = function (fixture, openbus)
          local subscription, observer = fixture:subscribeLoginObs()
          -- watch a new logins that will be logged out later
          local istrue = checks.equal(true)
          local conns = {}
          local ids = {}
          local loginmap = {}
          for i = 1, 3 do
            local conn = fixture:newConn("system")
            conns[i] = conn
            ids[i] = conn.login.id
            loginmap[conn.login.id] = conn.login.entity
          end
          subscription:watchLogins(ids)
          -- check list of observed logins
          local observed = subscription:getWatchedLogins()
          checks.assert(observed, checks.type("table"))
          local observedmap = {}
          for _, login in ipairs(observed) do
            observedmap[login.id] = login.entity
          end
          checks.assert(observedmap, checks.like(loginmap, nil, {isomorphic=true}))
          -- logout connections and wait for the notification
          for _, conn in ipairs(conns) do
            local login = conn.login
            checks.assert(conn:logout(), checks.equal(true))
            local notified = observer:_wait("entityLogout")
            checks.assert(notified, checks.like(login))
          end
        end,
        ObserverOfRepeatedLogin = function (fixture, openbus)
          local subscription, observer = fixture:subscribeLoginObs()
          -- new login that will be logged out later
          local conn = fixture:newConn("system")
          local login = conn.login
          -- watch the new login many times
          local istrue = checks.equal(true)
          local isloginlist = checks.like{login}
          checks.assert(subscription:watchLogin(login.id), istrue)
          checks.assert(subscription:getWatchedLogins(), isloginlist)
          checks.assert(subscription:watchLogin(login.id), istrue)
          checks.assert(subscription:getWatchedLogins(), isloginlist)
          subscription:watchLogins{ login.id, login.id }
          checks.assert(subscription:getWatchedLogins(), isloginlist)
          local ok, err = pcall(subscription.watchLogins, subscription, {
            FakeLoginId,
            login.id,
          })
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{
            _repid = logintypes.InvalidLogins,
            loginIds = { FakeLoginId },
          })
          checks.assert(subscription:getWatchedLogins(), isloginlist)
          -- logout the created login
          checks.assert(conn:logout(), checks.equal(true))
          -- wait for the notification
          local notified = observer:_wait("entityLogout")
          checks.assert(notified, checks.like(login))
        end,
        ForgetSingleLogin = function (fixture, openbus)
          local subscription, observer = fixture:subscribeLoginObs()
          -- watch a new login that will be logged out later
          local conn = fixture:newConn("system")
          local login = conn.login
          checks.assert(subscription:watchLogin(login.id), checks.equal(true))
          checks.assert(subscription:getWatchedLogins(), checks.like{login})
          subscription:forgetLogin(login.id)
          checks.assert(subscription:getWatchedLogins(), isEmptyList)
          -- logout the created login
          checks.assert(conn:logout(), checks.equal(true))
          -- wait for the notification
          oil.sleep(3)
          local notified = observer:_get("entityLogout")
          checks.assert(notified, checks.is(nil))
        end,
        ForgetMultipleLogins = function (fixture, openbus)
          local subscription, observer = fixture:subscribeLoginObs()
          -- watch a new logins that will be logged out later
          local istrue = checks.equal(true)
          local conns = {}
          local ids = {}
          local loginmap = {}
          for i = 1, 5 do
            local conn = fixture:newConn("system")
            conns[i] = conn
            ids[i] = conn.login.id
            loginmap[conn.login.id] = conn.login.entity
          end
          subscription:watchLogins(ids)
          -- check list of observed logins
          local observed = subscription:getWatchedLogins()
          checks.assert(observed, checks.type("table"))
          local observedmap = {}
          for _, login in ipairs(observed) do
            observedmap[login.id] = login.entity
          end
          checks.assert(observedmap, checks.like(loginmap, nil, {isomorphic=true}))
          -- forget two last connections
          subscription:forgetLogin(ids[3])
          subscription:forgetLogins{ids[4], ids[5]}
          -- logout connections and wait for the notification
          for i, conn in ipairs(conns) do
            local login = conn.login
            checks.assert(conn:logout(), checks.equal(true))
            if i < 3 then
              local notified = observer:_wait("entityLogout")
              checks.assert(notified, checks.like(login))
            else
              oil.sleep(3)
              local notified = observer:_get("entityLogout")
              checks.assert(notified, checks.like(nil))
            end
          end
        end,
        ForgetRepeatedLogins = function (fixture, openbus)
          local subscription, observer = fixture:subscribeLoginObs()
          -- watch a new logins that will be logged out later
          local istrue = checks.equal(true)
          local conns = {}
          local ids = {}
          local loginmap = {}
          for i = 1, 3 do
            local conn = fixture:newConn("system")
            conns[i] = conn
            ids[i] = conn.login.id
            loginmap[conn.login.id] = conn.login.entity
          end
          subscription:watchLogins(ids)
          -- check list of observed logins
          local observed = subscription:getWatchedLogins()
          checks.assert(observed, checks.type("table"))
          local observedmap = {}
          for _, login in ipairs(observed) do
            observedmap[login.id] = login.entity
          end
          checks.assert(observedmap, checks.like(loginmap, nil, {isomorphic=true}))
          -- forget two last connections
          subscription:forgetLogins{ids[3], ids[3], ids[3]}
          -- logout connections and wait for the notification
          for i, conn in ipairs(conns) do
            local login = conn.login
            checks.assert(conn:logout(), checks.equal(true))
            if i ~= 3 then
              local notified = observer:_wait("entityLogout")
              checks.assert(notified, checks.like(login))
            else
              oil.sleep(3)
              local notified = observer:_get("entityLogout")
              checks.assert(notified, checks.like(nil))
            end
          end
        end,
        ObserverRemoved = function (fixture, openbus)
          local subscription, observer = fixture:subscribeLoginObs()
          -- watch a new logins that will be logged out later
          local istrue = checks.equal(true)
          local conns = {}
          local ids = {}
          local loginmap = {}
          for i = 1, 3 do
            local conn = fixture:newConn("system")
            conns[i] = conn
            ids[i] = conn.login.id
            loginmap[conn.login.id] = conn.login.entity
          end
          subscription:watchLogins(ids)
          -- check list of observed logins
          local observed = subscription:getWatchedLogins()
          checks.assert(observed, checks.type("table"))
          local observedmap = {}
          for _, login in ipairs(observed) do
            observedmap[login.id] = login.entity
          end
          checks.assert(observedmap, checks.like(loginmap, nil, {isomorphic=true}))
          -- remove subscription
          subscription:remove()
          -- logout connections and wait for the notification
          for i, conn in ipairs(conns) do
            local login = conn.login
            checks.assert(conn:logout(), checks.equal(true))
            oil.sleep(3)
            local notified = observer:_get("entityLogout")
            checks.assert(notified, checks.like(nil))
          end
        end,
      },
    },
    AsAdmin = LoginsFixture{
      identity = "admin",
      tests = makeSimpleTests{
        logins = {
          getEntityLogins = {
            Invalid = {
              params = { "fake" },
              result = { isEmptyList },
            },
          },
        },
        GetAllLogins = function (fixture)
          local mine = fixture:getMyLogins()
          checks.assert(next(mine), checks.NOT(checks.equal(nil)))
          local all = fixture.logins:getAllLogins()
          for _, login in ipairs(all) do
            checks.assert(login.id, checks.type("string"))
            checks.assert(login.entity, checks.type("string"))
            local expected = mine[login.id]
            if expected ~= nil then
              checks.assert(login, checks.like(expected))
              mine[login.id] = nil
            end
          end
          checks.assert(next(mine), checks.equal(nil, "got unreported login"))
        end,
        GetAllLoginsByEntity = function (fixture)
          local map = table.memoize(function () return {} end)
          for id, login in pairs(fixture:getMyLogins()) do
            map[login.entity][id] = login
          end
          checks.assert(next(map), checks.NOT(checks.equal(nil)))
          for entity, set in pairs(map) do
            local list = fixture.logins:getEntityLogins(entity)
            for _, login in ipairs(list) do
              local expected = set[login.id]
              if expected ~= nil then
                checks.assert(login, checks.like(expected))
                set[login.id] = nil
              end
            end
            checks.assert(next(set), checks.equal(nil, "got unreported login"))
          end
        end,
        InvalidateLogin = function (fixture)
          local conn = fixture:newConn("user")
          local login = conn.login.id
          local logins = fixture.logins
          checks.assert(logins:invalidateLogin(login), checks.equal(true))
          checks.assert(logins:getLoginValidity(login), checks.equal(0))
          local ok, err = pcall(logins.getLoginInfo, logins, login)
          checks.assert(ok, checks.equal(false))
          checks.assert(err, checks.like{
            _repid = logintypes.InvalidLogins,
            loginIds = { login },
          })
        end,
      },
    },
  },
}
