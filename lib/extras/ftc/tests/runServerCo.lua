--
--  runServerCo.lua
--

require "oil"

local socket = require "socket"

local host = "localhost"
local port = 45000

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
}

local function OctBytes2Long(str)
  local v = 0
  for i = 1, 8 do
    v = v + string.byte(string.sub(str,i,i)) * math.pow(256, (8-i))
  end
  return v
end

oil.main( function()
  oil.newthread( function()
    local server = assert(socket.tcp())
    print("Server "..tostring(server).." criado...")
    assert(server:bind(host,port))
    print("Binds to: ", host, port, "\n")

    assert(server:listen(1))
    local c = assert(server:accept())

    print("Client:", c)
    local ct = { client = c }
    ct.accessKeyLength = string.byte(assert(c:receive(1)))
    print("Pronto para receber chave de acesso de tamanho:", ct.accessKeyLength)
    ct.accessKey = assert(c:receive(ct.accessKeyLength))
    print("Chave de acesso:", ct.accessKey)
    local n = 0
    while true do
      local opcode = string.byte(assert(c:receive(1)))
      print("OPERAÇÂO:", opcode)
      if (opcode == operation.OPEN_READ_ONLY) then
        print("OPEN_READ_ONLY operation")
        ct.filePathLength = string.byte(assert(c:receive(1)))
        print("Pronto para receber path de tamanho:", ct.filePathLength)
        ct.filePath = assert(c:receive(ct.filePathLength))
        print("Arquivo requisitado:", ct.filePath)
        ct.fp = assert(io.open(ct.filePath))
        assert(c:send(string.char(returnCode.OK)))
        print("Código de retorno OK enviado")
        assert(c:send(string.char(returnCode.OK)))
        print("Código de retorno OK enviado")
      elseif (opcode == operation.READ) then
        print("READ operation")
        local position = OctBytes2Long(assert(c:receive(8)))
        print("File position:", position)
        local nbytes = OctBytes2Long(assert(c:receive(8)))
        print("Bytes to read:", nbytes)
        local content = ct.fp:read(nbytes)
        print("Content of the file:")
        print(content)
        print("Enviando 7 bytes...")
        assert(c:send(string.sub(content,1,7)))
        print("Dormindo por 3 segundos...")
        oil.sleep(3)
        print("Enviando 2 bytes...")
        assert(c:send(string.sub(content,8,9)))
        print("Dormindo por 5 segundos...")
        oil.sleep(5)
        print("Enviando 1 byte...")
        assert(c:send(string.sub(content,10,10)))
      end
      n = n + 1
    end
    server:close()
  end)
  oil.loadidl([[
  interface foo {
    void run() ;
  } ;
  ]])
  foo = oil.newproxy(assert(oil.readfrom("ref.ior")), "IDL:foo:1.0")
  while true do
    foo:run()
    oil.sleep(1)
  end
end)
