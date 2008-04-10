package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
require "oil"

local CredentialManager = require "openbus.common.CredentialManager"
local ClientInterceptor = require "openbus.common.ClientInterceptor"

local CORBA_IDL_DIR = os.getenv("CORBA_IDL_DIR")
if CORBA_IDL_DIR == nil then
  io.stderr:write("A variavel CORBA_IDL_DIR nao foi definida.\n")
  os.exit(1)
end
local CONF_DIR = os.getenv("CONF_DIR")
local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()

oil.verbose:level(0)

local idlfile = CORBA_IDL_DIR.."/access_control_service.idl"
oil.loadidlfile(idlfile)
idlfile = CORBA_IDL_DIR.."/registry_service.idl"
oil.loadidlfile(idlfile)
idlfile = CORBA_IDL_DIR.."/data_service.idl"
oil.loadidlfile(idlfile)
idlfile = CORBA_IDL_DIR.."/project_service.idl"
oil.loadidlfile(idlfile)

-- Serviço de Acesso
local host = "localhost"
local port = 2089
-- Este deve ser um usuário CSBase.
local user = "tester"
local password = "tester"

function showNodes(nodes, depth, dataService)
  local prefix = ""
  for i=1, ((depth * 2) - 1) do
    prefix = prefix.."-"
  end
  prefix = prefix.." "
  local projectKey
  for i=1, #nodes do
    local node = nodes[i]
    io.stdout:write(prefix..node.key.." [")
    local prefix = ""
    for j=1, #node.properties do
      if node.properties[j].name == "type" and
          node.properties[j].value == "PROJECT" then
        projectKey = node.key
      end
      io.stdout:write(prefix..node.properties[j].name.." = "..
          node.properties[j].value)
      prefix = ", "
    end
    io.stdout:write("]\n")
    showNodes(dataService:getChildren(node.key), depth + 1, dataService)
  end
  if projectKey then
    local projectComponent = dataService:getComponent(projectKey)
    projectComponent:startup()
    local project = projectComponent:getFacetByName("Project")
    project = oil.narrow(project, "IDL:openbusidl/ps/IProject:1.0")
    print(project:getName())
    projectComponent:shutdown()
  end
end

function main()
  local accessControlServiceInterface = "IDL:openbusidl/acs/IAccessControlService:1.0"
  local accessControlService = oil.newproxy("corbaloc::"..host..":"..port.."/ACS", accessControlServiceInterface)
  accessControlService = oil.narrow(accessControlService, accessControlServiceInterface)

  -- instala o interceptador de cliente
  local credentialManager= CredentialManager()
  oil.setclientinterceptor(ClientInterceptor(config, credentialManager))

  local credential
  _, credential = accessControlService:loginByPassword(user, password)
  credentialManager:setValue(credential)

  local registryService= accessControlService:getRegistryService()

  local serviceOffers = registryService:find("ProjectService", {})

  if #serviceOffers == 0 then
    print("Serviço de projetos não registrado!!!")
  else
    local serviceOffer = serviceOffers[1]
    print(serviceOffer.description)
    local dataServiceInterface = "IDL:openbusidl/ds/IDataService:1.0"
    local dataService = serviceOffer.member:getFacet(dataServiceInterface)
    dataService = oil.narrow(dataService, dataServiceInterface)
    showNodes(dataService:getRoots(), 1, dataService)
  end
  accessControlService:logout(credential)
end

print(oil.pcall(oil.main,main))
