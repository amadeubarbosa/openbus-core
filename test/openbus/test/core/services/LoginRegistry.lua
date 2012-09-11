local _G = require "_G"
local pcall = _G.pcall
local ipairs = _G.ipairs

local oil = require "oil"

local openbus = require "openbus"
local idl = require "openbus.core.idl"
local srvtypes = idl.types.services
local logintypes = srvtypes.access_control

local Check = require "latt.Check"

-- Configurações --------------------------------------------------------------
bushost, busport = ...
require "openbus.test.configs"
local host = bushost
local port = busport
local admin = admin
local adminPassword = admpsw
local dUser = user
local dPassword = password

-- Inicialização --------------------------------------------------------------
local orb = openbus.initORB()
local OpenBusContext = orb.OpenBusContext
local connprops = { accesskey = openbus.newKey() }

-- Casos de Teste -------------------------------------------------------------
Suite = {}
Suite.Test1 = {}
Suite.Test2 = {}
Suite.Test3 = {}

-- Aliases
local NoPermissionCase = Suite.Test1 or {}
local InvalidParamCase = Suite.Test2 or {}
local LRCase = Suite.Test3

-- Funções auxiliares ---------------------------------------------------------
local function assertCondOrTimeout(condition,timeout)
  if timeout == nil then timeout = 2 end
  local deadline = oil.time()+timeout
  while not condition() do
    if oil.time() > deadline then
      error("Assert failed after "..tostring(timeout).." seconds.",2)
    end
    oil.sleep(.1)
  end
end

local function findLoginInList(list, id)
  for k, info in ipairs(list) do
    if info.id == id then
      return info
    end
  end
  return nil
end

-- Testes do LoginRegistry ----------------------------------------------------

-- -- IDL operations
-- function LoginRegistry:getAllLogins()
-- function LoginRegistry:getEntityLogins(entity)
-- function LoginRegistry:invalidateLogin(id)
-- function LoginRegistry:getLoginInfo(id)
-- function LoginRegistry:getLoginValidity(id)
-- function LoginRegistry:subscribeObserver(callback)

-------------------------------------
-- Caso de teste "NO PERMISSION"
-------------------------------------

function NoPermissionCase.beforeTestCase(self)
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
end

function NoPermissionCase.afterTestCase(self)
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
  self.conn = nil
end

function NoPermissionCase.testGetAllLogins(self)
  local logins = OpenBusContext:getLoginRegistry()
  local ok, err = pcall(logins.getAllLogins, logins)
  Check.assertTrue(not ok)
  Check.assertEquals(srvtypes.UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testGetEntityLogins(self)
  local logins = OpenBusContext:getLoginRegistry()
  local ok, err = pcall(logins.getEntityLogins, logins, "entity")
  Check.assertTrue(not ok)
  Check.assertEquals(srvtypes.UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testInvalidateLogin(self)
  local logins = OpenBusContext:getLoginRegistry()
  local ok, err = pcall(logins.invalidateLogin, logins, "login-id")
  Check.assertTrue(not ok)
  Check.assertEquals(srvtypes.UnauthorizedOperation, err._repid)
end

-------------------------------------
-- Caso de teste "INVALID PARAMETERS"
-------------------------------------

function InvalidParamCase.beforeTestCase(self)
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.logins = OpenBusContext:getLoginRegistry()
  self.invalidId = "invalid-login-id"
end

function InvalidParamCase.afterTestCase(self)
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
  self.conn = nil
  self.logins = nil
end

function InvalidParamCase.afterEachTest(self)
  if self.conn2 ~= nil then
    self.conn2:logout()
    self.conn2 = nil
  end
end

function InvalidParamCase.testGetEntityLogins(self)
  local logins = OpenBusContext:getLoginRegistry()
  local infos = logins:getEntityLogins(self.invalidId)
  Check.assertEquals(0, #infos)
end

function InvalidParamCase.testInvalidateLogin(self)
  local logins = OpenBusContext:getLoginRegistry()
  local ok, ret = pcall(logins.invalidateLogin, logins, self.invalidId)
  Check.assertTrue(ok)
  Check.assertFalse(ret)
end

function InvalidParamCase.testGetLoginInfo(self)
  local logins = OpenBusContext:getLoginRegistry()
  local ok, err = pcall(logins.getLoginInfo, logins, self.invalidId)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.InvalidLogins, err._repid)
  Check.assertEquals(1, #err.loginIds)
  Check.assertEquals(self.invalidId, err.loginIds[1])
end

function InvalidParamCase.testGetValidity(self)
  local logins = self.logins
  local ok, validity = pcall(logins.getLoginValidity, logins, self.invalidId)
  Check.assertTrue(ok)
  Check.assertEquals(0, validity)
end

function InvalidParamCase.testSubscribeInvalidObserver(self)
  local logins = self.logins
  local ok, observer = pcall(logins.subscribeObserver, logins, {})
  Check.assertTrue(ok)
  Check.assertNotNil(observer)
  local ok, err = pcall(observer.watchLogin, observer, self.conn.login.id)
  Check.assertTrue(ok)
  Check.assertTrue(err)
  ok, err = pcall(observer.watchLogin, observer, self.invalidId)
  Check.assertTrue(ok)
  Check.assertFalse(err)
  -- start ORB to receive observer notification
  local orb = self.conn.orb
  oil.newthread(orb.run, orb)
  ok, err = pcall(self.conn.logout, self.conn)
  Check.assertTrue(ok)
  orb:shutdown()
  -- CORBA Error should happen in the BUS side and can`t be checked here.
  -- The CORBA error is NO_PERMISSION
  -- loggin in again so 'afterTestCase' can logout
  self.conn:loginByPassword(admin, adminPassword)
  self.logins = OpenBusContext:getLoginRegistry()
end

function InvalidParamCase.test2ConnectionSubscribeInvalidObserver(self)
  local conn2 = OpenBusContext:createConnection(host, port, connprops)
  self.conn2 = conn2
  conn2:loginByPassword(dUser, dPassword)
  -- subscribe observer
  local logins = self.logins
  local ok, observer = pcall(logins.subscribeObserver, logins, {})
  Check.assertTrue(ok)
  Check.assertNotNil(observer)
  local ok, err = pcall(observer.watchLogin, observer, conn2.login.id)
  Check.assertTrue(ok)
  Check.assertTrue(err)
  -- start ORB to receive observer notification
  local orb = self.conn.orb
  oil.newthread(orb.run, orb)
  conn2:logout()
  self.conn2 = nil
  orb:shutdown()
  -- CORBA Error should happen in the BUS side and can`t be checked here.
  -- The CORBA error is NO_IMPLEMENT
end

-------------------------------------
-- Caso de teste "PADRÃO"
-------------------------------------

function LRCase.beforeTestCase(self)
  local conn = OpenBusContext:createConnection(host, port, connprops)
  OpenBusContext:setDefaultConnection(conn)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.logins = OpenBusContext:getLoginRegistry()
end

function LRCase.afterTestCase(self)
  self.conn:logout()
  OpenBusContext:setDefaultConnection(nil)
  self.conn = nil
  self.logins = nil
end

function LRCase.afterEachTest(self)
  if self.conn2 ~= nil then
    self.conn2:logout()
    self.conn2 = nil
  end
end

function LRCase.testGetAllLogins(self)
  local logins = self.logins
  local list = logins:getAllLogins()
  Check.assertTrue(#list > 0)
  local found = findLoginInList(list, self.conn.login.id)
  Check.assertNotNil(found)
  Check.assertEquals(self.conn.login.id, found.id)
  Check.assertEquals(admin, found.entity)
end

function LRCase.test2ConnectionGetAllLogins(self)
  local logins = self.logins
  local conn2 = OpenBusContext:createConnection(host, port, connprops)
  self.conn2 = conn2
  conn2:loginByPassword(dUser, dPassword)
  local ok, list = pcall(logins.getAllLogins, logins)
  Check.assertTrue(ok)
  Check.assertTrue(#list > 1)
  local found = findLoginInList(list, self.conn.login.id)
  Check.assertNotNil(found)
  Check.assertEquals(self.conn.login.id, found.id)
  Check.assertEquals(admin, found.entity)
  found = findLoginInList(list, conn2.login.id)
  Check.assertNotNil(found)
  Check.assertEquals(conn2.login.id, found.id)
  Check.assertEquals(dUser, found.entity)
end

function LRCase.testGetEntityLogins(self)
  local logins = self.logins
  local list = logins:getEntityLogins(admin)
  Check.assertTrue(#list > 0)
  local found = findLoginInList(list, self.conn.login.id)
  Check.assertNotNil(found)
  Check.assertEquals(self.conn.login.id, found.id)
  Check.assertEquals(admin, found.entity)  
end

function LRCase.testInvalidateLogin(self)
  local logins = self.logins
  local conn2 = OpenBusContext:createConnection(host, port, connprops)
  self.conn2 = conn2
  conn2:loginByPassword(dUser, dPassword)
  -- check login
  local info = logins:getLoginInfo(conn2.login.id)
  Check.assertNotNil(info)
  Check.assertEquals(conn2.login.id, info.id)
  Check.assertEquals(dUser, info.entity)
  local validity = logins:getLoginValidity(conn2.login.id)
  -- invalidating
  local bool = logins:invalidateLogin(conn2.login.id)
  Check.assertTrue(bool)
  local conn2id = conn2.login.id
  -- sleeping validity time so the login may be removed from cache. If not, the
  -- call to getLoginInfo will return the info from cache (won`t call the bus)
  oil.sleep(validity)
  local ok, err = pcall(logins.getLoginInfo, logins, conn2id)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.InvalidLogins, err._repid)
  Check.assertEquals(1, #err.loginIds)
  Check.assertEquals(conn2id, err.loginIds[1])
  -- test logout of conn2
  Check.assertFalse(conn2:logout())
  self.conn2 = nil
end

function LRCase.testGetLoginInfo(self)
  local logins = self.logins
  local conn2 = OpenBusContext:createConnection(host, port, connprops)
  self.conn2 = conn2
  conn2:loginByPassword(dUser, dPassword)
  local info = logins:getLoginInfo(conn2.login.id)
  Check.assertNotNil(info)
  Check.assertEquals(conn2.login.id, info.id)
  Check.assertEquals(dUser, info.entity)
  OpenBusContext:setCurrentConnection(conn2)
  local logins2 = OpenBusContext:getLoginRegistry()
  local ok, info = pcall(logins2.getLoginInfo, logins2, self.conn.login.id)
  OpenBusContext:setCurrentConnection(nil)
  Check.assertTrue(ok, info)
  Check.assertNotNil(info)
  Check.assertEquals(self.conn.login.id, info.id)
  Check.assertEquals(admin, info.entity)
end

function LRCase.testGetValidity(self)
  local logins = self.logins
  local validity = logins:getLoginValidity(self.conn.login.id)
  Check.assertTrue(validity > 0)
end

function LRCase.test2ConnectionsGetValidity(self)
  local logins = self.logins
  local conn2 = OpenBusContext:createConnection(host, port, connprops)
  self.conn2 = conn2
  conn2:loginByPassword(dUser, dPassword)
  local validity = logins:getLoginValidity(conn2.login.id)
  Check.assertTrue(validity > 0)
end

function LRCase.testSubscribeObserver(self)
  local conn2 = OpenBusContext:createConnection(host, port, connprops)
  self.conn2 = conn2
  conn2:loginByPassword(dUser, dPassword)
  -- subscribe login observer
  local loginId = conn2.login.id
  local logoutInfo
  local loginObs = {}
  function loginObs:entityLogout(login)
    logoutInfo = login
  end
  local observer = self.logins:subscribeObserver(loginObs)
  Check.assertNotNil(observer)
  Check.assertTrue(observer:watchLogin(loginId))
  -- start ORB to receive observer notification and logout 'conn2'
  local orb = self.conn.orb
  oil.newthread(orb.run, orb)
  conn2:logout()
  self.conn2 = nil
  -- check if observer was called properly (before a timeout)
  assertCondOrTimeout(function() return logoutInfo ~= nil end, 1)
  orb:shutdown()
  Check.assertEquals(loginId, logoutInfo.id)
  Check.assertEquals(dUser, logoutInfo.entity)
end

