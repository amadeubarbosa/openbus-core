--
-- init.lua
--

local receiveUserData = receiveUserData

-- Verbose
local print = print
-- [[VERBOSE]] local verbose = require "ftc.verbose"
-- [[VERBOSE]] local LOG = verbose.LOG

local error     = error
local math      = math
local pairs     = pairs
local string    = string
local tonumber  = tonumber

local oil = require 'oil'
local orb = oil.orb

local pack = oil.bit.pack

local oo = require "loop.base"
module("ftc", oo.class)

local sockets = oil.kernel.base.Sockets

local operation = {
  OPEN_READ_ONLY  = 0,
  OPEN_READ_WRITE = 1,
  CLOSE           = 2,
  TRUNCATE        = 3,
  GET_POSITION    = 4,
  SET_POSITION    = 5,
  GET_SIZE        = 6,
  READ            = 7,
  WRITE           = 8,
}

local errorCode = {
  FAILURE         = -1,                                         -- FAILURE
  INVALID_KEY     = -2,                                         -- INVALID_KEY
  [253]           = "File not found.",                          -- FILE_NOT_FOUND
  [252]           = "There is no permission to open the file.", -- NO_PERMISSION
  FILE_LOCKED     = -5,                                         -- FILE_LOCKED
  [250]           = "This file wasn't open.",                   -- FILE_NOT_OPENED
  [249]           = "This a read-only file.",                   -- IS_READ_ONLY_FILE
}

for k,v in pairs(operation) do
  operation[k] = string.char(v)
end

local buffer
local host
local port
local accessKey
local identifier
local writable
local opened
local readOnly
local size
local channel
local timeout

--- Create a remote file
-- @param identifier The file path
-- @param writable The writable flag
-- @param size The file size
-- @param host The host of server
-- @param port The port of server
-- @param accessKey This is an access key for the file
function __init(self, identifier, writable, size, host, port, accessKey)
  return oo.rawnew(self, {
    identifier = identifier,
    writable = writable,
    size = size,
    host = host,
    port = port,
    accessKey = accessKey,
  } )
end

-- Base converter
-- Decimal to base 256
local function LuaNumber2Long(x)
  local v = ""
  x = math.floor(x)
  for i = 1, 8 do
    v = string.char(math.mod(x, 256))..v
    x = math.floor(x / 256)
  end
  return v
end

-- Base converter
-- This function returns a representation of a number
-- in a decimal base.
local function OctBytes2Long(str)
-- [[VERBOSE]] LOG:OctBytes2Long("OctBytes = ", verbose.bytes(str))
  local v = 0
  for i = 1, 8 do
    v = v + string.byte(string.sub(str,i,i)) * math.pow(256, (8-i))
-- [[VERBOCE]] LOG:OctBytes2Long("str[", i, "] = ", string.byte(string.sub(str,i,i)), "\tv = ", v)
  end
  return v
end

function settimeout(self, timeout)
  self.timeout = timeout
end

--- Open a remote file
-- @param readonly The 'readonly' flag
-- @return Returns true in case of success, or, in case of errors,
-- nil plus an error message.
function open(self, readonly)
-- [[VERBOSE]] LOG:open("OPEN")
  if (readonly == false and self.writable == false) then
  -- [[VERBOSE]] LOG:open("O arquivo não pode ser aberto para escrita.")
    return nil, "O arquivo não pode ser aberto para escrita."
  end
  local errmsg
  self.channel, errmsg = sockets:tcp()
  if not self.channel then
    return nil, errmsg
  end
-- [[VERBOSE]] LOG:open("Tentando se conectar em ", self.host, ":", self.port, " ...")
  local status, errmsg = self.channel:connect(self.host, self.port)
  if not status then
  -- [[VERBOSE]] LOG:open("ERRO '", errmsg, "'")
    return nil, errmsg
  end
-- [[VERBOSE]] LOG:open("Conexão estabelecida.")
  self.buffer = string.char(string.len(self.accessKey))
  self.buffer = self.buffer..self.accessKey
-- [[VERBOSE]] LOG:open("accessKey = ", self.accessKey)
  if (readonly) then
  -- [[VERBOSE]] LOG:open("Operação OPEN_READ_ONLY")
    self.buffer = self.buffer..operation.OPEN_READ_ONLY
  else
  -- [[VERBOSE]] LOG:open("Operação OPEN_READ_WRITE")
    self.buffer = self.buffer..operation.OPEN_READ_WRITE
  end
  self.buffer = self.buffer..string.char(string.len(self.identifier))
  self.buffer = self.buffer..self.identifier
-- [[VERBOSE]] LOG:open("identifier = ", self.identifier)
  status, errmsg = self.channel:send(self.buffer)
  if not status then
    return nil, errmsg
  end
  --status = string.byte(self.channel:receive(1))
--falta testar INVALID_KEY
  local code = string.byte(self.channel:receive(1))
-- [[VERBOSE]] LOG:open("AccessKeyCode = ", code)
  if errorCode[code] then
  -- [[VERBOSE]] LOG:open("ERROR Code=", code, " Msg=", errorCode[code])
    return nil, errorCode[code], code
  end
  code = string.byte(self.channel:receive(1))
-- [[VERBOSE]] LOG:open("Return code = ", code)
  if errorCode[code] then
  -- [[VERBOSE]] LOG:open("ERROR Code=", code, " Msg=", errorCode[code])
    return nil, errorCode[code], code
  end
  self.opened = true
  self.readOnly = readonly
  return true
end

--- Verify if the file is open
-- @return Returns true in case of the file is open;
-- otherwise it returns false.
function isOpen(self)
  return self.opened
end

--- Close the file
-- @return Returns true in case of success, or, in case of errors,
-- nil plus error message.
function close(self)
-- [[VERBOSE]] LOG:close("CLOSE")
  if (not self.opened) then
  -- [[VERBOSE]] LOG:close("ERRO '", errorCode[250], "'")
    return nil, errorCode[250], 250
  end
  self.buffer = operation.CLOSE
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:close("ERRO '", errmsg, "'")
    return nil, errmsg
  end
  local code = string.byte(self.channel:receive(1))
-- [[VERBOSE]] LOG:close("Return code = ", code)
  if errorCode[code] then
    return nil, errorCode[code]
  end
  self.channel:close()
  self.channel = nil
  self.opened = false
  return true
end

--- Truncate the file for a specified length
-- @param size The new size of the file
-- @return Returns true in case of success, or, in case of errors,
-- nil plus error message.
function truncate(self, size)
-- [[VERBOSE]] LOG:truncate("TRUNCATE")
  if (self.readOnly) then
  -- [[VERBOSE]] LOG:truncate("ERRO '", errorCode[249], "'")
    return nil, errorCode[249], 249
  end
  self.buffer = operation.TRUNCATE
  self.buffer = self.buffer..LuaNumber2Long(size)
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:truncate("ERRO '", errmsg, "'")
    return nil, errmsg
  end
-- o q se pode retornar como erro??
  local code = string.byte(self.channel:receive(1))
  if errorCode[code] then
  -- [[VERBOSE]] LOG:truncate("ERRO '", errorCode[code], "'")
    return nil, errorCode[code]
  end
  return true
end

--- Get the file position
-- @return Returns true in case of success plus the current position of the file
-- , or, in case of errors, nil plus error message.
function getPosition(self)
-- [[VERBOSE]] LOG:getposition("GETPOSITION")
  self.buffer = operation.GET_POSITION
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:getposition("ERRO '", errmsg, "'")
    return nil, errmsg
  end
  local bytes = self.channel:receive(8)
-- [[VERBOSE]] LOG:getPosition("position = ", verbose.bytes(self.buffer))
  return true, OctBytes2Long(bytes)
end

function setPosition(self, position)
-- [[VERBOSE]] LOG:setPosition("SETPOSITION")
  self.buffer = operation.SET_POSITION
  self.buffer = self.buffer..LuaNumber2Long(position)
-- [[VERBOSE]] LOG:setPosition("position = ", position)
  local status , errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:setPosition("ERRO '", errmsg, "'")
    return nil, errmsg
  end
-- o q se pode retornar como erro??
  local code = string.byte(self.channel:receive(1))
  if errorCode[code] then
  -- [[VERBOSE]] LOG:setPosition("ERRO '", errorCode[code], "'")
    return nil, errorCode[code]
  end
  return true, size
end

--- Get the file size
-- @return Returns true in case of success plus the size of the file
-- , or, in case of errors, nil plus error message.
function getSize(self)
-- [[VERBOSE]] LOG:getSize("GETSIZE")
  self.buffer = operation.GET_SIZE
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:getSize("ERRO '", errmsg, "'")
    return nil, errmsg
  end
  local bytes = self.channel:receive(8)
-- [[VERBOSE]] LOG:getSize("size = = ", verbose.bytes(self.buffer))
  return true, OctBytes2Long(bytes)
end

function read(self, nbytes, position, userdata)
-- [[VERBOSE]] LOG:read("READ")
  self.buffer = operation.READ
  if (position > self.size) then
    position = self.size
  end
  local available = self.size - position
  if (nbytes > available) then
    nbytes = available
  end
-- [[VERBOSE]] LOG:read("nbytes = ", nbytes," position = ", position)
  self.buffer = self.buffer..LuaNumber2Long(position)..LuaNumber2Long(nbytes)
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:read("ERRO '", errmsg, "'")
    return nil, errmsg
  end
  local data
  if userdata then
    data, errmsg = self.channel:receiveC(nbytes, userdata)
  else
    data, errmsg = self.channel:receive(nbytes)
  end
  if not data then
  -- [[VERBOSE]] LOG:read("ERRO '", errmsg, "'")
    return nil, errmsg
  end
  return true, data
end

function write(self, nbytes, position, data)
-- [[VERBOSE]] LOG:write("WRITE")
  if (self.readOnly) then
    return nil, "This a read-only file."
  end
  self.buffer = operation.WRITE
  if (position > self.size) then
    position = self.size
  end
  local available = self.size - position
  if (nbytes > available) then
    nbytes = available
  end
-- [[VERBOSE]] LOG:write("nbytes = ", nbytes," position = ", position)
  self.buffer = self.buffer..LuaNumber2Long(position)..LuaNumber2Long(nbytes)
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:write("ERRO '", errmsg, "'")
    return nil, errmsg
  end
  status, errmsg = self.channel:send(data)
  if not status then
  -- [[VERBOSE]] LOG:write("ERRO '", errmsg, "'")
    return nil, errmsg
  end
  return true
  end
