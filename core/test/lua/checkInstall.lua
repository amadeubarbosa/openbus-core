--
-- Teste para verificar se a instalação do Openbus foi concluida com sucesso
-- $Id: testServices.lua $
--
require "oil"
local orb = oil.init {flavor = "intercepted;corba;typed;cooperative;base",}
oil.orb = orb

oil.verbose:level(0)

local ClientInterceptor = require "openbus.interceptors.ClientInterceptor"
local CredentialManager = require "openbus.util.CredentialManager"
local Utils = require "openbus.util.Utils"

if #arg < 1 then
   print("[ERRO] Parametros insuficientes, e necessario um arquivo de configuracao.")
   os.exit(1)
end

local f, err = loadfile(arg[1])
if not f then
   print("[ERRO] Ao abrir o arquivo.")
   os.exit(1)
end
f()

local host = props.host
local port = props.port
local user = props.user
local password = props.password

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end

function run()
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_VERSION.."/session_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_VERSION.."/registry_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_VERSION..
      "/access_control_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_PREV.."/session_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_PREV.."/registry_service.idl")
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.OB_PREV..
      "/access_control_service.idl")


  accessControlService = orb:newproxy("corbaloc::" .. 
      host .. ":" .. port .. 
      "/ACS", 
      "synchronous",
      "IDL:tecgraf/openbus/core/"..Utils.OB_VERSION..
          "/access_control_service/IAccessControlService:1.0")

  -- instala o interceptador de cliente
  local DATA_DIR = os.getenv("OPENBUS_DATADIR")
  local config = assert(loadfile(DATA_DIR ..
      "/conf/advanced/InterceptorsConfiguration.lua"))()
  credentialManager = CredentialManager()
  orb:setclientinterceptor(ClientInterceptor(config, credentialManager))


  -- Testando se o usuário de teste está habilitado
  success, credential = accessControlService:loginByPassword("tester", "tester")
  if success then
     print("[ERRO] O usuario de testes esta habilitado.")
  end

  success, credential = accessControlService:loginByPassword(user, password)
  if not success then
     print("[ERRO] O usuario ou a senha passada nao sao validos.")
     os.exit(1)
  end

  credentialManager:setValue(credential)

  local acsIComp = self.accessControlService:_component()
  acsIComp = orb:narrow(acsIComp, "IDL:scs/core/IComponent:1.0")
  local acsIRecept = acsIComp:getFacetByName("IReceptacles")
  acsIRecept = orb:narrow(acsIRecept, "IDL:scs/core/IReceptacles:1.0")
  local conns = acsIRecept:getConnections("RegistryServiceReceptacle")
  if not conns[1] then
     print("[ERRO] O servico de registro nao esta conectado ao barramento.")
     os.exit(1)
  end 
  local rsIComp = orb:narrow(conns[1].objref, "IDL:scs/core/IComponent:1.0")
  local registryService = rsIComp:getFacetByName("IRegistryService_" .. Utils.OB_VERSION)
  registryService = orb:narrow(registryService,
    "IDL:tecgraf/openbus/core/"..Utils.OB_VERSION..
        "/registry_service/IRegistryService:1.0")
  local serviceOffers = registryService:find({"ISessionService_" .. Utils.OB_VERSION})
  
  if #serviceOffers == 0 then
    print("[ERRO] O servico de sessao nao esta conectado ao barramento.")
    os.exit(1)
  end
  local sessionServiceComponent = orb:narrow(serviceOffers[1].member, "IDL:scs/core/IComponent:1.0")
  local sessionServiceInterface = "IDL:tecgraf/openbus/session_service/"..
      Utils.OB_VERSION"/ISessionService:1.0"
  sessionService = sessionServiceComponent:getFacet(sessionServiceInterface)
  sessionService = orb:narrow(sessionService, sessionServiceInterface)
end

oil.main(function()
  sucess, err = oil.pcall(run)
  if sucess then 
    print("[INFO] Os servicos do Openbus estao funcionando perfeitamente") 
  else
     print(err)
  end
end)
