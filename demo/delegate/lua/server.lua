--
-- OpenBus Delegate Demo
-- server.lua
--

local oil = require "oil"
local oop = require "loop.base"
local openbus = require "openbus.Openbus"
local scsutils = require ("scs.core.utils").Utils()

-- Inicializa��o do barramento
local props = {}
scsutils:readProperties(props, "Delegate.properties")
local host = props["host.name"].value
local port = props["host.port"].value
openbus:init(host, tonumber(port))
--openbus:enableFaultTolerance()
local orb = openbus:getORB()

local scs = require "scs.core.base"

-- Implementa��o da Faceta IHello
local Hello = oop.class {}
function Hello:sayHello()
  local intCred = openbus:getInterceptedCredential()
  print "HELLO!\n\n"
  print("[Thread " .. intCred.delegate .. "]: Hello " .. intCred.owner .. " !")
end

-- Descri��es do componente HelloComponent
local facetDescriptions = {}
facetDescriptions.IHello = {
  name = "IHello",
  interface_name = "IDL:demoidl/demoDelegate/IHello:1.0",
  class = Hello
}
local componentId = {
  name = "DelegateService",
  major_version = 1,
  minor_version = 0,
  patch_version = 0,
  platform_spec = ""
}

-- Execu��o
function main ()
  -- Carga da IDL Hello
  orb:loadidlfile("../idl/delegate.idl")

  -- Permite que o ORB comece a aguardar requisi��es
  openbus:run()

  -- Instancia��o do componente HelloComponent
  local component = scs.newComponent(facetDescriptions, {}, componentId)

  -- Conex�o com o barramento e registro do componente
  local entityName = props["entity.name"].value
  local privateKeyFile = props["private.key"].value
  local acsCertificateFile = props["acs.certificate"].value
  local registryService = openbus:connectByCertificate(entityName, privateKeyFile, acsCertificateFile)
  if not registryService then
    io.stderr:write("HelloServer: Erro ao conectar ao barramento.\n")
    os.exit(1)
  end
  local suc = registryService:register({ properties = {}, member = component.IComponent})
  if not suc then
      io.stderr:write("HelloServer: Erro ao registrar ofertas.\n")
      os.exit(1)
  end
  print("*********************************************\n")
  print("PUBLISHER\nServi�o Hello registrado no barramento do OpenBus.\n")
  print("*********************************************")
end

oil.main(function()
  print(oil.pcall(main))
end)