--
--  server.lua
--

--Verbose
--[[VERBOSE]] local verbose = require "ftc.verbose"
--[[VERBOSE]] local LOG = verbose.LOG

require "oil"

local socket = require "socket"

local host = "localhost"
local port = 40120

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

local returnCode = {
  OK              = 0,
  NO_PERMISSION   = 252,
  FILE_NOT_FOUND  = 253,
}

local function LuaNumber2OctBytes(x)
  local v = ""
  x = math.floor(x)
  for i = 1, 8 do
    v = string.char(math.mod(x, 256))..v
    x = math.floor(x / 256)
  end
  return v
end

local function OctBytes2Long(str)
  local v = 0
  for i = 1, 8 do
    v = v + string.byte(string.sub(str,i,i)) * math.pow(256, (8-i))
  end
  return v
end

local server = assert(socket.tcp())
--[[VERBOSE]] LOG:log("Server "..tostring(server).." criado...")
assert(server:bind(host,port))
--[[VERBOSE]] LOG:log("Binds to: ", host, port, "\n")

assert(server:listen(1))

while true do
  local c = assert(server:accept())

--[[VERBOSE]] LOG:log("Client:", c)
  local ct = { client = c }
  ct.accessKeyLength = string.byte(assert(c:receive(1)))
--[[VERBOSE]] LOG:log("Pronto para receber chave de acesso de tamanho:", ct.accessKeyLength)
  ct.accessKey = assert(c:receive(ct.accessKeyLength))
--[[VERBOSE]] LOG:log("Chave de acesso:", ct.accessKey)
  while true do
    local opcode = string.byte(assert(c:receive(1)))
    if (opcode == operation.OPEN_READ_ONLY) then
    --[[VERBOSE]] LOG:log(true, "OPEN_READ_ONLY operation BEGIN")
      ct.filePathLength = string.byte(assert(c:receive(1)))
    --[[VERBOSE]] LOG:log("Pronto para receber path de tamanho:", ct.filePathLength)
      ct.filePath = assert(c:receive(ct.filePathLength))
    --[[VERBOSE]] LOG:log("Arquivo requisitado:", ct.filePath)
      local errmsg, errcode
      ct.fp, errmsg, errcode = io.open(ct.filePath)
      errcode = tonumber(errcode)
      assert(c:send(string.char(returnCode.OK)))
    --[[VERBOSE]] LOG:log("Código de retorno OK enviado")
    --"...The interpretation of the error numbers is system dependent..." PIL
      if (errcode == 2) then
    --[[VERBOSE]] LOG:log("Código de retorno FILE_NOT_FOUND enviado")
        assert(c:send(string.char(returnCode.FILE_NOT_FOUND)))
    --[[VERBOSE]] LOG:log(false, "OPEN_READ_WRITE operation END")
        break
      elseif (errcode == 13) then
        assert(c:send(string.char(returnCode.NO_PERMISSION)))
    --[[VERBOSE]] LOG:log(false, "OPEN_READ_WRITE operation END")
        break
      else
    --[[VERBOSE]] LOG:log("Código de retorno OK enviado")
        assert(c:send(string.char(returnCode.OK)))
      end
    --[[VERBOSE]] LOG:log(false, "OPEN_READ_ONLY operation END")
    elseif (opcode == operation.OPEN_READ_WRITE) then
    --[[VERBOSE]] LOG:log(true, "OPEN_READ_WRITE operation BEGIN")
      ct.filePathLength = string.byte(assert(c:receive(1)))
    --[[VERBOSE]] LOG:log("Pronto para receber path de tamanho:", ct.filePathLength)
      ct.filePath = assert(c:receive(ct.filePathLength))
    --[[VERBOSE]] LOG:log("Arquivo requisitado:", ct.filePath)
      local errmsg, errcode
      ct.fp, errmsg, errcode = io.open(ct.filePath, 'r+')
    --[[VERBOSE]] LOG:log("FP: ", ct.fp, " ErrMsg: ", errmsg, " Código de retorno OK enviado")
      assert(c:send(string.char(returnCode.OK)))
    --[[VERBOSE]] LOG:log("Código de retorno OK enviado")
      if (errcode == "2") then
        assert(c:send(string.char(returnCode.FILE_NOT_FOUND)))
    --[[VERBOSE]] LOG:log(false, "OPEN_READ_WRITE operation END")
        break
      elseif (errcode == 13) then
        assert(c:send(string.char(returnCode.NO_PERMISSION)))
    --[[VERBOSE]] LOG:log(false, "OPEN_READ_WRITE operation END")
        break
      else
    --[[VERBOSE]] LOG:log("Código de retorno OK enviado")
        assert(c:send(string.char(returnCode.OK)))
      end
    --[[VERBOSE]] LOG:log(false, "OPEN_READ_WRITE operation END")
    elseif (opcode == operation.CLOSE) then
    --[[VERBOSE]] LOG:log(true, "CLOSE operation BEGIN")
      assert(c:close())
    --[[VERBOSE]] LOG:log(false, "CLOSE operation END")
      break
    elseif (opcode == operation.TRUNCATE) then
    --[[VERBOSE]] LOG:log(true, "TRUNCATE operation BEGIN")
      local size = OctBytes2Long(assert(c:receive(8)))
    --[[VERBOSE]] LOG:log(true, "New size: ", size)
      local content = assert(ct.fp:read(size))
      assert(ct.fp:seek("set"))
      assert(ct.fp:write(content))
    --[[VERBOSE]] LOG:log("Código de retorno OK enviado")
      assert(c:send(string.char(returnCode.OK)))
    --[[VERBOSE]] LOG:log(false, "TRUNCATE operation END")
      break
    elseif (opcode == operation.GET_POSITION) then
    --[[VERBOSE]] LOG:log(true, "GET_POSITION operation BEGIN")
      local position = ct.fp:seek()
    --[[VERBOSE]] LOG:log("File position:", position)
      position = LuaNumber2OctBytes(position)
      assert(c:send(position))
    --[[VERBOSE]] LOG:log(false, "GET_POSITION operation END")
    elseif (opcode == operation.SET_POSITION) then
    --[[VERBOSE]] LOG:log(true, "SET_POSITION operation BEGIN")
      local position = OctBytes2Long(assert(c:receive(8)))
    --[[VERBOSE]] LOG:log("File position:", position)
      ct.fp:seek("set", position)
    --[[VERBOSE]] LOG:log("Código de retorno OK enviado")
      assert(c:send(string.char(returnCode.OK)))
--       assert(c:send(position))
    --[[VERBOSE]] LOG:log(false, "SET_POSITION operation END")
    elseif (opcode == operation.GET_SIZE) then
    --[[VERBOSE]] LOG:log(true, "GET_SIZE operation BEGIN")
      local actualPosition = ct.fp:seek()
      local size = ct.fp:seek("end")
    --[[VERBOSE]] LOG:log("File size:", size)
      ct.fp:seek("set", actualPosition)
      size = LuaNumber2OctBytes(size)
      assert(c:send(size))
    --[[VERBOSE]] LOG:log(false, "GET_SIZE operation END")
    elseif (opcode == operation.READ) then
    --[[VERBOSE]] LOG:log(true, "READ operation BEGIN")
      local position = OctBytes2Long(assert(c:receive(8)))
    --[[VERBOSE]] LOG:log("File position:", position)
      local nbytes = OctBytes2Long(assert(c:receive(8)))
    --[[VERBOSE]] LOG:log("Bytes to read:", nbytes)
      local content = ct.fp:read(nbytes)
    --[[VERBOSE]] LOG:log(string.format("Enviando %d bytes...", nbytes))
    --[[VERBOSE]] LOG:log(false, "CLOSE operation END")
      assert(c:send(content))
    elseif (opcode == operation.WRITE) then
    --[[VERBOSE]] LOG:log(true, "WRITE operation BEGIN")
      local position = OctBytes2Long(assert(c:receive(8)))
    --[[VERBOSE]] LOG:log("File position:", position)
      local nbytes = OctBytes2Long(assert(c:receive(8)))
    --[[VERBOSE]] LOG:log("Bytes to write:", nbytes)
      local content = assert(c:receive(nbytes))
      assert(ct.fp:seek("set", position))
      print(ct.fp:write(content))
    --[[VERBOSE]] LOG:log(true, "WRITE operation END")
    end
  end
end
