--
-- OpenBus Demo
-- publisher.lua
--

package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
local oil = require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local ServerInterceptor = require "openbus.common.ServerInterceptor"
local CredentialHolder = require "openbus.common.CredentialHolder"

local IComponent = require "scs.core.IComponent"

--  oil.verbose:level(0)
oil.loadidlfile "hello.idl"

oil.tasks:register(coroutine.create(oil.run))

function main ()
  local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
  if CORBA_IDL_DIR == nil then
    io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
    os.exit(1)
  end

  local idlfile = CORBA_IDL_DIR.."/registry_service.idl"
  oil.loadidlfile(idlfile)
  idlfile = CORBA_IDL_DIR.."/access_control_service.idl"
  oil.loadidlfile(idlfile)

  local user = "csbase"
  local password = "csbLDAPtest"

  accessControlService = oil.newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

  -- instala o interceptador de cliente
  local CONF_DIR = os.getenv("CONF_DIR")
  local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
  credentialHolder = CredentialHolder()
  oil.setclientinterceptor(ClientInterceptor(config, credentialHolder))
  serverInterceptor = ServerInterceptor(config, accessControlService)
  oil.setserverinterceptor(serverInterceptor)

  local success
  success, credential = accessControlService:loginByPassword(user, password)
  credentialHolder:setValue(credential)

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
    success, registryIdentifier = registryService:register({type = "type", description = "none",
properties = {}, member = M, })
    print("*********************************************\n")
    print("PUBLISHER\nServiço Hello registrado no barramento do OpenBus.\n")
    print("*********************************************")
end

oil.main(function()
  print(oil.pcall(main))
end)
