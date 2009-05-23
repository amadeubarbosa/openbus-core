-- $Id$

---
--Inicialização do Serviço de Controle de Acesso
---

local Log = require "openbus.common.Log"
local LDAPLoginPasswordValidator =
    require "core.services.accesscontrol.LDAPLoginPasswordValidator"
local TestLoginPasswordValidator =
    require "core.services.accesscontrol.TestLoginPasswordValidator"

local oil = require "oil"

-- Inicialização do nível de verbose do openbus.
Log:level(1)

local IDLPATH_DIR = os.getenv("IDLPATH_DIR")
if IDLPATH_DIR == nil then
  Log:error("A variavel IDLPATH_DIR nao foi definida.\n")
  os.exit(1)
end

local DATA_DIR = os.getenv("OPENBUS_DATADIR")
if DATA_DIR == nil then
  Log:error("A variavel OPENBUS_DATADIR nao foi definida.\n")
  os.exit(1)
end

-- Obtém a configuração do serviço
assert(loadfile(DATA_DIR.."/conf/AccessControlServerConfiguration.lua"))()

-- Define os níveis de verbose para o OpenBus e para o OiL.
if AccessControlServerConfiguration.logLevel then
  Log:level(AccessControlServerConfiguration.logLevel)
end
if AccessControlServerConfiguration.oilVerboseLevel then
  oil.verbose:level(AccessControlServerConfiguration.oilVerboseLevel)
end

-- Inicializa o ORB, fixando a localização do serviço em uma porta específica
local orb = oil.init { host = AccessControlServerConfiguration.hostName,
                       port = AccessControlServerConfiguration.hostPort,
                       flavor = "intercepted;corba;typed;cooperative;base",
                       tcpoptions = {reuseaddr = true}
                     }

oil.orb = orb

local scs = require "scs.core.base"
local AccessControlService = require "core.services.accesscontrol.AccessControlService"

orb:loadidlfile(IDLPATH_DIR.."/access_control_service.idl")

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
--Função que será executada pelo OiL em modo protegido.
---
function main()
  local success, res = oil.pcall(oil.newthread, orb.run, orb)
  if not success then
    Log:error("Falha na execução do ORB: "..tostring(res).."\n")
    os.exit(1)
  end

  -- Cria o componente responsável pelo Serviço de Controle de Acesso
  acsInst = scs.newComponent(facetDescriptions, receptacleDescriptions, componentId)

  -- Configurações
  acsInst.IComponent.startup = AccessControlService.startup
  
  local acs = acsInst.IAccessControlService
  acs.config = AccessControlServerConfiguration
  acs.entries = {}
  acs.observers = {}
  acs.challenges = {}
  acs.loginPasswordValidators = {LDAPLoginPasswordValidator(acs.config.ldapHosts, acs.config.ldapSuffixes),
    TestLoginPasswordValidator(),
  }

  -- Inicialização
  success, res = oil.pcall(acsInst.IComponent.startup, acsInst.IComponent)
  if not success then
    Log:error("Falha ao iniciar o serviço de controle de acesso: "..
        tostring(res).."\n")
    os.exit(1)
  end
  Log:init("Serviço de controle de acesso iniciado com sucesso")
end

print(oil.pcall(oil.main,main))
