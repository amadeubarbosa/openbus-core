-- $Id$

---
--Inicializa��o do Servi�o de Controle de Acesso
---

-- Inclu�ndo mecanismo para identificar descritores abertos
local socket = require "socket.core"
require "fileleak"
io.open = fileleak.wrapfactory(io.open)
socket.tcp = fileleak.wrapfactory(socket.tcp)
socket.udp = fileleak.wrapfactory(socket.udp)
-- Fim do mecanismo


local oil = require "oil"
local Openbus = require "openbus.Openbus"
local Log = require "openbus.util.Log"
local LDAPLoginPasswordValidator =
    require "core.services.accesscontrol.LDAPLoginPasswordValidator"
local TestLoginPasswordValidator =
    require "core.services.accesscontrol.TestLoginPasswordValidator"

-- Inicializa��o do n�vel de verbose do openbus.
Log:level(1)

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obt�m a configura��o do servi�o
assert(loadfile(DATA_DIR.."/conf/AccessControlServerConfiguration.lua"))()
local iconfig = assert(loadfile(DATA_DIR ..
  "/conf/advanced/ACSInterceptorsConfiguration.lua"))()

-- Define os n�veis de verbose para o OpenBus e para o OiL.
if AccessControlServerConfiguration.logLevel then
  Log:level(AccessControlServerConfiguration.logLevel)
end
if AccessControlServerConfiguration.oilVerboseLevel then
  oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
end
local props = { host = AccessControlServerConfiguration.hostName,
  port = AccessControlServerConfiguration.hostPort}

-- Inicializa o barramento
Openbus:resetAndInitialize( AccessControlServerConfiguration.hostName,
  AccessControlServerConfiguration.hostPort, props, iconfig)
local orb = Openbus:getORB()

local scs = require "scs.core.base"
local AccessControlService = require "core.services.accesscontrol.AccessControlService"

-----------------------------------------------------------------------------
-- AccessControlService Descriptions
-----------------------------------------------------------------------------

-- Facet Descriptions
local facetDescriptions = {}
facetDescriptions.IComponent          	= {}
facetDescriptions.IMetaInterface      	= {}
facetDescriptions.IAccessControlService = {}
facetDescriptions.ILeaseProvider       	= {}

facetDescriptions.IComponent.name                     = "IComponent"
facetDescriptions.IComponent.interface_name           = "IDL:scs/core/IComponent:1.0"
facetDescriptions.IComponent.class                    = scs.Component
facetDescriptions.IComponent.key                      = "IC"

facetDescriptions.IMetaInterface.name                 = "IMetaInterface"
facetDescriptions.IMetaInterface.interface_name       = "IDL:scs/core/IMetaInterface:1.0"
facetDescriptions.IMetaInterface.class                = scs.MetaInterface

facetDescriptions.IAccessControlService.name            = "IAccessControlService"
facetDescriptions.IAccessControlService.interface_name  = "IDL:openbusidl/acs/IAccessControlService:1.0"
facetDescriptions.IAccessControlService.class           = AccessControlService.ACSFacet
facetDescriptions.IAccessControlService.key             = "ACS"

facetDescriptions.ILeaseProvider.name                  = "ILeaseProvider"
facetDescriptions.ILeaseProvider.interface_name        = "IDL:openbusidl/acs/ILeaseProvider:1.0"
facetDescriptions.ILeaseProvider.class                 = AccessControlService.LeaseProviderFacet
facetDescriptions.ILeaseProvider.key                   = "LP"

-- Receptacle Descriptions
local receptacleDescriptions = {}

-- component id
local componentId = {}
componentId.name = "AccessControlService"
componentId.major_version = 1
componentId.minor_version = 0
componentId.patch_version = 0
componentId.platform_spec = ""

---
--Fun��o que ser� executada pelo OiL em modo protegido.
---
function main()
  -- Aloca uma thread do OiL para o orb
  Openbus:run()

  -- Cria o componente respons�vel pelo Servi�o de Controle de Acesso
  acsInst = scs.newComponent(facetDescriptions, receptacleDescriptions, componentId)

  -- Configura��es
  acsInst.IComponent.startup = AccessControlService.startup

  local acs = acsInst.IAccessControlService
  acs.config = AccessControlServerConfiguration
  acs.entries = {}
  acs.observers = {}
  acs.challenges = {}
  acs.loginPasswordValidators = {LDAPLoginPasswordValidator(acs.config.ldapHosts, acs.config.ldapSuffixes),
    TestLoginPasswordValidator(),
  }

  -- Inicializa��o
  success, res = oil.pcall(acsInst.IComponent.startup, acsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o servi�o de controle de acesso: "..
        tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Servi�o de controle de acesso iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
fileleak.showstats()
