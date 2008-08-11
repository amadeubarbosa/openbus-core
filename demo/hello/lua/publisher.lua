--
-- OpenBus Demo
-- publisher.lua
--

package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
local oil = require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"

local IComponent = require "scs.core.IComponent"

--  oil.verbose:level(0)
oil.loadidlfile "hello.idl"

oil.tasks:register(coroutine.create(oil.run))

function main ()
  local CORE_IDL_DIR = os.getenv("CORE_IDL_DIR")
  if CORE_IDL_DIR == nil then
    io.stderr:write("A variavel CORE_IDL_DIR nao foi definida.\n")
    os.exit(1)
  end

  local idlfile = CORE_IDL_DIR.."/registry_service.idl"
  oil.loadidlfile(idlfile)
  idlfile = CORE_IDL_DIR.."/access_control_service.idl"
  oil.loadidlfile(idlfile)

  local user = "tester"
  local password = "tester"

  accessControlService = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

  -- instala o interceptador de cliente
  local CONF_DIR = os.getenv("CONF_DIR")
  local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
  credentialManager = CredentialManager()
  oil.setclientinterceptor(ClientInterceptor(config, credentialManager))
  serverInterceptor = ServerInterceptor(config, accessControlService)
  oil.setserverinterceptor(serverInterceptor)

  local success
  success, credential = accessControlService:loginByPassword(user, password)
  credentialManager:setValue(credential)

  registryService = accessControlService:getRegistryService()

  local registryIdentifier

  local Hello = {}
    function Hello:sayHello()
      local user = serverInterceptor:getCredential().entityName
      print "HELLO!\n\n"
      print(string.format("O usuário OpenBus %s requisitou a operação sayHello.", user))
      registryService:unregister(registryIdentifier)
    end
    local M = IComponent("Membro", 1)
    M = oil.newobject(M, "IDL:scs/core/IComponent:1.0")
    M:addFacet("faceta", "IDL:Hello:1.0", Hello)
    success, registryIdentifier = registryService:register({ properties = {{name = "type", value = {"type"}}}, member = M, })
    print("*********************************************\n")
    print("PUBLISHER\nServiço Hello registrado no barramento do OpenBus.\n")
    print("*********************************************")
end

oil.main(function()
  print(oil.pcall(main))
end)
