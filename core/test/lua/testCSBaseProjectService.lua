--
-- Teste de integração do Serviço de Projetos do CSBase.
--
-- $Id$
--
require "oil"
oil.orb = oil.init {flavor = "intercepted;corba;csockets;typed;cooperative;base"}
local orb = oil.orb

require "ftc"

local CredentialManager = require "openbus.util.CredentialManager"
local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  io.stderr:write("A variável IDLPATH_DIR não foi definida.\n")
  os.exit(1)
end
local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  io.stderr:write("A variável IDLPATH_DIR não foi definida.\n")
  os.exit(1)
end

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
local config = assert(loadfile(DATA_DIR.."/conf/advanced/InterceptorsConfiguration.lua"))()

oil.verbose:level(0)

local actualDataId = arg[1]
print("ID: ", actualDataId)

local idlfile = IDLPATH_DIR.."/access_control_service.idl"
orb:loadidlfile(idlfile)
idlfile = IDLPATH_DIR.."/registry_service.idl"
orb:loadidlfile(idlfile)
idlfile = IDLPATH_DIR.."/project_service.idl"
orb:loadidlfile(idlfile)

-- Serviço de Acesso
local host = "localhost"
local port = 2089
-- Este deve ser um usuário CSBase.
local user = "tester"
local password = "tester"

function main()
  local accessControlServiceInterface = "IDL:openbusidl/acs/IAccessControlService:1.0"
  local accessControlService = orb:newproxy("corbaloc::"..host..":"..port.."/ACS", accessControlServiceInterface)
  accessControlService = orb:narrow(accessControlService, accessControlServiceInterface)

  -- instala o interceptador de cliente
  local credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config, credentialManager))

  local credential
  _, credential = accessControlService:loginByPassword(user, password)
  credentialManager:setValue(credential)

  local registryService = accessControlService:getRegistryService()

  local serviceOffers = registryService:find({
    {name = "facets", value = {"projectDataService"}}
  })
  if #serviceOffers == 0 then
    print("Serviço de projetos não registrado!!!")
  else
    local serviceOffer = serviceOffers[1]
    local dataServiceInterface = "IDL:openbusidl/ds/IDataService:1.0"
    local dataService = serviceOffer.member:getFacet(dataServiceInterface)
    dataService = orb:narrow(dataService, dataServiceInterface)
    if actualDataId then
      local dataKey = {
        service_id = serviceOffer.member:getComponentId(),
        actual_data_id = actualDataId
      }
      local facetInterface = dataService:getFacetInterfaces(dataKey)
      if #facetInterface > 0 then
        local projectInterface = "IDL:openbusidl/ps/IProject:1.0"
        if facetInterface[1] == projectInterface then
          local project = dataService:getDataFacet(dataKey, projectInterface)
          if project then
            print(project:getFacetInterface())
            print((project:getAttr("NAME"))._anyval)
          end
        else
          local fileInterface = "IDL:openbusidl/ps/IFile:1.0"
          local data = dataService:getDataFacet(dataKey, fileInterface)
          if data then
            print(data:getFacetInterface())
            print((data:getAttr("NAME"))._anyval)
            print((data:getAttr("ABSOLUTE_PATH"))._anyval)
            print((data:getAttr("TYPE"))._anyval)
            local file = orb:narrow(data, fileInterface)
            if file:isDirectory() then
              file:createFile("teste","")
              local files = file:getFiles()
              for k, v in pairs(files) do
                if type(v) == "table" then
                  print(k, v:getName())
                end
              end
              print(dataService:deleteData(file:getKey()))
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
          end
        end
      else
        print("O "..actualDataId.." não foi encontrado.")
      end
    end
  end
  accessControlService:logout(credential)
end

print(oil.pcall(oil.main,main))
