--
-- OpenBus Demo
-- consumer.lua
--

package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
local oil = require "oil"

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"

local IComponent = require "scs.core.IComponent"

--  oil.verbose:level(0)
oil.loadidlfile "hello.idl"

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

  local user = "tester"
  local password = "tester"

  accessControlService = oil.newproxy("corbaloc::localhost:2089/ACS",
"IDL:openbusidl/acs/IAccessControlService:1.0")

-- instala o interceptador de cliente
  local CONF_DIR = os.getenv("CONF_DIR")
  local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
  credentialManager = CredentialManager()
  oil.setclientinterceptor(ClientInterceptor(config, credentialManager))

  local success
  success, credential = accessControlService:loginByPassword(user, password)
  credentialManager:setValue(credential)

  registryService = accessControlService:getRegistryService()

  local offers = registryService:find("type", {})
  -- Assume que o publisher é o único serviço cadastrado.
  SS = oil.narrow(offers[1].member, "IDL:scs/core/IComponent:1.0")
  local facet = SS:getFacet("IDL:Hello:1.0")
  hello = oil.narrow(facet, "IDL:Hello:1.0")
  hello:sayHello()

end

oil.main(function()
  print(oil.pcall(main))
end)
