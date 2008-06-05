--
-- Teste de integração do Serviço de Projetos do CSBase.
--
-- $Id$
--
package.loaded["oil.component"] = require "loop.component.wrapped"
package.loaded["oil.port"]      = require "loop.component.intercepted"
require "oil"
require "ftc"

local CredentialManager = require "openbus.common.CredentialManager"
local ClientInterceptor = require "openbus.common.ClientInterceptor"

local CORE_IDL_DIR = os.getenv("CORE_IDL_DIR")
if CORE_IDL_DIR == nil then
  io.stderr:write("A variável CORE_IDL_DIR não foi definida.\n")
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

local projectPath = arg[1]
print("Chave", projectPath)

local idlfile = CORE_IDL_DIR.."/access_control_service.idl"
oil.loadidlfile(idlfile)
idlfile = CORE_IDL_DIR.."/registry_service.idl"
oil.loadidlfile(idlfile)
idlfile = IDLPATH_DIR.."/project_service.idl"
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
    if projectPath then
      local file = projectService:getFile(projectPath)
      if file then
        print(file:getName())
        if file:isDirectory() then
          file:createFile("teste","")
          file = projectService:getFile(projectPath)
          local files = file:getFiles()
          for k, v in pairs(files) do
            if type(v) == "table" then
              print(k, v:getName())
            end
          end
        else
          local dataChannel = file:getDataChannel()
          if dataChannel then
            print(dataChannel.host, dataChannel.port, dataChannel.fileIdentifier)
            local ftc = ftc(dataChannel.fileIdentifier, dataChannel.writable, dataChannel.fileSize, dataChannel.host, dataChannel.port, dataChannel.accessKey)
            print(ftc:open(false))
            local _, size = ftc:getSize()
            print("Tamanho do arquivo: "..size.." byte(s).")
            print(ftc:read(size, 0))
            print(ftc:truncate(0))
            _, size = ftc:getSize()
            print("Tamanho do arquivo: "..size.." byte(s).")
            print(ftc:write(10, 0, "1234567890"))
            ftc:close()
          end
        end
      else
        print("O arquivo "..projectPath.." não foi encontrado.")
      end
    end
  end
  accessControlService:logout(credential)
end

print(oil.pcall(oil.main,main))
