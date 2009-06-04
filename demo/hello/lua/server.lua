--
-- OpenBus Demo
-- publisher.lua
--

local oil = require "oil"

local orb = oil.init {
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"

local oop = require "loop.base"
local scs = require "scs.core.base"

--  oil.verbose:level(0)
orb:loadidlfile "../idl/hello.idl"

oil.tasks:register(coroutine.create(function() return orb:run() end))

function main ()
  local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
  if IDLPATH_DIR == nil then
    io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
    os.exit(1)
  end

  local idlfile = IDLPATH_DIR.."/registry_service.idl"
  orb:loadidlfile(idlfile)
  idlfile = IDLPATH_DIR.."/access_control_service.idl"
  orb:loadidlfile(idlfile)

  local user = "tester"
  local password = "tester"

  accessControlService = orb:newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

  -- instala o interceptador de cliente
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()
  credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config, credentialManager))
  serverInterceptor = ServerInterceptor(config, accessControlService)
  orb:setserverinterceptor(serverInterceptor)

  local success
  success, credential = accessControlService:loginByPassword(user, password)
  credentialManager:setValue(credential)

  registryService = accessControlService:getRegistryService()

  local registryIdentifier

  local Hello = oop.class{}
    function Hello:sayHello()
      local user = serverInterceptor:getCredential().owner
      print "HELLO!\n\n"
      print(string.format("O usu�rio OpenBus %s requisitou a opera��o sayHello.", user))
      registryService:unregister(registryIdentifier)
    end
    local facetDescriptions = {}
    facetDescriptions.IComponent = {name = "IComponent", interface_name = "IDL:scs/core/IComponent:1.0",
                                     class = scs.Component}
    facetDescriptions.IMetaInterface = {name = "IMetaInterface", interface_name = "IDL:scs/core/IMetaInterface:1.0", class = scs.MetaInterface}
    facetDescriptions.IHello = {name = "IHello", interface_name = "IDL:demoidl/hello/IHello:1.0", class = Hello}
    local componentId = {name = "Membro", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = ""}
    local component = scs.newComponent(facetDescriptions, {}, componentId)
    success, registryIdentifier = registryService:register({ properties = {}, 
      member = component.IComponent})
    print("*********************************************\n")
    print("PUBLISHER\nServi�o Hello registrado no barramento do OpenBus.\n")
    print("*********************************************")
end

oil.main(function()
  print(oil.pcall(main))
end)
