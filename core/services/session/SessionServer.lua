-----------------------------------------------------------------------------
-- Inicialização do Serviço de Sessão
--
-- Última alteração:
--   $Id$
-----------------------------------------------------------------------------
local oil = require "oil"
local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"

-- Inicialização do nível de verbose do openbus.
Log:level(1)

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/SessionServerConfiguration.lua"))()
local iConfig =
  assert(loadfile(DATA_DIR.."/conf/advanced/SSInterceptorsConfiguration.lua"))()

-- Seta os níveis de verbose para o openbus e para o oil
if SessionServerConfiguration.logLevel then
  Log:level(SessionServerConfiguration.logLevel)
end
if SessionServerConfiguration.oilVerboseLevel then
  oil.verbose:level(SessionServerConfiguration.oilVerboseLevel)
end

-- Inicializa o barramento
Openbus:resetAndInitialize(
  SessionServerConfiguration.accessControlServerHostName,
  SessionServerConfiguration.accessControlServerHostPort,
  nil, iConfig, iConfig)
local orb = Openbus:getORB()

local scs = require "scs.core.base"
local SessionServiceComponent =
  require "core.services.session.SessionServiceComponent"
local SessionService = require "core.services.session.SessionService"

-----------------------------------------------------------------------------
-- Descricoes do Componente Servico de Sessao
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent          = {}
facetDescriptions.IMetaInterface      = {}
facetDescriptions.ISessionService     = {}
facetDescriptions.ICredentialObserver = {}

facetDescriptions.IComponent.name                    = "IComponent"
facetDescriptions.IComponent.interface_name          = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                   = SessionServiceComponent.SessionServiceComponent

facetDescriptions.IMetaInterface.name                = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name      = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class               = scs.MetaInterface

facetDescriptions.ISessionService.name               = "ISessionService"
facetDescriptions.ISessionService.interface_name     = "IDL:openbusidl/ss/ISessionService:1.0"
facetDescriptions.ISessionService.class              = SessionService.SessionService

facetDescriptions.ICredentialObserver.name           = "SessionServiceCredentialObserver"
facetDescriptions.ICredentialObserver.interface_name = "IDL:openbusidl/acs/ICredentialObserver:1.0"
facetDescriptions.ICredentialObserver.class          = SessionService.Observer

-- Receptacle Descriptions
local receptacleDescs = {}
receptacleDescs.AccessControlServiceReceptacle = {}
receptacleDescs.AccessControlServiceReceptacle.name           = "AccessControlServiceReceptacle"
receptacleDescs.AccessControlServiceReceptacle.interface_name =  "IDL:openbusidl/acs/IAccessControlService:1.0"
receptacleDescs.AccessControlServiceReceptacle.is_multiplex   = false

-- component id
local componentId = {}
componentId.name = "SessionService"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  -- Cria o componente responsável pelo Serviço de Sessão
  success, res = oil.pcall(scs.newComponent, facetDescriptions, receptacleDescs,
      componentId)
  if not success then
    Log:error("Falha criando componente: "..tostring(res).."\n")
    os.exit(1)
  end
  res.IComponent.config = SessionServerConfiguration
  local sessionServiceComponent = res.IComponent
  success, res = oil.pcall(sessionServiceComponent.startup,
      sessionServiceComponent)
  if not success then
    Log:error("Falha ao iniciar o serviço de sessão: "..tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Serviço de sessão iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
