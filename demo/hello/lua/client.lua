--
-- OpenBus Demo
-- client.lua
--

local oil = require "oil"
oil.verbose:level(3)
local openbus = require "openbus.Openbus"
local scsutils = require ("scs.core.utils").Utils()
local log = require "openbus.util.Log"

-- Inicializacao do barramento
local props = {}
scsutils:readProperties(props, "Hello.properties")
local host = props["host.name"].value
local port = props["host.port"].value
openbus:resetAndInitialize(host, tonumber(port))
local orb = openbus:getORB()

-- Execução
function main ()
  -- Carga da IDL Hello
  orb:loadidlfile("../idl/hello.idl")

  -- Conexão com o barramento e obtenção do componente HelloComponent
  local login = props.login.value
  local password = props.password.value
  local registryService = openbus:connect(login, password)
  if not registryService then
    io.stderr:write("HelloClient: Erro ao conectar ao barramento.\n")
    os.exit(1)
  end
  local offers = registryService:find({"IHello"})

  -- Assume que HelloComponent é o único serviço cadastrado.
  local helloComponent = orb:narrow(offers[1].member,
    "IDL:scs/core/IComponent:1.0")
  local helloFacet = helloComponent:getFacet("IDL:demoidl/hello/IHello:1.0")
  helloFacet = orb:narrow(helloFacet, "IDL:demoidl/hello/IHello:1.0")
  helloFacet:sayHello()
end

oil.main(function()
  print(oil.pcall(main))
end)
