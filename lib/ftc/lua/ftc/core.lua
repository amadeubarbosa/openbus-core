--
-- core.lua
--

-- Verbose
--local print = print
--local verbose = require "ftc.verbose"
--local LOG = verbose.LOG

local math      = math
local pairs     = pairs
local string    = string

local oo = require "loop.base"
module("ftc.core", oo.class)

function showAccessKey(key)
  local len = string.len(key)
  local dump = ''
  for i=1, len do
    dump = dump..'['..string.byte(key, i, i)..'] '
  end
  return dump
end

local sockets

local operation = {
  OPEN_READ_ONLY  = 0,
  OPEN_READ_WRITE = 1,
  CLOSE           = 2,
  SET_SIZE        = 3,
  GET_POSITION    = 4,
  SET_POSITION    = 5,
  GET_SIZE        = 6,
  READ            = 7,
  WRITE           = 8,
}

local FAILURE             = 255
local INVALID_KEY         = 254
local FILE_NOT_FOUND      = 253
local NO_PERMISSION       = 252
local FILE_LOCKED         = 251
local MAX_CLIENTS_REACHED = 250
local FILE_NOT_OPEN       = 249

local errorCode = {
  [FAILURE            ] = "Failure",
  [INVALID_KEY        ] = "Invalid Key",
  [FILE_NOT_FOUND     ] = "File not found.",
  [NO_PERMISSION      ] = "No permission.",
  [FILE_LOCKED        ] = "File locked",
  [MAX_CLIENTS_REACHED] = "Server max clients limit reached.",
  [FILE_NOT_OPEN      ] = "The file is not open",
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
local channel
local timeout
local readBufferSize

--- Create a remote file
-- @param identifier The file path
-- @param writable The writable flag
-- @param host The host of server
-- @param port The port of server
-- @param accessKey This is an access key for the file
function __init(self, psockets, identifier, writable, host, port, accessKey)
  sockets = psockets
  return oo.rawnew(self, {
    identifier = identifier,
    writable = writable,
    host = host,
    port = port,
    accessKey = accessKey,
	readBufferSize = 1024*1024
  } )
end

-- Base converter
-- Decimal to base 256
local function LuaNumber2Long(x)
-- [[Verbose]] LOG:LuaNumber2Long("x ["..x.."]")
  local v = ""
  x = math.floor(x)
  local m = 0
  for i = 1, 8 do
	m = math.mod(x, 256)  
    v = string.char(m)..v
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
    return nil, errorCode[NO_PERMISSION], NO_PERMISSION
  end
  local errmsg
  self.channel, errmsg = sockets:tcp()
  if not self.channel then
    return nil, errmsg , FAILURE
  end
-- [[VERBOSE]] LOG:open("Tentando se conectar em ", self.host, ":", self.port, " ...")
  local status, errmsg = self.channel:connect(self.host, self.port)
  if not status then
 -- [[VERBOSE]] LOG:open("ERRO '", errmsg, "'")
    return nil, errmsg, FAILURE
  end
-- [[VERBOSE]] LOG:open("Conexão estabelecida.")
  self.buffer = string.char(string.len(self.accessKey))
  self.buffer = self.buffer..self.accessKey
-- [[VERBOSE]] LOG:open("accessKey[", string.len(self.accessKey), "] = ", showAccessKey(self.accessKey))
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
    return nil, errmsg, FAILURE
  end
  --status = string.byte(self.channel:receive(1))
--falta testar INVALID_KEY
  local code = string.byte(self.channel:receive(1))
-- [[VERBOSE]] LOG:open("AccessKeyCode = ", code)
  if errorCode[code] then
-- [[VERBOSE]]   LOG:open("ERROR Code=", code, " Msg=", errorCode[code])
    return nil, errorCode[code], code
  end
  byte,err =self.channel:receive(1) 
  if not byte then
-- [[VERBOSE]]	  print("channel:receive error: " .. err)
	  return nil,err, FAILURE
  end
  code = string.byte(byte)
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
    return nil, errorCode[FILE_NOT_OPEN], FILE_NOT_OPEN
  end
  self.buffer = operation.CLOSE
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:close("ERRO '", errmsg, "'")
    return nil, errmsg , FAILURE
  end
  local code = string.byte(self.channel:receive(1))
-- [[VERBOSE]] LOG:close("Return code = ", code)
  if errorCode[code] then
    return nil, errorCode[code],code
  end
  self.channel:close()
  self.channel = nil
  self.opened = false
  return true
end

--- Resize the file for a specified length
-- @param size The new size of the file
-- @return Returns true in case of success, or, in case of errors,
-- nil plus error message.
function setSize(self, size)
-- [[VERBOSE]] LOG:setSize("SET_SIZE")
  if (self.readOnly) then
  -- [[VERBOSE]] LOG:setSize("ERRO '", errorCode[249], "'")
    return nil, errorCode[NO_PERMISSION], NO_PERMISSION
  end
  self.buffer = operation.SET_SIZE
  self.buffer = self.buffer..LuaNumber2Long(size)
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:setSize("ERRO '", errmsg, "'")
    return nil, errmsg, FAILURE
  end
-- o q se pode retornar como erro??
  local code = string.byte(self.channel:receive(1))
  if errorCode[code] then
  -- [[VERBOSE]] LOG:setSize("ERRO '", errorCode[code], "'")
    return nil, errorCode[code], code
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
    return nil, errmsg, FAILURE
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
    return nil, errmsg, FAILURE
  end
-- o q se pode retornar como erro??
  local code = string.byte(self.channel:receive(1))
  if errorCode[code] then
  -- [[VERBOSE]] LOG:setPosition("ERRO '", errorCode[code], "'")
    return nil, errorCode[code], code
  end
  return true, position
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
    return nil, errmsg, FAILURE
  end
  local bytes = self.channel:receive(8)
 -- [[VERBOSE]] LOG:getSize("size = = ", verbose.bytes(self.buffer))
--  print(OctBytes2Long(bytes))
  return true, OctBytes2Long(bytes)
end

function read(self, nbytes, position, userdata)
-- [[VERBOSE]] LOG:read("READ")
  self.buffer = operation.READ
-- [[VERBOSE]] LOG:read("nbytes = ", nbytes," position = ", position)
  self.buffer = self.buffer..LuaNumber2Long(position)..LuaNumber2Long(nbytes)
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:read("ERRO '", errmsg, "'")
    return nil, errmsg, FAILURE
  end
  local data, readBytes
  if userdata then
    data, errmsg , readBytes = self.channel:receiveC(nbytes, userdata)
  else
    data, errmsg = self.channel:receive(nbytes)
    if data then readBytes = #data end
  end
  if not data then
  -- [[VERBOSE]] LOG:read("ERRO '", errmsg, "'")
    return nil, errmsg, FAILURE 
  end
  return true, data , readBytes
end

function transferTo(self, position, count , outfile , userdata )
 -- [[VERBOSE]]  LOG:transferTo("")
  self.buffer = operation.READ
 -- [[VERBOSE]] LOG:transferTo("Position=", position, " Count=", count  , " outfile=", outfile) 
  self.buffer = self.buffer..LuaNumber2Long(position)..LuaNumber2Long(count)
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
 -- [[VERBOSE]]  LOG:transferTo("SEND ERROR '", errmsg, "'")
    return false, errmsg, FAILURE
  end

  local readBlockSize    = 0            
  local bytesAlreadyRead = 0            
  local missingBytes     = 0           
  local data,errmsg

  while( bytesAlreadyRead < count ) do    
    missingBytes = count - bytesAlreadyRead   

    if(missingBytes > self.readBufferSize) then 
        readBlockSize = self.readBufferSize 
    else
        readBlockSize = missingBytes 
    end

    -- Lendo os dados          
    if userdata then
      data, errmsg = self.channel:receiveC(readBlockSize, userdata)
    else
      data, errmsg = self.channel:receive(readBlockSize)
    end

    -- Se tudo ok escrevendo em um arquivo
    if not data then 
 -- [[VERBOSE]]      LOG:transferTo("DATA ERRO '", errmsg, "'")
		return nil, errmsg,FAILURE
    else
	  local ret
      if userdata then
        ret, errmsg = self.channel:writeToFile(outfile,readBlockSize, data)
      else
        ret, errmsg = outfile:write(data)
	  end

	  if ret == nil then
 -- [[VERBOSE]]  	  LOG:transferTo("WRITE ERRO '", errmsg, "'")
		  return nil, errmsg, FAILURE
	  end
    end

    bytesAlreadyRead = bytesAlreadyRead + readBlockSize
  end
  
  return true , bytesAlreadyRead 
end

function write(self, nbytes, position, data)
-- [[VERBOSE]] LOG:write("WRITE")
  if (self.readOnly) then
    return nil, errorCode[NO_PERMISSION], NO_PERMISSION
  end
  self.buffer = operation.WRITE
-- [[VERBOSE]] LOG:write("nbytes = ", nbytes," position = ", position)
  self.buffer = self.buffer..LuaNumber2Long(position)..LuaNumber2Long(nbytes)
  local status, errmsg = self.channel:send(self.buffer)
  if not status then
  -- [[VERBOSE]] LOG:write("ERRO '", errmsg, "'")
    return nil, errmsg, FAILURE
  end
  status, errmsg = self.channel:send(data)
  if not status then
  -- [[VERBOSE]] LOG:write("ERRO '", errmsg, "'")
    return nil, errmsg,FAILURE
  end
  local code = string.byte(self.channel:receive(1))
  if errorCode[code] then
  -- [[VERBOSE]] LOG:setPosition("ERRO '", errorCode[code], "'")
    return nil, errorCode[code], code
  end
  return true , nbytes
end

function setReadBufferSize(self, size)
	self.readBufferSize = size
	return self.readBufferSize
end

function getReadBufferSize(self)
	return self.readBufferSize
end
