--
-- Teste de integração do Serviço de Dados do CSBase.
--
-- $Id$
--
package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
require "oil"

local CredentialManager = require "openbus.common.CredentialManager"
local ClientInterceptor = require "openbus.common.ClientInterceptor"

local CORE_IDL_DIR = os.getenv("CORE_IDL_DIR")
if CORE_IDL_DIR == nil then
  io.stderr:write("A variavel CORE_IDL_DIR nao foi definida.\n")
  os.exit(1)
end
local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  io.stderr:write("A variável IDLPATH_DIR não foi definida.\n")
  os.exit(1)
end

local CONF_DIR = os.getenv("CONF_DIR")
local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()

oil.verbose:level(0)

local idlfile = CORE_IDL_DIR.."/access_control_service.idl"
oil.loadidlfile(idlfile)
idlfile = CORE_IDL_DIR.."/registry_service.idl"
oil.loadidlfile(idlfile)
idlfile = CORE_IDL_DIR.."/data_service.idl"
oil.loadidlfile(idlfile)
idlfile = IDLPATH_DIR.."/project_service.idl"
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
    io.stdout:write(prefix..node.key.actual_data_id.." [")
    for j=1, #node.metadata do
      io.stdout:write("\n"..node.metadata[j].name.." = "..
          node.metadata[j].value)
    end
    local interfaces = dataService:getFacetInterfaces(node.key)
    for j=1, #interfaces do
      io.stdout:write("\nINTERFACE = "..interfaces[j])
    end
    io.stdout:write("\n]\n")
    showNodes(dataService:getChildren(node.key), depth + 1, dataService)
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
