local _G = require "_G"
local pcall = _G.pcall
local pcall = _G.pcall
local string = _G.string
local ipairs = _G.ipairs

local oil = require "oil"
local oillog = require "oil.verbose"

local openbus = require "openbus.multiplexed"
local log = require "openbus.util.logger"
local server = require "openbus.util.server"
local setuplog = server.setuplog
local Check = require "latt.Check"

local idl = require "openbus.core.idl"
local srvtypes = idl.types.services
local logintypes = srvtypes.access_control

-- Configurações --------------------------------------------------------------
local host = "localhost"
local port = 2089
local admin = "admin"
local adminPassword = "admin"
local dUser = "tester"
local dPassword = "tester"
local certificate = "teste.crt"
local pkey = "teste.key"
local sdklevel = 5
local oillevel = 0

local scsutils = require ("scs.core.utils")()
local props = {}
scsutils:readProperties(props, "test.properties")
scsutils = nil

host = props:getTagOrDefault("host", host)
port = props:getTagOrDefault("port", port)
admin = props:getTagOrDefault("adminLogin", admin)
adminPassword = props:getTagOrDefault("adminPassword", adminPassword)
dUser = props:getTagOrDefault("login", dUser)
dPassword = props:getTagOrDefault("password", dPassword)
certificate = props:getTagOrDefault("certificate", certificate)
pkey = props:getTagOrDefault("privatekey", pkey)
sdklevel = props:getTagOrDefault("sdkLogLevel", sdklevel)
oillevel = props:getTagOrDefault("oilLogLevel", oillevel)

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

local function findLoginInList(list, id)
  for k, info in ipairs(list) do
    if info.id == id then
      return info
    end
  end
  return nil
end

-- Inicialização --------------------------------------------------------------
setuplog(log, sdklevel)
setuplog(oillog, oillevel)

-- Testes do LoginRegistry ----------------------------------------------------

-- -- IDL operations
-- function LoginRegistry:getAllLogins()
-- function LoginRegistry:getEntityLogins(entity)
-- function LoginRegistry:invalidateLogin(id)
-- function LoginRegistry:getLoginInfo(id)
-- function LoginRegistry:getValidity(ids)
-- function LoginRegistry:subscribeObserver(callback)

-------------------------------------
-- Caso de teste "NO PERMISSION"
-------------------------------------

function NoPermissionCase.beforeTestCase(self)
  local conn = openbus.connect(host, port)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
end

function NoPermissionCase.afterTestCase(self)
  self.conn:logout()
  self.conn = nil
end

function NoPermissionCase.testGetAllLogins(self)
  local logins = self.conn.logins
  local ok, err = pcall(logins.getAllLogins, logins)
  Check.assertTrue(not ok)
  Check.assertEquals(srvtypes.UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testGetEntityLogins(self)
  local logins = self.conn.logins
  local ok, err = pcall(logins.getEntityLogins, logins, "entity")
  Check.assertTrue(not ok)
  Check.assertEquals(srvtypes.UnauthorizedOperation, err._repid)
end

function NoPermissionCase.testInvalidateLogin(self)
  local logins = self.conn.logins
  local ok, err = pcall(logins.invalidateLogin, logins, "login-id")
  Check.assertTrue(not ok)
  Check.assertEquals(srvtypes.UnauthorizedOperation, err._repid)
end

-------------------------------------
-- Caso de teste "INVALID PARAMETERS"
-------------------------------------

function InvalidParamCase.beforeTestCase(self)
  local orb = openbus.initORB()
  local conn = openbus.connect(host, port, orb)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.logins = conn.logins
  self.invalidId = "invalid-login-id"
end

function InvalidParamCase.afterTestCase(self)
  self.conn:logout()
  self.conn = nil
  self.logins = nil
end

function InvalidParamCase.testGetEntityLogins(self)
  local logins = self.conn.logins
  local ok, infos = pcall(logins.getEntityLogins, logins, self.invalidId)
  Check.assertTrue(ok)
  Check.assertEquals(0, #infos)
end

function InvalidParamCase.testInvalidateLogin(self)
  local logins = self.logins
  local ok, ret = pcall(logins.invalidateLogin, logins, self.invalidId)
  Check.assertTrue(ok)
  Check.assertFalse(ret)
end

function InvalidParamCase.testGetLoginInfo(self)
  local logins = self.logins
  local ok, err = pcall(logins.getLoginInfo, logins, self.invalidId)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.InvalidLogins, err._repid)
  Check.assertEquals(1, #err.loginIds)
  Check.assertEquals(self.invalidId, err.loginIds[1])
end

function InvalidParamCase.testGetValidity(self)
  local logins = self.logins
  local list = { self.invalidId }
  local ok, vals = pcall(logins.getValidity, logins, list)
  Check.assertTrue(ok)
  Check.assertEquals(1, #vals)
  Check.assertEquals(0, vals[1])
end

function InvalidParamCase.testGetValidityEmptyList(self)
  local logins = self.logins
  local list = {}
  local ok, vals = pcall(logins.getValidity, logins, list)
  Check.assertTrue(ok)
  Check.assertEquals(0, #vals)
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
  self.logins = self.conn.logins
end

function InvalidParamCase.test2ConnectionSubscribeInvalidObserver(self)
  local conn2 = openbus.connect(host, port)
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
  orb:shutdown()
  -- CORBA Error should happen in the BUS side and can`t be checked here.
  -- The CORBA error is NO_IMPLEMENT
end

-------------------------------------
-- Caso de teste "PADRÃO"
-------------------------------------

function LRCase.beforeTestCase(self)
  local conn = openbus.connect(host, port)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.logins = conn.logins
end

function LRCase.afterTestCase(self)
  self.conn:logout()
  self.conn = nil
  self.logins = nil
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
  local conn2 = openbus.connect(host, port)
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
  conn2:logout()
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
  local conn2 = openbus.connect(host, port)
  conn2:loginByPassword(dUser, dPassword)
  -- check login
  local info = logins:getLoginInfo(conn2.login.id)
  Check.assertNotNil(info)
  Check.assertEquals(conn2.login.id, info.id)
  Check.assertEquals(dUser, info.entity)
  local list = { conn2.login.id }
  local vals = logins:getValidity(list)
  Check.assertNotNil(vals)
  Check.assertEquals(1, #vals)
  local validity = vals[1]  
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
  local ok, err = pcall(conn2.logout, conn2)
  Check.assertTrue(ok)
  Check.assertFalse(err)
end

function LRCase.testGetLoginInfo(self)
  local logins = self.logins
  local conn2 = openbus.connect(host, port)
  conn2:loginByPassword(dUser, dPassword)
  local info = logins:getLoginInfo(conn2.login.id)
  Check.assertNotNil(info)
  Check.assertEquals(conn2.login.id, info.id)
  Check.assertEquals(dUser, info.entity)
  info = conn2.logins:getLoginInfo(self.conn.login.id)
  Check.assertNotNil(info)
  Check.assertEquals(self.conn.login.id, info.id)
  Check.assertEquals(admin, info.entity)
  conn2:logout()
end

function LRCase.testGetValidity(self)
  local logins = self.logins
  local list = { self.conn.login.id }
  local vals = logins:getValidity(list)
  Check.assertNotNil(vals)
  Check.assertEquals(1, #vals)
  local t1 = vals[1]
  oil.sleep(1)
  vals = logins:getValidity(list)
  Check.assertNotNil(vals)
  Check.assertEquals(1, #vals)
  local t2 = vals[1]
  Check.assertTrue(t1 > t2)
end

function LRCase.test2ConncetionsGetValidity(self)
  local logins = self.logins
  local conn2 = openbus.connect(host, port)
  conn2:loginByPassword(dUser, dPassword)
  local list = { self.conn.login.id, conn2.login.id }
  local vals = logins:getValidity(list)
  Check.assertNotNil(vals)
  Check.assertEquals(2, #vals)
  local conn1t1 = vals[1]
  local conn2t1 = vals[2]
  oil.sleep(1)
  vals = logins:getValidity(list)
  Check.assertNotNil(vals)
  Check.assertEquals(2, #vals)
  conn2:logout()
  local conn1t2 = vals[1]
  local conn2t2 = vals[2]
  Check.assertTrue(conn1t1 > conn1t2)
  Check.assertTrue(conn2t1 > conn2t2)
end

function LRCase.testSubscribeObserver(self)
  local conn2 = openbus.connect(host, port)
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
  orb:shutdown()
  -- check if observer was called properly
  Check.assertNotNil(logoutInfo)
  Check.assertEquals(loginId, logoutInfo.id)
  Check.assertEquals(dUser, logoutInfo.entity)
end

