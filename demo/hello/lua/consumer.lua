--
-- OpenBus Demo
-- consumer.lua
--

local oil = require "oil"

local orb = oil.init {
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

local ClientInterceptor = require "openbus.common.ClientInterceptor"
local CredentialManager = require "openbus.common.CredentialManager"

local IComponent = require "scs.core.IComponent"

--  oil.verbose:level(0)
orb:loadidlfile "hello.idl"

function main ()
  local CORE_IDL_DIR = os.getenv("CORE_IDL_DIR")
  if CORE_IDL_DIR == nil then
    io.stderr:write("A variavel CORE_IDL_DIR nao foi definida.\n")
    os.exit(1)
  end

  local idlfile = CORE_IDL_DIR.."/registry_service.idl"
  orb:loadidlfile(idlfile)
  idlfile = CORE_IDL_DIR.."/access_control_service.idl"
  orb:loadidlfile(idlfile)

  local user = "tester"
  local password = "tester"

  accessControlService = orb:newproxy("corbaloc::localhost:2089/ACS", "IDL:openbusidl/acs/IAccessControlService:1.0")

-- instala o interceptador de cliente
  local CONF_DIR = os.getenv("CONF_DIR")
  local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()
  credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config, credentialManager))

  local success
  success, credential = accessControlService:loginByPassword(user, password)
  credentialManager:setValue(credential)

  registryService = accessControlService:getRegistryService()

  local offers = registryService:find({name = "type", value = "type"})
  -- Assume que o publisher � o �nico servi�o cadastrado.
  SS = orb:narrow(offers[1].member, "IDL:scs/core/IComponent:1.0")
  local facet = SS:getFacet("IDL:Hello:1.0")
  hello = orb:narrow(facet, "IDL:Hello:1.0")
  hello:sayHello()

end

oil.main(function()
  print(oil.pcall(main))
end)
