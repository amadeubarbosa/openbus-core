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
local CONF_DIR = os.getenv("CONF_DIR")
local config = assert(loadfile(CONF_DIR.."/advanced/InterceptorsConfiguration.lua"))()

oil.verbose:level(0)

local key = arg[1]
print("Chave", key)

local idlfile = CORE_IDL_DIR.."/access_control_service.idl"
oil.loadidlfile(idlfile)
idlfile = CORE_IDL_DIR.."/registry_service.idl"
oil.loadidlfile(idlfile)
idlfile = CORE_IDL_DIR.."/project_service.idl"
oil.loadidlfile(idlfile)

-- Serviço de Acesso
local host = "localhost"
local port = 2089
-- Este deve ser um usuário CSBase.
local user = "tester"
local password = "tester"

function main()
  local accessControlServiceInterface = "IDL:openbusidl/acs/IAccessControlService:1.0"
  local accessControlService = oil.newproxy("corbaloc::"..host..":"..port.."/ACS", accessControlServiceInterface)
  accessControlService = oil.narrow(accessControlService, accessControlServiceInterface)

  -- instala o interceptador de cliente
  local credentialManager = CredentialManager()
  oil.setclientinterceptor(ClientInterceptor(config, credentialManager))

  local credential
  _, credential = accessControlService:loginByPassword(user, password)
  credentialManager:setValue(credential)

  local registryService = accessControlService:getRegistryService()

  local serviceOffers = registryService:find("ProjectService", {})
  if #serviceOffers == 0 then
    print("Serviço de projetos não registrado!!!")
  else
    local serviceOffer = serviceOffers[1]
    print(serviceOffer.description)
    local projectServiceInterface = "IDL:openbusidl/ps/IProjectService:1.0"
    local projectService = serviceOffer.member:getFacet(projectServiceInterface)
    projectService = oil.narrow(projectService, projectServiceInterface)
    local projects = projectService:getProjects()
    for _, project in ipairs(projects) do
      print(project:getName())
      project:close()
    end
    if key then
      local file = projectService:getFile(key)
      print(file:getName())
      -- print(file:getSize())
      file:close()
    end
  end
  accessControlService:logout(credential)
end

print(oil.pcall(oil.main,main))
