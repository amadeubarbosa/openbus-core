local struct = require "struct"
local encode = struct.pack

local oil = require "oil"
local newORB = oil.init

local cothread = require "cothread"
local running = cothread.running
local sleep = cothread.delay

local hash = require "lce.hash"
local sha256 = hash.sha256
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
local credtypes = idl.types.credential

bushost, busport = ...
require "openbus.util.testcfg"

syskey = assert(decodeprvkey(syskey))

do -- CORBA GIOP message context manipuation functions
  
  local receive = {
    request = {},
    reply = {},
  }
  local send = {
    request = {},
    reply = {},
  }

  local iceptor = {}
  function iceptor:sendrequest(request)
    local thread = running()
    request.service_context = send.request[thread]
    send.request[thread] = nil
    receive.reply[thread] = nil
  end
  function iceptor:receivereply(request)
    local thread = running()
    receive.reply[thread] = request.reply_service_context
  end
  function iceptor:receiverequest(request)
    local thread = running()
    receive.request[thread] = request.service_context
  end
  function iceptor:sendreply(request)
    local thread = running()
    receive.request[thread] = nil
    request.reply_service_context = send.reply[thread]
    send.reply[thread] = nil
  end

  local orb
  function initORB()
    orb = newORB{ flavor = "cooperative;corba.intercepted" }
    orb:setinterceptor(iceptor, "corba")
    return orb
  end
  
  function encodeCDR(value, type)
    local encoder = orb:newencoder()
    encoder:put(value, orb.types:lookup_id(type))
    return encoder:getdata()
  end
  function decodeCDR(stream, type)
    return orb:newdecoder(stream):get(orb.types:lookup_id(type))
  end

  function putreqcxt(tag, data)
    local contexts = send.request[running()]
    if contexts == nil then
      contexts = {}
      send.request[running()] = contexts
    end
    contexts[tag] = data
  end
  function getrepcxt(tag)
    local contexts = receive.reply[running()]
    if contexts ~= nil then
      return contexts[tag]
    end
  end
  function getreqcxt(tag)
    local contexts = receive.request[running()]
    if contexts ~= nil then
      return contexts[tag]
    end
  end
  function putrepcxt(tag, data)
    local contexts = send.reply[running()]
    if contexts == nil then
      contexts = {}
      send.reply[running()] = contexts
    end
    contexts[tag] = data
  end
end

do -- protocol data encoding functions
  function encodeCredential(data)
    data.hash = sha256("\002\000"..encode(
      "<c0I4c0",    -- '<' flag to set to little endian
      data.secret,  -- 'c0' sequence of all chars of a string
      data.ticket,  -- 'I4' unsigned integer with 4 bytes
      data.opname)) -- 'c0' sequence of all chars of a string
    return encodeCDR(data, credtypes.CredentialData)
  end

  function decodeReset(stream)
    local reset = decodeCDR(stream, credtypes.CredentialReset)
    reset.secret = assert(prvkey:decrypt(reset.challenge))
    assert(reset.login == BusLogin)
    return reset
  end

  function decodeChain(buskey, signed)
    local encoded = signed.encoded
    assert(buskey:verify(sha256(encoded), signed.signature))
    return decodeCDR(encoded, logintypes.CallChain)
  end

  function encodeLogin(buskey, data, pubkey)
    return buskey:encrypt(encodeCDR({data = data, hash = sha256(pubkey)},
                                    logintypes.LoginAuthenticationInfo))
  end
end

do -- protocol predefined formats
  local FourHex = string.rep("%x", 4)

  LoginFormat = string.format("^%s%%-%s%%-%s%%-%s%%-%s$",
    FourHex:rep(2), FourHex, FourHex, FourHex, FourHex:rep(3))

  NullChain = {
    signature = string.rep("\000", EncryptedBlockSize),
    encoded = "",
  }
end

-- test initialization ---------------------------------------------------------

do -- connection to the bus
  orb = initORB(orb)
  loadIDL(orb)
  
  bus = orb:newproxy(
    "corbaloc::"..bushost..":"..busport.."/"..idl.const.BusObjectKey,
    nil, -- default proxy type
    "scs::core::IComponent")
  
  ac = assert(bus:getFacet(logintypes.AccessControl))
  ac = orb:narrow(ac, logintypes.AccessControl)
  
  busid = assert(ac:_get_busid())
  buskey = assert(decodepubkey(ac:_get_buskey()))
  
  prvkey = newkey(EncryptedBlockSize)
  pubkey = prvkey:encode("public")
  shortkey = newkey(EncryptedBlockSize-1):encode("public")
  
end

-- login by password -----------------------------------------------------------

do -- login using reserved entity
  local user = "OpenBus"
  local encrypted = encodeLogin(buskey, password, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.AccessDenied)
end

do -- login with wrong password
  local encrypted = encodeLogin(buskey, "WrongPassword", pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.AccessDenied)
end

do -- login with wrong access key hash
  local encrypted = encodeLogin(buskey, password, "WrongKey")
  local ok, ex = pcall(ac.loginByPassword, ac, user, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.AccessDenied)
end

do -- login with wrong bus key
  local buskey = decodepubkey(pubkey)
  local encrypted = encodeLogin(buskey, password, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.WrongEncoding)
end

do -- login with invalid access key
  local pubkey = "InvalidAccessKey"
  local encrypted = encodeLogin(buskey, password, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.InvalidPublicKey)
end

do -- login with key too short
  local pubkey = shortkey
  local encrypted = encodeLogin(buskey, password, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, user, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.InvalidPublicKey)
end

do -- login successfull
  local encrypted = encodeLogin(buskey, password, pubkey)
  local login, lease = ac:loginByPassword(user, pubkey, encrypted)
  assert(login.id:match(LoginFormat))
  assert(login.entity == user)
  assert(lease > 0)
  loginid = login.id
end

-- login by certificate -----------------------------------------------------------

do -- login with wrong secret
  local attempt = ac:startLoginByCertificate(system)
  local encrypted = encodeLogin(buskey, "WrongSecret", pubkey)
  local ok, ex = pcall(attempt.login, attempt, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.AccessDenied)
end

do -- login with wrong access key hash
  local attempt, challenge = ac:startLoginByCertificate(system)
  local secret = assert(syskey:decrypt(challenge))
  local encrypted = encodeLogin(buskey, secret, "WrongKey")
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
  local encrypted = encodeLogin(buskey, secret, pubkey)
  local ok, ex = pcall(attempt.login, attempt, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.InvalidPublicKey)
end

do -- login with invalid key too short
  local pubkey = shortkey
  local attempt, challenge = ac:startLoginByCertificate(system)
  local secret = assert(syskey:decrypt(challenge))
  local encrypted = encodeLogin(buskey, secret, pubkey)
  local ok, ex = pcall(attempt.login, attempt, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.InvalidPublicKey)
end

do -- login successfull
  local attempt, challenge = ac:startLoginByCertificate(system)
  local secret = assert(syskey:decrypt(challenge))
  local encrypted = encodeLogin(buskey, secret, pubkey)
  local login, lease = attempt:login(pubkey, encrypted)
  assert(attempt:_non_existent())
  assert(login.id:match(LoginFormat))
  assert(login.entity == system)
  assert(lease > 0)
  logoutid = login.id -- this login will be invalidated by a logout
end

do -- cancel login attempt
  local attempt = ac:startLoginByCertificate(system)
  attempt:cancel()
  assert(attempt:_non_existent())
end

-- logout ----------------------------------------------------------------------

do -- logout
  -- create an invalid credential
  local credential = {
    opname = "logout",
    bus = busid,
    login = logoutid,
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
  local reset = decodeReset(assert(getrepcxt(CredentialContextId)))
  -- update credential with credential reset information
  credential.session = reset.session
  credential.ticket = 1
  credential.secret = reset.secret
  putreqcxt(CredentialContextId, encodeCredential(credential))
  -- perform bus call
  ac:logout()
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

-- credentials -----------------------------------------------------------------

do -- no credential
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.NoCredentialCode)
  assert(getrepcxt(CredentialContextId) == nil)
end

do -- illegal credential
  putreqcxt(CredentialContextId, "ILLEGAL CDR STREAM")
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/MARSHAL:1.0")
  assert(getrepcxt(CredentialContextId) == nil)
end

do -- credential with fake login
  putreqcxt(CredentialContextId, encodeCredential{
    opname = "renew",
    bus = busid,
    login = "FakeLogin",
    session = 0,
    ticket = 0,
    secret = "",
    chain = NullChain,
  })
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidLoginCode)
  assert(getrepcxt(CredentialContextId) == nil)
end

do -- credential with fake bus ID
  putreqcxt(CredentialContextId, encodeCredential{
    opname = "renew",
    bus = "FakeBus",
    login = loginid,
    session = 0,
    ticket = 0,
    secret = "",
    chain = NullChain,
  })
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.UnknownBusCode)
  assert(getrepcxt(CredentialContextId) == nil)
end

do -- invalid credential
  putreqcxt(CredentialContextId, encodeCredential{
    opname = "renew",
    bus = busid,
    login = loginid,
    session = 1234,
    ticket = 4321,
    secret = string.rep("\171", 16),
    chain = NullChain,
  })
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidCredentialCode)
  reset = decodeReset(assert(getrepcxt(CredentialContextId)))
end

do -- valid credential
  putreqcxt(CredentialContextId, encodeCredential{
    opname = "renew",
    bus = busid,
    login = loginid,
    session = reset.session,
    ticket = 1,
    secret = reset.secret,
    chain = NullChain,
  })
  assert(ac:renew() > 0)
end

do -- credential with wrong secret
  local credential = {
    opname = "renew",
    bus = busid,
    login = loginid,
    session = reset.session,
    ticket = 2,
    secret = string.rep("\171", 16),
    chain = NullChain,
  }
  putreqcxt(CredentialContextId, encodeCredential(credential))
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidCredentialCode)
  decodeReset(assert(getrepcxt(CredentialContextId)))
  credential.secret = reset.secret -- use the correct secret now
  putreqcxt(CredentialContextId, encodeCredential(credential))
  assert(ac:renew() > 0)
end

do -- credential with wrong operation name
  local credential = {
    opname = "renova",
    bus = busid,
    login = loginid,
    session = reset.session,
    ticket = 3,
    secret = reset.secret,
    chain = NullChain,
  }
  putreqcxt(CredentialContextId, encodeCredential(credential))
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidCredentialCode)
  decodeReset(assert(getrepcxt(CredentialContextId)))
  credential.opname = "renew" -- use the correct operation name now
  putreqcxt(CredentialContextId, encodeCredential(credential))
  assert(ac:renew() > 0)
end

do -- credential with used ticket
  local credential = {
    opname = "renew",
    bus = busid,
    login = loginid,
    session = reset.session,
    ticket = 3,
    secret = reset.secret,
    chain = NullChain,
  }
  putreqcxt(CredentialContextId, encodeCredential(credential))
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidCredentialCode)
  decodeReset(assert(getrepcxt(CredentialContextId)))
  credential.ticket = 4 -- use a fresh ticket now
  putreqcxt(CredentialContextId, encodeCredential(credential))
  assert(ac:renew() > 0)
end

do -- credential with login not valid anymore
  putreqcxt(CredentialContextId, encodeCredential{
    opname = "renew",
    bus = busid,
    login = logoutid,
    session = reset.session,
    ticket = 2,
    secret = reset.secret,
    chain = NullChain,
  })
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidLoginCode)
end

-- chain signature -------------------------------------------------------------

do -- sign chain for an invalid login
  putreqcxt(CredentialContextId, encodeCredential{
    opname = "signChainFor",
    bus = busid,
    login = loginid,
    session = reset.session,
    ticket = 100,
    secret = reset.secret,
    chain = NullChain,
  })
  signed = ac:signChainFor(logoutid)
  local chain = decodeChain(buskey, signed)
  assert(chain.target == logoutid)
  assert(chain.caller.id == loginid)
  assert(chain.caller.entity == user)
end

do -- join chain targeted for other login (an invalid one)
  putreqcxt(CredentialContextId, encodeCredential{
    opname = "signChainFor",
    bus = busid,
    login = loginid,
    session = reset.session,
    ticket = 101,
    secret = reset.secret,
    chain = signed,
  })
  local ok, ex = pcall(ac.signChainFor, ac, logoutid)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidChainCode)
end

-- login lease -----------------------------------------------------------------

do
  local credential = {
    opname = "renew",
    bus = busid,
    login = loginid,
    session = reset.session,
    ticket = 200,
    secret = reset.secret,
    chain = NullChain,
  }
  -- check the 'renew' operation is keeping the login alive
  local lease
  for i = 1, 2 do
    credential.ticket = credential.ticket+1
    putreqcxt(CredentialContextId, encodeCredential(credential))
    lease = ac:renew()
    assert(lease > 0)
    sleep(lease)
  end
  -- wait for login to expire and check if the call will fail
  sleep(lease)
  credential.ticket = credential.ticket+1
  putreqcxt(CredentialContextId, encodeCredential(credential))
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidLoginCode)
end
