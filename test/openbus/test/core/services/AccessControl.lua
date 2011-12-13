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

local lce = require "lce"
local encrypt = lce.cipher.encrypt
local decrypt = lce.cipher.decrypt
local readcertificate = lce.x509.readfromderstring

local Access = require "openbus.core.Access"
local log = require "openbus.util.logger"
local server = require "openbus.util.server"
local setuplog = server.setuplog
local readprivatekey = server.readprivatekey

local idl = require "openbus.core.idl"
local loginconst = idl.const.services.access_control
local logintypes = idl.types.services.access_control
local BusObjectKey = idl.const.BusObjectKey

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

-- Casos de Teste -------------------------------------------------------------
Suite = {}
Suite.Test1 = {}

-- Aliases
local ACSuite = Suite.Test1

-- Variáveis Locais -----------------------------------------------------------
local busadmin = string.format(
    "busadmin --host=%s --port=%s --login=%s --password=%s ", 
    host, port, admin, adminPassword)

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
  local result, errmsg = readcertificate(accontrol:_get_certificate())
  assert(result, errmsg)
  local buskey, errmsg =  result:getpublickey()
  assert(buskey, errmsg)
  local encoded, errmsg = encrypt(buskey, password)
  assert(encoded, errmsg)
  local login, lease = accontrol:loginByPassword(user, encoded)
  assert(login)
  assert(lease)
  conn:setLogin(login)
  return conn, login
end

local function registerCertificate()
  local addCertificate = string.format("--add-certificate=%s --certificate=%s",
      dUser, certificate)
  os.execute(busadmin..addCertificate)
end

local function removeCertificate()
  local delCertificate = string.format("--del-certificate=%s", dUser)
  os.execute(busadmin..delCertificate)
end

-- Inicialização --------------------------------------------------------------
setuplog(log, loglevel)
setuplog(oillog, oillevel)

-- Testes do AccessControl ----------------------------------------------------

-- -- IDL operations
-- function AccessControl:loginByPassword(entity, password)
-- function AccessControl:startLoginByCertificate(entity)
-- function AccessControl:logout()
-- function AccessControl:renew()

function ACSuite.testLoginByPasswordAndLogout()
  local conn, login = loginByPassword()
  local accontrol = conn.AccessControl
  accontrol:logout()
  conn:setLogin(nil)
end

function ACSuite.testInvalidPassword()
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local result, errmsg = readcertificate(accontrol:_get_certificate())
  assert(result, errmsg)
  local buskey, errmsg =  result:getpublickey()
  assert(buskey, errmsg)
  local encoded, errmsg = encrypt(buskey, "wrong password")
  assert(encoded, errmsg)
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, encoded)
  assert(not ok)
  assert(errmsg._repid == logintypes.AccessDenied)
end

function ACSuite.testEmptyPassword()
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, {})
  assert(not ok)
  assert(errmsg._repid == logintypes.WrongEncoding)
end

function ACSuite.testPasswordInvalidEncriptation()
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local ok, errmsg = pcall(accontrol.loginByPassword, accontrol, dUser, dPassword)
  assert(not ok)
  assert(errmsg._repid == logintypes.WrongEncoding)
end

function ACSuite.testLogoutLoginByPassword()
  local conn, login = loginByPassword()
  local accontrol = conn.AccessControl
  accontrol:logout()
  -- calling after logout
  local ok, err = pcall(accontrol.renew, accontrol)
  assert(not ok)
  assert(err._repid == sysex.NO_PERMISSION)
end

function ACSuite.testLoginByCertificateAndLogout()
  registerCertificate()
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  assert(attempt)
  assert(challenge)
  local privatekey, errmsg = readprivatekey(pkey)
  assert(privatekey, errmsg)
  local secret, errmsg = decrypt(privatekey, challenge)
  assert(secret, errmsg)
  local result, errmsg = readcertificate(accontrol:_get_certificate())
  assert(result, errmsg)
  local buskey, errmsg =  result:getpublickey()
  assert(buskey, errmsg)
  local answer, errmsg = encrypt(buskey, secret)
  assert(answer, errmsg)
  local login, lease = attempt:login(answer)
  assert(login)
  assert(lease)
  conn:setLogin(login)
  accontrol:logout()
  conn:setLogin(nil)
  removeCertificate()
end

function ACSuite.testCancelLoginByCertificate()
  registerCertificate()
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  assert(attempt)
  assert(challenge)
  local ok, errmsg = pcall(attempt.cancel, attempt)
  assert(ok, errmsg)
  removeCertificate()
end

function ACSuite.testLogoutLoginByCertificate()
  registerCertificate()  
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  assert(attempt)
  assert(challenge)
  local privatekey, errmsg = readprivatekey(pkey)
  assert(privatekey, errmsg)
  local secret, errmsg = decrypt(privatekey, challenge)
  assert(secret, errmsg)
  local result, errmsg = readcertificate(accontrol:_get_certificate())
  assert(result, errmsg)
  local buskey, errmsg =  result:getpublickey()
  assert(buskey, errmsg)
  local answer, errmsg = encrypt(buskey, secret)
  assert(answer, errmsg)
  local login, lease = attempt:login(answer)
  assert(login)
  assert(lease)
  conn:setLogin(login)
  accontrol:logout()
  -- calling after logout
  local ok, err = pcall(accontrol.renew, accontrol)
  assert(not ok)
  assert(err._repid == sysex.NO_PERMISSION)
  removeCertificate()
end

function ACSuite.testLoginByCertificateWrongAnswer()
  registerCertificate()  
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  assert(attempt)
  assert(challenge)
  local wrongsecret = "wrong secret"
  local result, errmsg = readcertificate(accontrol:_get_certificate())
  assert(result, errmsg)
  local buskey, errmsg =  result:getpublickey()
  assert(buskey, errmsg)
  local answer, errmsg = encrypt(buskey, wrongsecret)
  assert(answer, errmsg)
  local ok, errmsg = pcall(attempt.login, attempt, answer)
  assert(not ok)
  assert(errmsg._repid == logintypes.AccessDenied)
  removeCertificate()
end

function ACSuite.testLoginByCertificateNoEncoding()
  registerCertificate()  
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  assert(attempt)
  assert(challenge)
  local privatekey, errmsg = readprivatekey(pkey)
  assert(privatekey, errmsg)
  local secret, errmsg = decrypt(privatekey, challenge)
  assert(secret, errmsg)
  local result, errmsg = readcertificate(accontrol:_get_certificate())
  assert(result, errmsg)
  local buskey, errmsg =  result:getpublickey()
  assert(buskey, errmsg)
  local ok, errmsg = pcall(attempt.login, attempt, secret)
  assert(not ok)
  assert(errmsg._repid == logintypes.WrongEncoding)
  removeCertificate()
end

function ACSuite.testLoginByCertificateWrongEncoding()
  registerCertificate()
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local attempt, challenge = accontrol:startLoginByCertificate(dUser)
  assert(attempt)
  assert(challenge)
  local ok, errmsg = pcall(attempt.login, attempt, challenge)
  assert(not ok)
  assert(errmsg._repid == logintypes.WrongEncoding)
  removeCertificate()
end

function ACSuite.testRenew()
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local result, errmsg = readcertificate(accontrol:_get_certificate())
  assert(result, errmsg)
  local buskey, errmsg =  result:getpublickey()
  assert(buskey, errmsg)
  local encoded, errmsg = encrypt(buskey, dPassword)
  assert(encoded, errmsg)
  local login, lease = accontrol:loginByPassword(dUser, encoded)
  assert(login)
  assert(lease)
  conn:setLogin(login)
  oil.sleep(3*lease/4)
  lease = accontrol:renew()
  assert(lease)
  oil.sleep(3*lease/4)
  local ok, errmsg = pcall(accontrol.logout, accontrol)
  assert(ok, errmsg)
  conn:setLogin(nil)
end

function ACSuite.testExpiredLogin()
  local conn = connectByAddress(host, port)
  local accontrol = conn.AccessControl
  local result, errmsg = readcertificate(accontrol:_get_certificate())
  assert(result, errmsg)
  local buskey, errmsg =  result:getpublickey()
  assert(buskey, errmsg)
  local encoded, errmsg = encrypt(buskey, dPassword)
  assert(encoded, errmsg)
  local login, lease = accontrol:loginByPassword(dUser, encoded)
  assert(login)
  assert(lease)
  conn:setLogin(login)
  oil.sleep(3*lease)
  local ok, errmsg = pcall(accontrol.logout, accontrol)
  assert(not ok)
  assert(errmsg._repid == sysex.NO_PERMISSION)
  conn:setLogin(nil)
end
