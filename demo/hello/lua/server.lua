--
-- OpenBus Demo
-- server.lua
--

local oil = require "oil"
local oop = require "loop.base"
local openbus = require "openbus.Openbus"

-- Inicializa��o do barramento
openbus:resetAndInitialize("localhost", 2089)
local orb = openbus:getORB()

local scs = require "scs.core.base"

-- Implementa��o da Faceta IHello
local Hello = oop.class {}
function Hello:sayHello()
  local user = openbus:getInterceptedCredential().owner
  print "HELLO!\n\n"
  print("O usu�rio OpenBus " .. user .. " requisitou a opera��o sayHello.")
end

-- Descri��es do componente HelloComponent
local facetDescriptions = {}
facetDescriptions.IComponent = {
  name = "IComponent",
  interface_name = "IDL:scs/core/IComponent:1.0",
  class = scs.Component
}
facetDescriptions.IMetaInterface = {
  name = "IMetaInterface",
  interface_name = "IDL:scs/core/IMetaInterface:1.0",
  class = scs.MetaInterface
}
facetDescriptions.IHello = {
  name = "IHello",
  interface_name = "IDL:demoidl/hello/IHello:1.0",
  class = Hello
}
local componentId = {
  name = "HelloComponent",
  major_version = 1,
  minor_version = 0,
  patch_version = 0,
  platform_spec = ""
}

-- Execu��o
function main ()
  -- Carga da IDL Hello
  orb:loadidlfile("../idl/hello.idl")

  -- Permite que o ORB comece a aguardar requisi��es
  openbus:run()

  -- Instancia��o do componente HelloComponent
  local component = scs.newComponent(facetDescriptions, {}, componentId)

  -- Conex�o com o barramento e registro do componente
  local user = "tester"
  local password = "tester"
  local registryService = openbus:connect(user, password)
  if not registryService then
    io.stderr:write("HelloServer: Erro ao conectar ao barramento.\n")
    os.exit(1)
  end
  registryService:register({ properties = {}, member = component.IComponent})
  print("*********************************************\n")
  print("PUBLISHER\nServi�o Hello registrado no barramento do OpenBus.\n")
  print("*********************************************")
end

oil.main(function()
  print(oil.pcall(main))
end)
