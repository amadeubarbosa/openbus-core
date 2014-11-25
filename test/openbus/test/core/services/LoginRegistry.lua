local table = require "loop.table"
local cached = require "loop.cached"
local checks = require "loop.test.checks"
local Fixture = require "loop.test.Fixture"
local Suite = require "loop.test.Suite"

local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local openbus = require "openbus"
local idl = require "openbus.core.idl"
local srvtypes = idl.types.services
local logintypes = srvtypes.access_control


-- Configurações --------------------------------------------------------------

require "openbus.test.core.services.utils"

local FakeLoginId = "Fake Login ID"

-- Funções auxiliares ---------------------------------------------------------

local function isLoginSubscription(observer, login)
  return function (subs)
    checks.assert(subs:watchLogin(FakeLoginId), checks.equal(false))
    checks.assert(subs:_get_owner(), checks.like(login))
    checks.assert(subs:_get_observer(), checks.equal(observer))
    local desc = subs:describe()
    checks.assert(desc.observer, checks.equal(observer))
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
            InvalidLogin = {
              params = { FakeLoginId },
              result = { checks.equal(false)} ,
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
        InvalidObserverWatchingOtherLogin = function (fixture, openbus)
          local logins = fixture.logins
          local observer = {}
          local subscription = logins:subscribeObserver(observer)
          checks.assert(subscription, isLoginSubscription(observer,
            openbus.context:getCurrentConnection().login))
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
          checks.assert(subscription, isLoginSubscription(observer, conn.login))
          checks.assert(subscription:watchLogin(conn.login.id), checks.equal(true))
          conn:logout()
          -- CORBA Error should happen in the BUS side and can`t be checked here.
          -- The CORBA error is always NO_PERMISSION.
        end,
      },
    },
    AsAdmin = LoginsFixture{
      identity = "admin",
      tests = makeSimpleTests{
        logins = {
          getEntityLogins = {
            Invalid = {
              params = { FakeLoginId },
              result = { checks.like({n=0}, nil, {isomorphic=true}) },
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
        ObserverOfOtherLogin = function (fixture, openbus)
          -- create new observer
          local observer = newObserver({ entityLogout = true }, openbus.context)
          -- subscribe a new observer and validate some of its operations
          local subscription = fixture.logins:subscribeObserver(observer)
          checks.assert(subscription, isLoginSubscription(observer,
            openbus.context:getCurrentConnection().login))
          -- watch a new login that will be logged out later
          local conn = fixture:newConn("user")
          local login = conn.login
          checks.assert(subscription:watchLogin(login.id), checks.equal(true))
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
          -- create new observer
          local observer = newObserver({ entityLogout = true }, openbus.context)
          -- subscribe a new observer and validate some of its operations
          local subscription = fixture.logins:subscribeObserver(observer)
          checks.assert(subscription, isLoginSubscription(observer, conn.login))
          -- watch the new login
          local login = conn.login
          checks.assert(subscription:watchLogin(login.id), checks.equal(true))
          -- logout the created login
          checks.assert(conn:logout(), checks.equal(true))
          -- wait for the notification
          local notified = observer:_wait("entityLogout")
          checks.assert(notified, checks.like(login))
        end,
        ObserverOfTerminatedLogin = function (fixture, openbus)
          -- create new observer
          local observer = newObserver({ entityLogout = true }, openbus.context)
          -- subscribe a new observer and validate some of its operations
          local logins = fixture.logins
          local subscription = logins:subscribeObserver(observer)
          checks.assert(subscription, isLoginSubscription(observer,
            openbus.context:getCurrentConnection().login))
          -- watch a new login that will be terminated later
          local conn = fixture:newConn("user")
          local login = conn.login
          checks.assert(subscription:watchLogin(login.id), checks.equal(true))
          -- terminate the created login
          checks.assert(logins:invalidateLogin(login.id), checks.equal(true))
          -- wait for the notification
          local notified = observer:_wait("entityLogout")
          checks.assert(notified, checks.like(login))
        end,
        ObserverOfOwnTermination = function (fixture, openbus)
          -- assume new login that can be terminated later
          local conn = fixture:newConn("user")
          local context = openbus.context
          context:setCurrentConnection(conn)
          -- create new observer
          local observer = newObserver({ entityLogout = true }, openbus.context)
          -- subscribe a new observer and validate some of its operations
          local logins = fixture.logins
          local subscription = logins:subscribeObserver(observer)
          checks.assert(subscription, isLoginSubscription(observer, conn.login))
          -- watch the new login
          local login = conn.login
          checks.assert(subscription:watchLogin(login.id), checks.equal(true))
          -- as admin terminate the created login
          context:setCurrentConnection(nil)
          checks.assert(logins:invalidateLogin(login.id), checks.equal(true))
          -- wait for the notification
          local notified = observer:_wait("entityLogout")
          checks.assert(notified, checks.like(login))
        end,
      },
    },
  },
}
