-------------------------------------------------------------------------------
-- Demo de eventos do Serviço de Sessão
-- server.lua
--

local oo      = require "loop.base"
local utils   = require ("scs.core.utils").Utils()
local oil     = require "oil"
local openbus = require "openbus.Openbus"

--oil.verbose:level(5)

-- Carrega as propriedades
local props = {}
utils:readProperties(props, "HelloSession.properties")
-- Aliases
local host               = props["host.name"].value
local port               = tonumber(props["host.port"].value)
local entityName         = props["entity.name"].value
local privateKeyFile     = props["private.key"].value
local acsCertificateFile = props["acs.certificate"].value

-- Inicialização
openbus:resetAndInitialize(host, port)
-- ORB deve estar inicializado antes de carregar o SCS
local scs = require "scs.core.base"

-- Auxiliares
local orb = openbus:getORB()
local compFacet = "IDL:scs/core/IComponent:1.0"
local sinkFacet = "IDL:openbusidl/ss/SessionEventSink:1.0"
local context

-------------------------------------------------------------------------------
-- Descrições do componente
local facetDescriptions = {}

facetDescriptions.IComponent = {
  name = "IComponent",
  interface_name = "IDL:scs/core/IComponent:1.0",
  class = scs.Component
}

facetDescriptions.IMetaInterface = {
  name = "IMetaInterface",
  interface_name = "IDL:scs/core/IMetaInterface:1.0",
  class = scs.MetaInterface
}

local componentId = {
  name = "HelloSource",
  major_version = 1,
  minor_version = 0,
  patch_version = 0,
  platform_spec = ""
}

-------------------------------------------------------------------------------
-- Publica os eventos no canal
--
local function publish(session, sink)
  while true do
    oil.sleep(3)
    local num = math.random(1, 10)
    print("Publicando: " .. num)
    local event = {}
    event.type = "LongEvent"
    event.value = setmetatable({ _anyval = num }, oil.corba.idl.long)
    sink:push(event)
  end
end

-- Função principal
local function main ()
  -- Permite que o ORB comece a aguardar requisições
  openbus:run()
  -- Instanciação do componente
  context = scs.newComponent(facetDescriptions, {}, componentId)
  -- Conexão com o barramento
  local registryService = openbus:connectByCertificate(entityName,
    privateKeyFile, acsCertificateFile)
  if not registryService then
    io.stderr:write("[ERRO] Não foi possível conectar ao barramento.\n")
    os.exit(1)
  end
  -- Cria a sessão
  local session, sessionId
  local sessionService = openbus:getSessionService()
  succ, session, sessionId = sessionService:createSession(context.IComponent)
  if not succ then
    io.stderr:write("[ERRO] Não foi possível criar sessão.\n")
    openbus.disconnect()
    os.exit(1)
  end
  -- Recupera serviço de eventos
  local comp = orb:narrow(session:_component(), compFacet)
  local sink = orb:narrow(comp:getFacet(sinkFacet), sinkFacet)
  -- Registro do componente
  local succ, registryId = registryService:register{
    --properties = {}, 
    properties = { {name = "sessionName", value = {"HelloSession"}} },
    member = comp,
  }
  if not succ then
    io.stderr:write("[ERRO] Não foi possível registrar a oferta.\n")
    openbus:disconnect()
    os.exit(1)
  end
  -- Publica os eventos
  oil.newthread(publish, session, sink)
  print("[INFO] Publisher ativado.")
end

oil.main(function()
  local succ, msg = oil.pcall(main)
  if not succ then
    print(msg)
  end
end)
