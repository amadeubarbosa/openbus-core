local coroutine = require "coroutine"
local running = coroutine.running

local struct = require "struct"
local encode = struct.pack

local hash = require "lce.hash"
local sha256 = hash.sha256
local pubkey = require "lce.pubkey"
local newkey = pubkey.create

local pubkey = require "lce.pubkey"
local decodepubkey = pubkey.decodepublic

local oil = require "oil"
local initORB = oil.init

local idl = require "openbus.core.idl"
local loadIDL = idl.loadto
local BusLogin = idl.const.BusLogin
local EncryptedBlockSize = idl.const.EncryptedBlockSize
local CredentialContextId = idl.const.credential.CredentialContextId
local loginconst = idl.const.services.access_control
local logintypes = idl.types.services.access_control
local credtypes = idl.types.credential


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

local function getorb()
  if orb == nil then
    orb = initORB{ flavor = "cooperative;corba.intercepted" }
    orb:setinterceptor(iceptor, "corba")
    loadIDL(orb)
  end
  return orb
end

local module = { getorb = getorb }

function module.encode(type, value)
  local encoder = orb:newencoder()
  encoder:put(value, type)
  return encoder:getdata()
end
function module.decode(type, stream)
  return orb:newdecoder(stream):get(type)
end

function module.putreqcxt(tag, data)
  local contexts = send.request[running()]
  if contexts == nil then
    contexts = {}
    send.request[running()] = contexts
  end
  contexts[tag] = data
end
function module.getrepcxt(tag)
  local contexts = receive.reply[running()]
  if contexts ~= nil then
    return contexts[tag]
  end
end
function module.getreqcxt(tag)
  local contexts = receive.request[running()]
  if contexts ~= nil then
    return contexts[tag]
  end
end
function module.putrepcxt(tag, data)
  local contexts = send.reply[running()]
  if contexts == nil then
    contexts = {}
    send.reply[running()] = contexts
  end
  contexts[tag] = data
end



NullSignature = string.rep("\000", EncryptedBlockSize)
NullEncodedChain = ""

do -- connection to the bus
  host, port = ...
  host = host or "localhost"
  port = port or 2089
  
  orb = module.getorb()
  bus = orb:newproxy(
    "corbaloc::"..host..":"..port.."/"..idl.const.BusObjectKey,
    nil, -- default proxy type
    "scs::core::IComponent")
  
  ac = assert(bus:getFacet(logintypes.AccessControl))
  ac = orb:narrow(ac, logintypes.AccessControl)
  
  busid = assert(ac:_get_busid())
  buskey = assert(decodepubkey(ac:_get_buskey()))
  
  prvkey = newkey(EncryptedBlockSize)
  pubkey = prvkey:encode("public")
end

-- protocol data encoders
function calculateHash(secret, ticket, opname)
  return sha256("\002\000"..encode(
    "<c0I4c0", -- '<' flag to set to little endian
    secret,    -- 'c0' sequence of all chars of a string
    ticket,    -- 'I4' unsigned integer with 4 bytes
    opname))   -- 'c0' sequence of all chars of a string
end

function encodeCredential(data)
  data.hash = calculateHash(data.secret, data.ticket, data.opname)
  local encoder = orb:newencoder()
  encoder:put(data, orb.types:lookup_id(credtypes.CredentialData))
  return encoder:getdata()
end

function decodeReset(stream)
  local reset = orb:newdecoder(stream):get(
    orb.types:lookup_id(credtypes.CredentialReset))
  reset.secret = assert(prvkey:decrypt(reset.challenge))
  return reset
end

function encodeLogin(data, pubkey)
  local encoder = orb:newencoder()
  encoder:put(
    {data=data,hash=sha256(pubkey)},
    orb.types:lookup_id(logintypes.LoginAuthenticationInfo))
  local encoded = encoder:getdata()
  return buskey:encrypt(encoded)
end


do -- login by password using reserved entity
  local entity = "OpenBus"
  local encrypted = encodeLogin(entity, pubkey)
  local ok, ex = pcall(ac.loginByPassword, ac, entity, pubkey, encrypted)
  assert(ok == false)
  assert(ex._repid == logintypes.AccessDenied)
end

do -- login by password
  entity = "ProtocolTest"
  local encrypted = encodeLogin(entity, pubkey)
  login, lease = ac:loginByPassword(entity, pubkey, encrypted)
end

do -- call without credential
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.NoCredentialCode)
end

do -- call with illegal credential
  module.putreqcxt(CredentialContextId, "ILLEGAL CDR STREAM")
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/MARSHAL:1.0")
end

do -- call with invalid credential
  module.putreqcxt(CredentialContextId, encodeCredential{
    opname = "renew",
    bus = busid,
    login = login.id,
    session = 1234,
    ticket = 4321,
    secret = "FakeSecret",
    chain = {
      signature = NullSignature,
      encoded = NullEncodedChain,
    },
  })
  local ok, ex = pcall(ac.renew, ac)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidCredentialCode)
  reset = decodeReset(assert(module.getrepcxt(CredentialContextId)))
  assert(reset.login == BusLogin)
end

do -- call with valid credential
  module.putreqcxt(CredentialContextId, encodeCredential{
    opname = "renew",
    bus = busid,
    login = login.id,
    session = reset.session,
    ticket = 1,
    secret = reset.secret,
    chain = {
      signature = NullSignature,
      encoded = NullEncodedChain,
    },
  })
  assert(ac:renew() > 0)
end

do -- sign chain for an invalid login
  module.putreqcxt(CredentialContextId, encodeCredential{
    opname = "signChainFor",
    bus = busid,
    login = login.id,
    session = reset.session,
    ticket = 2,
    secret = reset.secret,
    chain = {
      signature = NullSignature,
      encoded = NullEncodedChain,
    },
  })
  signedChainForInvalidLogin = ac:signChainFor("FakeLogin")
end

do -- join chain targeted for other login (an invalid one)
  module.putreqcxt(CredentialContextId, encodeCredential{
    opname = "signChainFor",
    bus = busid,
    login = login.id,
    session = reset.session,
    ticket = 3,
    secret = reset.secret,
    chain = signedChainForInvalidLogin,
  })
  local ok, ex = pcall(ac.signChainFor, ac, login.id)
  assert(ok == false)
  assert(ex._repid == "IDL:omg.org/CORBA/NO_PERMISSION:1.0")
  assert(ex.completed == "COMPLETED_NO")
  assert(ex.minor == loginconst.InvalidChainCode)
end

do -- logout
  module.putreqcxt(CredentialContextId, encodeCredential{
    opname = "logout",
    bus = busid,
    login = login.id,
    session = reset.session,
    ticket = 4,
    secret = reset.secret,
    chain = {
      signature = NullSignature,
      encoded = NullEncodedChain,
    },
  })
  ac:logout()
end
