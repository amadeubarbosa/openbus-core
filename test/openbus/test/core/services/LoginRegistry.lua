local _G = require "_G"
local pcall = _G.pcall
local pcall = _G.pcall
local string = _G.string

local oil = require "oil"
local oillog = require "oil.verbose"
local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local openbus = require "openbus.multiplexed"
local log = require "openbus.util.logger"
local server = require "openbus.util.server"
local setuplog = server.setuplog
local Check = require "latt.Check"

local idl = require "openbus.core.idl"
local logintypes = idl.types.services.access_control

local cothread = require "cothread"
cothread.verbose:level(1)
cothread.verbose:flag("state",true)

-- Configurações --------------------------------------------------------------
local host = "localhost"
local port = 2089
local admin = "admin"
local adminPassword = "admin"
local dUser = "tester"
local dPassword = "tester"
local certificate = "teste.crt"  
local pkey = "teste.key"
local loglevel = 5
local oillevel = 0 

local scsutils = require ("scs.core.utils")()
local props = {}
scsutils:readProperties(props, "test.properties")
scsutils = nil

host = props:getTagOrDefault("host", host)
port = props:getTagOrDefault("port", port)
admin = props:getTagOrDefault("admin", admin)
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

-- Cria o método entityLogout do LoginObserver
local function createEntityLogout(id, entity)
  return function (info)
    Check.assertNotNil(info.id)
    Check.assertNotNil(info.entity)
    Check.assertEquals(id, info.id)
    Check.assertEquals(entity, info.entity)
  end
end

-- Inicialização --------------------------------------------------------------
setuplog(log, loglevel)
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
  print("NoPermissionCase.beforeTestCase")
  local conn = openbus.connectByAddress(host, port)
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
  Check.assertEquals(sysex.NO_PERMISSION, err._repid)
end

function NoPermissionCase.testGetEntityLogins(self)
  local logins = self.conn.logins
  local ok, err = pcall(logins.getEntityLogins, logins, "entity")
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, err._repid)
end

function NoPermissionCase.testInvalidateLogin(self)
  local logins = self.conn.logins
  local ok, err = pcall(logins.invalidateLogin, logins, "login-id")
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, err._repid)
end

-------------------------------------
-- Caso de teste "INVALID PARAMETERS"
-------------------------------------

function InvalidParamCase.beforeTestCase(self)
  print("InvalidParamCase.beforeTestCase")
  local orb = openbus.createORB()
  local conn = openbus.connectByAddress(host, port, orb)
  conn:loginByPassword(admin, adminPassword)
  self.conn = conn
  self.logins = conn.logins
  self.invalidId = "invalid-login-id"
  self.orb = orb
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

function InvalidParamCase.atestSubscribeObserver(self)
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
  require("cothread").verbose:level(1)
  ok, err = pcall(self.conn.logout, self.conn)
  Check.assertTrue(ok)
  self.conn:loginByPassword(admin, adminPassword)
  self.logins = conn.logins
end

-------------------------------------
-- Caso de teste "PADRÃO"
-------------------------------------

function LRCase.beforeTestCase(self)
  print("LRCase.beforeTestCase")
  local conn = openbus.connectByAddress(host, port)
  conn:loginByPassword(dUser, dPassword)
  self.conn = conn
  self.logins = conn.logins
end

function LRCase.afterTestCase(self)
  self.conn:logout()
  self.conn = nil
  self.logins = nil
end

function LRCase.testGetAllLogins(self)
  
end

function LRCase.testGetEntityLogins(self)
  
end

function LRCase.testInvalidateLogin(self)
  
end

function LRCase.testGetLoginInfo(self)
  
end

function LRCase.testGetValidity(self)
  
end

function LRCase.testSubscribeObserver(self)
  local conn2 = openbus.connectByAddress(host, port, self.orb)
  local login, lease = conn2:loginByPassword(dUser, dPassword)
  local f = createEntityLogout(conn2.login.id, dUser)
  local loginObs = { entityLogout = f }

  oil.newthread(function ()
    self.conn.orb:run()
  end)
  
  local logins = self.logins
  local ok, observer = pcall(logins.subscribeObserver, logins, loginObs)
  Check.assertTrue(ok)
  Check.assertNotNil(observer)
  local ok, err = pcall(observer.watchLogin, observer, conn2.login.id)
  Check.assertTrue(ok)
  Check.assertTrue(err)

  ok, err = pcall(conn2.logout, conn2)
  Check.assertTrue(ok)
  oil.sleep(lease)
end

