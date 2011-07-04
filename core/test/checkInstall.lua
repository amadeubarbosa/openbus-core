--
-- Teste para verificar se a instala��o do Openbus foi concluida com sucesso
-- $Id: testServices.lua $
--
local oil = require "oil"
local openbus = require "openbus.Openbus"
local format = string.format
local Log = require "openbus.util.Log"
local lpw     = require "lpw"
local Utils = require "openbus.util.Utils"

oil.verbose:level(0)
Log:level(1)

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  io.stderr:write("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end

if #arg < 2 then
   print("[ERRO] Par�metros insuficientes, e necessario um arquivo de configuracao.")
   os.exit(1)
end

if arg[1]:lower():find("help") then
  print(format("Usage: %s <host> <port>", arg[0]))
  return
end

if not tonumber(arg[2]) then
  print(format("[ERRO] Par�metro '%s' deveria ser o valor da porta do barramento.", arg[2]))
  os.exit(1)
end

local host = arg[1]
local port = tonumber(arg[2])

function run()
  openbus:init(host, port)
  local orb = openbus:getORB()
  orb:loadidlfile(IDLPATH_DIR.."/"..Utils.IDL_VERSION.."/session_service.idl")

  io.write("Login: ")
  local login = io.read()
  local password = lpw.getpass("Senha: ")

  local registryService = openbus:connectByLoginPassword(login, password)
  if not registryService then
     print("[ERRO] N�o foi poss�vel se conectar ao barramento.")
     os.exit(1)
  end
  openbus:disconnect()

  registryService = openbus:connectByLoginPassword("tester", "tester")
  if registryService then
    print("[WARN] O usu�rio de testes est� habilitado.")
  else
    print("[INFO] O usu�rio de testes n�o est� habilitado.")
  end

  local sessionServiceInterface = Utils.SESSION_SERVICE_INTERFACE
  local serviceOffers = registryService:find({sessionServiceInterface})

  if #serviceOffers == 0 then
    print("[ERRO] O servi�o de sess�o n�o est� conectado ao barramento.")
    os.exit(1)
  end
  if #serviceOffers > 1 then
    print("[ERRO] Existe mais de um servico de sess�o conectado ao barramento.")
    os.exit(1)
  end
  local sessionServiceComponent =
      orb:narrow(serviceOffers[1].member, "IDL:scs/core/IComponent:1.0")
  local sessionServiceName = Utils.SESSION_SERVICE_FACET_NAME
  sessionService = sessionServiceComponent:getFacetByName(sessionServiceName)
  sessionService = orb:narrow(sessionService, sessionServiceInterface)

  openbus:disconnect()
  openbus:destroy()
end

oil.main(function()
  sucess, err = oil.pcall(run)
  if sucess then
    print("[INFO] Os servi�os do Openbus est�o funcionando perfeitamente")
  else
     print(tostring(err))
  end
end)
