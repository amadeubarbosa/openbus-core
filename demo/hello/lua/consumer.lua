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

--  oil.verbose:level(0)
orb:loadidlfile "../idl/hello.idl"

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

  local success
  success, credential = accessControlService:loginByPassword(user, password)
  credentialManager:setValue(credential)

  registryService = accessControlService:getRegistryService()

  local offers = registryService:find({name = "facets", value = "Hello"})
  -- Assume que o publisher é o único serviço cadastrado.
  SS = orb:narrow(offers[1].member, "IDL:scs/core/IComponent:1.0")
  local facet = SS:getFacet("IDL:demoidl/hello/IHello:1.0")
  hello = orb:narrow(facet, "IDL:demoidl/hello/IHello:1.0")
  hello:sayHello()
end

oil.main(function()
  print(oil.pcall(main))
end)
