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

local ACSWrapper = require "core.services.accesscontrol.AccessControlServiceWrapper"

local IComponent = require "scs.core.IComponent"

--  oil.verbose:level(0)
orb:loadidlfile "../../idl/hello.idl"

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

  --accessControlService = orb:newproxy("corbaloc::localhost:2020/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")
  accessControlService = ACSWrapper

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

--oil.verbose:flag("marshal", true)
--oil.verbose:flag("unmarshal", true)

  --ok, registryService = oil.pcall(accessControlService.getRegistryService, accessControlService)
  registryService = accessControlService:getRegistryService()

  local registryIdentifier

--oil.verbose:flag("marshal", false)
--oil.verbose:flag("unmarshal", false)

  local Hello = {}
    function Hello:sayHello()
      local user = serverInterceptor:getCredential().owner
      print "HELLO!\n\n"
      print(string.format("O usuário OpenBus %s requisitou a operação sayHello.", user))
      registryService:unregister(registryIdentifier)
    end
    --local M = IComponent("Membro", 1)
    local M = IComponent("Membro", 1, 0, 0, "")
    M = orb:newservant(M, nil, "IDL:scs/core/IComponent:1.0")
    M:addFacet("faceta", "IDL:demoidl/hello/IHello:1.0", Hello)
    success, registryIdentifier = registryService:register({ properties = {{name = "type", value = {"type"}}}, member = M, })
    print("*********************************************\n")
    print("PUBLISHER\nServiço Hello registrado no barramento do OpenBus.\n")
    print("*********************************************")
end

oil.main(function()
  print(oil.pcall(main))
end)
