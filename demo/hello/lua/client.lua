--
-- OpenBus Demo
-- client.lua
--

local oil = require "oil"
oil.verbose:level(3)
local openbus = require "openbus.Openbus"

-- Inicializa��o do barramento
openbus:resetAndInitialize("localhost", 2089, orbinit)
local orb = openbus:getORB()

-- Execu��o
function main ()
  -- Carga da IDL Hello
  orb:loadidlfile("../idl/hello.idl")

  -- Conex�o com o barramento e obten��o do componente HelloComponent
  local user = "tester"
  local password = "tester"
  local registryService = openbus:connect(user, password)
  if not registryService then
    io.stderr:write("HelloClient: Erro ao conectar ao barramento.\n")
    os.exit(1)
  end
  local offers = registryService:find({"IHello"})

  -- Assume que HelloComponent � o �nico servi�o cadastrado.
  local helloComponent = orb:narrow(offers[1].member,
    "IDL:scs/core/IComponent:1.0")
  local helloFacet = helloComponent:getFacet("IDL:demoidl/hello/IHello:1.0")
  helloFacet = orb:narrow(helloFacet, "IDL:demoidl/hello/IHello:1.0")
  helloFacet:sayHello()
end

oil.main(function()
  print(oil.pcall(main))
end)
