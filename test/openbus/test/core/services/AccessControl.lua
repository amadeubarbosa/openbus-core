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

local pubkey = require "lce.pubkey"
local decodepubkey = pubkey.decodepublic

local hash = require "lce.hash"
local sha256 = hash.sha256

local openbus = require "openbus"
local access = require "openbus.core.Access"
local initORB = access.initORB
local Interceptor = access.Interceptor
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
  local orb = initORB()
  local iceptor = Interceptor{ orb = orb }
  --orb.OpenBusInterceptor = iceptor
  orb:setinterceptor(iceptor, "corba")
  conn.orb = orb
  conn.access = iceptor
  -- retrieve IDL definitions for login
  conn.LoginAuthenticationInfo =
    assert(orb.types:lookup_id(logintypes.LoginAuthenticationInfo))

  local ref = "corbaloc::"..host..":"..port.."/"..BusObjectKey
  local bus = orb:newproxy(ref, nil, "scs::core::IComponent")
  for field, name in pairs(LoginServiceNames) do
    local facetname = assert(loginconst[name.."Facet"], name)
    local typerepid = assert(logintypes[name], name)
    conn[field] = orb:narrow(bus:getFacetByName(facetname), typerepid)
  end
  conn.bus = bus
  iceptor.busid = conn.AccessControl:_get_busid()
  conn.buskey = assert(decodepubkey(conn.AccessControl:_get_buskey()))

  function conn:setLogin(login)
    iceptor.login = login
  end
  return conn
end

local function loginByPassword(entity, password)
  if not entity then
    entity = dUser
  end
  if not password then
    password = dPassword
  end
  local conn = connectByAddress(host,port)
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  Check.assertNotNil(pubkey)
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data=password,hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  Check.assertNotNil(encoded)
  local encrypted = conn.buskey:encrypt(encoded)
  Check.assertNotNil(encrypted)
  local login, lease = accontrol:loginByPassword(entity, pubkey, encrypted)
  login.pubkey = pubkey
  conn:setLogin(login)
  return conn, login, lease
end

local function startLoginByCertificate()
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  Check.assertNotNil(attempt)
  Check.assertNotNil(challenge)
  local privatekey, errmsg = readprivatekey(pkey)
  Check.assertNotNil(privatekey, errmsg)
  local secret, errmsg = privatekey:decrypt(challenge)
  Check.assertNotNil(secret, errmsg)
  return conn, attempt, secret
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
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data="wrong password",hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  local encrypted = conn.buskey:encrypt(encoded)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol,
    dUser, pubkey, encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.AccessDenied, errmsg._repid)
end

function ACSuite.testEmptyLogin(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data="",hash=sha256("")}, idltype)
  local encoded = encoder:getdata()
  local encrypted = conn.buskey:encrypt(encoded)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, "", pubkey, 
    encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.AccessDenied, errmsg._repid)
end

function ACSuite.testNilLogin(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data="",hash=sha256("")}, idltype)
  local encoded = encoder:getdata()
  local encrypted = conn.buskey:encrypt(encoded)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, nil, pubkey, 
    encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, errmsg._repid)
end

function ACSuite.testEmptyPassword(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data="",hash=sha256("")}, idltype)
  local encoded = encoder:getdata()
  local encrypted = conn.buskey:encrypt(encoded)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, pubkey, encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.AccessDenied, errmsg._repid)
end

function ACSuite.testNilPassword(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, pubkey, nil)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, errmsg._repid)
end

function ACSuite.testEmptyPubKey(self)
  local conn = connectByAddress(host,port)
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data=dPassword,hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  local encrypted = conn.buskey:encrypt(encoded)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, "", encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.AccessDenied, errmsg._repid)
end

function ACSuite.testNilPubKey(self)
  local conn = connectByAddress(host,port)
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data=dPassword,hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  local encrypted = conn.buskey:encrypt(encoded)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, nil, encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, errmsg._repid)
end

function ACSuite.testEmptyLoginAndPassword(self)
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data="",hash=sha256("")}, idltype)
  local encoded = encoder:getdata()
  local encrypted = conn.buskey:encrypt(encoded)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, "", pubkey, encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.AccessDenied, errmsg._repid)
end

function ACSuite.testPasswordInvalidEncriptation(self)
  local conn = connectByAddress(host,port)
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data=dPassword,hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  local publickey = decodepubkey(pubkey)
  local encrypted = publickey:encrypt(encoded)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, pubkey, encrypted)
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
  local conn, attempt, secret = startLoginByCertificate()
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  Check.assertNotNil(pubkey)
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data=secret,hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  Check.assertNotNil(encoded)
  local encrypted, errmsg = conn.buskey:encrypt(encoded)
  Check.assertNotNil(encrypted, errmsg)
  local login, lease = attempt:login(pubkey, encrypted)
  Check.assertNotNil(login)
  Check.assertNotNil(lease)
  login.pubkey = pubkey
  conn:setLogin(login)
  accontrol:logout()
  conn:setLogin(nil)
end

function ACSuite.testCancelLoginByCertificate(self)
  local conn, attempt, secret = startLoginByCertificate()
  local accontrol = conn.AccessControl
  local ok, errmsg = pcall(attempt.cancel, attempt)
  Check.assertTrue(ok, errmsg)
end

function ACSuite.testLogoutLoginByCertificate(self)
  local conn, attempt, secret = startLoginByCertificate()
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data=secret,hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  local encrypted, errmsg = conn.buskey:encrypt(encoded)
  local login, lease = attempt:login(pubkey, encrypted)
  Check.assertNotNil(login)
  Check.assertNotNil(login.id)
  Check.assertNotNil(lease)
  conn:setLogin(login)
  accontrol:logout()
  conn:setLogin(nil)
  -- calling after logout
  local ok, errmsg = pcall(accontrol.renew, accontrol)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, errmsg._repid)
end

function ACSuite.testLoginByCertificateWrongAnswer(self)
  local conn, attempt, secret = startLoginByCertificate()
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data="wrong secret",hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  local encrypted, errmsg = conn.buskey:encrypt(encoded)
  local ok, errmsg = pcall(attempt.login, attempt, pubkey, encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.AccessDenied, errmsg._repid)
end

function ACSuite.testLoginByCertificateNilPubkey(self)
  local conn, attempt, secret = startLoginByCertificate()
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data=secret,hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  local ok, errmsg = pcall(attempt.login, attempt, nil, encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, errmsg._repid)
end

function ACSuite.testLoginByCertificateNoEncoding(self)
  local conn, attempt, secret = startLoginByCertificate()
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data=secret,hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  local ok, errmsg = pcall(attempt.login, attempt, pubkey, encoded)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.MARSHAL, errmsg._repid)
end

function ACSuite.testLoginByCertificateWrongEncoding(self)
  local conn, attempt, secret = startLoginByCertificate()
  local accontrol = conn.AccessControl
  local pubkey = conn.access.prvkey:encode("public")
  local idltype = conn.LoginAuthenticationInfo
  local encoder = conn.orb:newencoder()
  encoder:put({data=secret,hash=sha256(pubkey)}, idltype)
  local encoded = encoder:getdata()
  local publickey = decodepubkey(pubkey)
  local encrypted = publickey:encrypt(encoded)
  local ok, errmsg = pcall(attempt.login, attempt, pubkey, encrypted)
  Check.assertTrue(not ok)
  Check.assertEquals(logintypes.WrongEncoding, errmsg._repid)
end

function ACSuite.testRenew(self)
  local conn, login, lease = loginByPassword()
  Check.assertNotNil(login)
  Check.assertNotNil(lease)
  oil.sleep(3*lease/4)
  local accontrol = conn.AccessControl
  lease = accontrol:renew()
  Check.assertNotNil(lease)
  oil.sleep(3*lease/4)
  local ok, errmsg = pcall(accontrol.logout, accontrol)
  Check.assertTrue(ok, errmsg)
  conn:setLogin(nil)
end

function ACSuite.testExpiredLogin(self)
  local conn, login, lease = loginByPassword()
  Check.assertNotNil(login)
  Check.assertNotNil(lease)
  oil.sleep(3*lease)
  local accontrol = conn.AccessControl
  local ok, errmsg = pcall(accontrol.logout, accontrol)
  Check.assertTrue(not ok)
  Check.assertEquals(sysex.NO_PERMISSION, errmsg._repid)
  conn:setLogin(nil)
end
