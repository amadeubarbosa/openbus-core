require "openbus.test.configs"
require "openbus.test.lowlevel"

local cothread = require "cothread"
local sleep = cothread.delay

local uuid = require "uuid"
local validid = uuid.isvalid

local pubkey = require "lce.pubkey"
local newkey = pubkey.create
local decodepubkey = pubkey.decodepublic
local decodeprvkey = pubkey.decodeprivate

local idl = require "openbus.core.idl"
local loadIDL = idl.loadto
local BusLogin = idl.const.BusLogin
local EncryptedBlockSize = idl.const.EncryptedBlockSize
local CredentialContextId = idl.const.credential.CredentialContextId
local loginconst = idl.const.services.access_control
local logintypes = idl.types.services.access_control

local giop = require "oil.corba.giop"
local sysex = giop.SystemExceptionIDs

local server = require "openbus.util.server"
local readfrom = server.readfrom

busref = assert(readfrom(busref))
syskey = assert(decodeprvkey(assert(readfrom(syskey))))

-- test initialization ---------------------------------------------------------

local bus, orb = connectToBus(busref)
local ac = bus.AccessControl
local prvkey = newkey(EncryptedBlockSize)
local pubkey = prvkey:encode("public")
local shortkey = newkey(EncryptedBlockSize-1):encode("public")
local longkey = newkey(EncryptedBlockSize+1):encode("public")
local otherkey = newkey(EncryptedBlockSize)

-- local function --------------------------------------------------------------

local function doLogout(login)
  -- create an invalid credential
  local credential = {
    opname = "logout",
    bus = bus.id,
    login = login,
    session = 0,
    ticket = 0,
    secret = "",
    chain = NullChain,
  }
  putreqcxt(CredentialContextId, encodeCredential(credential))
  -- request cresential reset
  local ok, ex = pcall(ac.logout, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidCredentialCode)
  local reset = decodeReset(assert(getrepcxt(CredentialContextId)), prvkey)
  -- update credential with credential reset information
  credential.session = reset.session
  credential.ticket = 1
  credential.secret = reset.secret
  putreqcxt(CredentialContextId, encodeCredential(credential))
  -- perform bus call
  ac:logout()
  return credential
end

-- login by password -----------------------------------------------------------

do -- login using reserved entity
  local user = "OpenBus"
  local encrypted = encodeLogin(bus.key, password, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, domain, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.AccessDenied)
end

for _, userpat in pairs{"%s", "%s%d"} do
  do -- login with wrong password max tries
    local encrypted = encodeLogin(bus.key, "WrongPassword", pubkey)
    local ok, ex
    for i = 1, passwordtries do
      local entity = userpat:format(user, i)
      ok, ex = pcall(ac.loginByPassword, ac, entity, domain, pubkey, encrypted)
      assert(ok == false)
      assert(ex._repid == logintypes.AccessDenied)
    end
    ok, ex = pcall(ac.loginByPassword, ac, user, domain, pubkey, encrypted)
    assert(ok == false)
    assert(ex._repid == logintypes.TooManyAttempts)
    assert(ex.domain == "ADDRESS")
    assert(ex.penaltyTime - 1000*passwordpenalty < 0.1)
    sleep(passwordpenalty)
    ok, ex = pcall(ac.loginByPassword, ac, user, domain, pubkey, encrypted)
    assert(ok == false)
    assert(ex._repid == logintypes.AccessDenied)
    -- reseting failed login attempts
    sleep(passwordpenalty)
  end

  do -- login with wrong password max - 1 tries
    local encrypted = encodeLogin(bus.key, "WrongPassword", pubkey)
    local ok, ex
    for i = 1, passwordtries - 1 do
      local entity = userpat:format(user, i)
      ok, ex = pcall(ac.loginByPassword, ac, entity, domain, pubkey, encrypted)
      assert(ok == false)
      assert(ex._repid == logintypes.AccessDenied)
    end
    encrypted = encodeLogin(bus.key, password, pubkey)
    local login = ac:loginByPassword(user, domain, pubkey, encrypted)
    doLogout(login.id)
    encrypted = encodeLogin(bus.key, "WrongPassword", pubkey)
    ok, ex = pcall(ac.loginByPassword, ac, user, domain, pubkey, encrypted)
    assert(ok == false)
    assert(ex._repid == logintypes.AccessDenied)
    -- reseting failed login attempts
    sleep(passwordpenalty)
  end
end


-- TODO: login with wrong password max tries with different IP addresses

do -- login with wrong access key hash
  local encrypted = encodeLogin(bus.key, password, "WrongKey")
  local ok, ex = pcall(ac.loginByPassword, ac, user, domain, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.AccessDenied)
end

do -- login with wrong bus key
  local buskey = decodepubkey(pubkey)
  local encrypted = encodeLogin(buskey, password, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, domain, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.WrongEncoding)
end

do -- login with invalid access key
  local pubkey = "InvalidAccessKey"
  local encrypted = encodeLogin(bus.key, password, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, domain, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.InvalidPublicKey)
end

do -- login with key too short
  local pubkey = shortkey
  local encrypted = encodeLogin(bus.key, password, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, domain, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.InvalidPublicKey)
end

do -- login with key too long
  local pubkey = longkey
  local encrypted = encodeLogin(bus.key, password, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, domain, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.InvalidPublicKey)
end

do -- login successfull
  local encrypted = encodeLogin(bus.key, password, pubkey)
  local login, lease = ac:loginByPassword(user, domain, pubkey, encrypted)
  assert(validid(login.id))
  assert(login.entity == user)
  assert(lease > 0)
  validlogin = login
end

-- login by certificate -----------------------------------------------------------

do -- login with wrong secret
  local attempt = ac:startLoginByCertificate(system)
  local encrypted = encodeLogin(bus.key, "WrongSecret", pubkey)
  local ok, ex = pcall(attempt.login, attempt, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.AccessDenied)
end

do -- login with wrong access key hash
  local attempt, challenge = ac:startLoginByCertificate(system)
  local secret = assert(syskey:decrypt(challenge))
  local encrypted = encodeLogin(bus.key, secret, "WrongKey")
  local ok, ex = pcall(attempt.login, attempt, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.AccessDenied)
end

do -- login with wrong bus key
  local buskey = decodepubkey(pubkey)
  local attempt, challenge = ac:startLoginByCertificate(system)
  local secret = assert(syskey:decrypt(challenge))
  local encrypted = encodeLogin(buskey, secret, pubkey)
  local ok, ex = pcall(attempt.login, attempt, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.WrongEncoding)
end

do -- login with invalid access key
  local pubkey = "InvalidAccessKey"
  local attempt, challenge = ac:startLoginByCertificate(system)
  local secret = assert(syskey:decrypt(challenge))
  local encrypted = encodeLogin(bus.key, secret, pubkey)
  local ok, ex = pcall(attempt.login, attempt, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.InvalidPublicKey)
end

do -- login with invalid key too short
  local pubkey = shortkey
  local attempt, challenge = ac:startLoginByCertificate(system)
  local secret = assert(syskey:decrypt(challenge))
  local encrypted = encodeLogin(bus.key, secret, pubkey)
  local ok, ex = pcall(attempt.login, attempt, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.InvalidPublicKey)
end

do -- login successfull
  local attempt, challenge = ac:startLoginByCertificate(system)
  local secret = assert(syskey:decrypt(challenge))
  local encrypted = encodeLogin(bus.key, secret, pubkey)
  local login, lease = attempt:login(pubkey, encrypted)
  assert(attempt:_non_existent())
  assert(validid(login.id))
  assert(login.entity == system)
  assert(lease > 0)
  syslogin = login.id -- this login will be invalidated by a logout
end

do -- cancel login attempt
  local attempt = ac:startLoginByCertificate(system)
  attempt:cancel()
  assert(attempt:_non_existent())
end

-- credentials -----------------------------------------------------------------

do
  validlogin.prvkey = prvkey
  validlogin.busSession = initBusSession(bus, validlogin)
  local function greaterthanzero(value) assert(value > 0) end
  testBusCall(bus, validlogin, otherkey, greaterthanzero, bus.AccessControl, "renew")
end

-- chain signature 1 -----------------------------------------------------------

do -- join chain targeted for other login
  validlogin.busSession:newCred("signChainFor")
  signed = ac:signChainFor(system)
  local chain = decodeChain(bus.key, signed)
  assert(chain.target == system)
  assert(chain.caller.id == validlogin.id)
  assert(chain.caller.entity == user)

  validlogin.busSession:newCred("signChainFor", signed)
  local ok, ex = pcall(ac.signChainFor, ac, validlogin.entity)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidChainCode)
end

-- logout ----------------------------------------------------------------------

do -- logout
  local credential = doLogout(syslogin)
  -- update credential with new ticket
  credential.ticket = credential.ticket+1
  putreqcxt(CredentialContextId, encodeCredential(credential))
  -- check if the call will fail
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidLoginCode)
end

-- chain signature 2 -----------------------------------------------------------

do -- sign chain for an entity without login
  validlogin.busSession:newCred("signChainFor")
  signed = ac:signChainFor(system)
  local chain = decodeChain(bus.key, signed)
  assert(chain.target == system)
  assert(chain.caller.id == validlogin.id)
  assert(chain.caller.entity == user)
end

-- login lease -----------------------------------------------------------------

do
  -- check the 'renew' operation is keeping the login alive
  local lease
  for i = 1, 2 do
    validlogin.busSession:newCred("renew")
    lease = ac:renew()
    assert(lease > 0)
    sleep(lease)
  end
  -- wait for login to expire and check if the call will fail
  sleep(lease+1)
  validlogin.busSession:newCred("renew")
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidLoginCode)
end

orb:shutdown()
