local _G = require "_G"
local pcall = _G.pcall
local print = _G.print
local pairs = _G.pairs
local ipairs = _G.ipairs
local type = _G.type
local pcall = _G.pcall
local string = _G.string
local table = _G.table
local assert = _G.assert
local os = _G.os

local oil = require "oil"
local oillog = require "oil.verbose"
local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local x509 = require "lce.x509"
local decodecertificate = x509.decode

local Access = require "openbus.core.Access"
local log = require "openbus.util.logger"
local server = require "openbus.util.server"
local setuplog = server.setuplog
local readprivatekey = server.readprivatekey
local Check = require "latt.Check"

local idl = require "openbus.core.idl"
local loginconst = idl.const.services.access_control
local logintypes = idl.types.services.access_control
local BusObjectKey = idl.const.BusObjectKey

-- Configurações --------------------------------------------------------------
local host = "localhost"
local port = 2089
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
dUser = props:getTagOrDefault("login", dUser)
dPassword = props:getTagOrDefault("password", dPassword)
certificate = props:getTagOrDefault("certificate", certificate)
pkey = props:getTagOrDefault("privatekey", pkey)
sdklevel = props:getTagOrDefault("sdkLogLevel", sdklevel)
oillevel = props:getTagOrDefault("oilLogLevel", oillevel)

-- Casos de Teste -------------------------------------------------------------
Suite = {}
Suite.Test1 = {}

-- Aliases
local ACSuite = Suite.Test1

-- Funções auxiliares ---------------------------------------------------------
local function connectByAddress(host, port)
  local LoginServiceNames = {
    AccessControl = "AccessControl",
    certificates = "CertificateRegistry",
    logins = "LoginRegistry",
  }
  local conn = {}
  local orb = Access.createORB()
  local access = Access{ orb = orb }
  --orb.OpenBusInterceptor = access
  orb:setinterceptor(access, "corba")
  conn.orb = orb
  
  local ref = "corbaloc::"..host..":"..port.."/"..BusObjectKey
  local bus = orb:newproxy(ref, nil, "scs::core::IComponent")
  for field, name in pairs(LoginServiceNames) do
    local facetname = assert(loginconst[name.."Facet"], name)
    local typerepid = assert(logintypes[name], name)
    conn[field] = orb:narrow(bus:getFacetByName(facetname), typerepid)
  end
  conn.bus = bus
  access.busid = conn.AccessControl:_get_busid()

  function conn:setLogin(login)
    access.login = login
  end
  return conn
end

local function loginByPassword(user, password)
  if not user then
    user = dUser
  end
  if not password then
    password = dPassword
  end
  local conn = connectByAddress(host,port)
  local accontrol = conn.AccessControl
  local result, errmsg = decodecertificate(accontrol:_get_certificate())
  Check.assertNotNil(result, errmsg)
  local buskey, errmsg =  result:getpubkey()
  Check.assertNotNil(buskey, errmsg)
  local encoded, errmsg = buskey:encrypt(password)
  Check.assertNotNil(encoded, errmsg)
  local login, lease = accontrol:loginByPassword(user, encoded)
  Check.assertNotNil(login)
  Check.assertNotNil(lease)
  conn:setLogin(login)
  return conn, login
end

-- Inicialização --------------------------------------------------------------
setuplog(log, sdklevel)
setuplog(oillog, oillevel)

-- Testes do AccessControl ----------------------------------------------------

-- -- IDL operations
-- function AccessControl:loginByPassword(entity, password)
-- function AccessControl:startLoginByCertificate(entity)
-- function AccessControl:logout()
-- function AccessControl:renew()

function ACSuite.testLoginByPasswordAndLogout(self)
  local conn, login = loginByPassword()
  local accontrol = conn.AccessControl
  accontrol:logout()
  conn:setLogin(nil)
end

function ACSuite.testInvalidPassword(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local result, errmsg = decodecertificate(accontrol:_get_certificate())
  Check.assertNotNil(result, errmsg)
  local buskey, errmsg =  result:getpubkey()
  Check.assertNotNil(buskey, errmsg)
  local encoded, errmsg = buskey:encrypt("wrong password")
  Check.assertNotNil(encoded, errmsg)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, encoded)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.AccessDenied, errmsg._repid)
end

function ACSuite.testEmptyLogin(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, "", {})
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.WrongEncoding, errmsg._repid)
end

function ACSuite.testNilLogin(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local result, errmsg = decodecertificate(accontrol:_get_certificate())
  Check.assertNotNil(result, errmsg)
  local buskey, errmsg =  result:getpubkey()
  Check.assertNotNil(buskey, errmsg)
  local encoded, errmsg = buskey:encrypt("")
  Check.assertNotNil(encoded, errmsg)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, nil, encoded)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, errmsg._repid)
end

function ACSuite.testEmptyPassword(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, {})
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.WrongEncoding, errmsg._repid)
end

function ACSuite.testNilPassword(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, nil)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, errmsg._repid)
end

function ACSuite.testEmptyLoginAndPassword(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, "", "")
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.WrongEncoding, errmsg._repid)
end

function ACSuite.testPasswordInvalidEncriptation(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, dPassword)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.WrongEncoding, errmsg._repid)
end

function ACSuite.testLogoutLoginByPassword(self)
  local conn, login = loginByPassword()
  local accontrol = conn.AccessControl
  accontrol:logout()
  -- calling after logout
  local ok, errmsg = pcall(accontrol.renew, accontrol)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, errmsg._repid)
end

function ACSuite.testLoginByCertificateAndLogout(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  Check.assertNotNil(attempt)
  Check.assertNotNil(challenge)
  local privatekey, errmsg = readprivatekey(pkey)
  Check.assertNotNil(privatekey, errmsg)
  local secret, errmsg = privatekey:decrypt(challenge)
  Check.assertNotNil(secret, errmsg)
  local result, errmsg = decodecertificate(accontrol:_get_certificate())
  Check.assertNotNil(result, errmsg)
  local buskey, errmsg =  result:getpubkey()
  Check.assertNotNil(buskey, errmsg)
  local answer, errmsg = buskey:encrypt(secret)
  Check.assertNotNil(answer, errmsg)
  local login, lease = attempt:login(answer)
  Check.assertNotNil(login)
  Check.assertNotNil(lease)
  conn:setLogin(login)
  accontrol:logout()
  conn:setLogin(nil)
end

function ACSuite.testCancelLoginByCertificate(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  Check.assertNotNil(attempt)
  Check.assertNotNil(challenge)
  local ok, errmsg = pcall(attempt.cancel, attempt)
  Check.assertTrue(ok, errmsg)
end

function ACSuite.testLogoutLoginByCertificate(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  Check.assertNotNil(attempt)
  Check.assertNotNil(challenge)
  local privatekey, errmsg = readprivatekey(pkey)
  Check.assertNotNil(privatekey, errmsg)
  local secret, errmsg = privatekey:decrypt(challenge)
  Check.assertNotNil(secret, errmsg)
  local result, errmsg = decodecertificate(accontrol:_get_certificate())
  Check.assertNotNil(result, errmsg)
  local buskey, errmsg =  result:getpubkey()
  Check.assertNotNil(buskey, errmsg)
  local answer, errmsg = buskey:encrypt(secret)
  Check.assertNotNil(answer, errmsg)
  local login, lease = attempt:login(answer)
  Check.assertNotNil(login)
  Check.assertNotNil(lease)
  conn:setLogin(login)
  accontrol:logout()
  -- calling after logout
  local ok, errmsg = pcall(accontrol.renew, accontrol)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, errmsg._repid)
end

function ACSuite.testLoginByCertificateWrongAnswer(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  Check.assertNotNil(attempt)
  Check.assertNotNil(challenge)
  local wrongsecret = "wrong secret"
  local result, errmsg = decodecertificate(accontrol:_get_certificate())
  Check.assertNotNil(result, errmsg)
  local buskey, errmsg =  result:getpubkey()
  Check.assertNotNil(buskey, errmsg)
  local answer, errmsg = buskey:encrypt(wrongsecret)
  Check.assertNotNil(answer, errmsg)
  local ok, errmsg = pcall(attempt.login, attempt, answer)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.AccessDenied, errmsg._repid)
end

function ACSuite.testLoginByCertificateNoEncoding(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  Check.assertNotNil(attempt)
  Check.assertNotNil(challenge)
  local privatekey, errmsg = readprivatekey(pkey)
  Check.assertNotNil(privatekey, errmsg)
  local secret, errmsg = privatekey:decrypt(challenge)
  Check.assertNotNil(secret, errmsg)
  local result, errmsg = decodecertificate(accontrol:_get_certificate())
  Check.assertNotNil(result, errmsg)
  local buskey, errmsg =  result:getpubkey()
  Check.assertNotNil(buskey, errmsg)
  local ok, errmsg = pcall(attempt.login, attempt, secret)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.WrongEncoding, errmsg._repid)
end

function ACSuite.testLoginByCertificateWrongEncoding(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  Check.assertNotNil(attempt)
  Check.assertNotNil(challenge)
  local ok, errmsg = pcall(attempt.login, attempt, challenge)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.WrongEncoding, errmsg._repid)
end

function ACSuite.testRenew(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local result, errmsg = decodecertificate(accontrol:_get_certificate())
  Check.assertNotNil(result, errmsg)
  local buskey, errmsg =  result:getpubkey()
  Check.assertNotNil(buskey, errmsg)
  local encoded, errmsg = buskey:encrypt(dPassword)
  Check.assertNotNil(encoded, errmsg)
  local login, lease = accontrol:loginByPassword(dUser, encoded)
  Check.assertNotNil(login)
  Check.assertNotNil(lease)
  conn:setLogin(login)
  oil.sleep(3*lease/4)
  lease = accontrol:renew()
  Check.assertNotNil(lease)
  oil.sleep(3*lease/4)
  local ok, errmsg = pcall(accontrol.logout, accontrol)
  Check.assertTrue(ok, errmsg)
  conn:setLogin(nil)
end

function ACSuite.testExpiredLogin(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local result, errmsg = decodecertificate(accontrol:_get_certificate())
  Check.assertNotNil(result, errmsg)
  local buskey, errmsg =  result:getpubkey()
  Check.assertNotNil(buskey, errmsg)
  local encoded, errmsg = buskey:encrypt(dPassword)
  Check.assertNotNil(encoded, errmsg)
  local login, lease = accontrol:loginByPassword(dUser, encoded)
  Check.assertNotNil(login)
  Check.assertNotNil(lease)
  conn:setLogin(login)
  oil.sleep(3*lease)
  local ok, errmsg = pcall(accontrol.logout, accontrol)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, errmsg._repid)
  conn:setLogin(nil)
end
