-- $Id$

local _G = require "_G"
local assert = _G.assert
local ipairs = _G.ipairs
local require = _G.require
local select = _G.select

local io = require "io"
local stderr = io.stderr

local os = require "os"
local getenv = os.getenv

local table = require "loop.table"
local copy = table.copy

local cothread = require "cothread"
local running = cothread.running

local oil = require "oil"
local oillog = require "oil.verbose"

local log = require "openbus.util.logger"
local database = require "openbus.util.database"
local opendb = database.open
local server = require "openbus.util.server"
local ConfigArgs = server.ConfigArgs
local newSCS = server.newSCS
local setuplog = server.setuplog
local readfilecontents = server.readfilecontents
local readprivatekey = server.readprivatekey

local idl = require "openbus.core.idl"
local const = idl.const
local access = require "openbus.core.services.Access"

local msg = require "openbus.core.services.messages"
local AccessControl = require "openbus.core.services.AccessControl"
local OfferRegistry = require "openbus.core.services.OfferRegistry"

return function(...)
  log.viewer.labels[running()] = "busservices"
  
  -- configuration parameters parser
  local Configs = ConfigArgs{
    host = "*",
    port = 2089,
  
    database = "openbus.db",
    privatekey = "openbus.key",
  
    leasetime = 30*60,
    expirationgap = 10,
  
    admin = {},
    validator = {},
  
    loglevel = 3,
    logfile = "",
    oilloglevel = 0,
    oillogfile = "",
    
    noauthorizations = false,
    nolegacy = false,
  }

  -- parse configuration file
  Configs:configs("configs", getenv("OPENBUS_CONFIG") or "openbus.cfg")

  -- parse command line parameters
  do
    io.write(msg.CopyrightNotice, "\n")
    local argidx, errmsg = Configs(...)
    if not argidx or argidx <= select("#", ...) then
      if errmsg ~= nil then
        stderr:write(errmsg,"\n")
      end
      stderr:write([[
Usage:  ]],OPENBUS_PROGNAME,[[ [options]
Options:

  -host <address>            endereço de rede usado pelo barramento
  -port <number>             número da porta usada pelo barramento

  -database <path>           arquivo de dados do barramento
  -privatekey <path>         arquivo com chave privada do barramento

  -leasetime <seconds>       tempo de lease dos logins de acesso
  -expirationgap <seconds>   tempo que os logins ficam válidas após o lease

  -admin <user>              usuário com privilégio de administração
  -validator <name>          nome de pacote de validação de login

  -loglevel <number>         nível de log gerado pelo barramento
  -logfile <path>            arquivo de log gerado pelo barramento
  -oilloglevel <number>      nível de log gerado pelo OiL (debug)
  -oillogfile <path>         arquivo de log gerado pelo OiL (debug)

  -noauthorizations          desativa o suporte a autorizações de oferta
  -nolegacy                  desativa o suporte à versão antiga do barramento

  -configs <path>            arquivo de configurações adicionais do barramento
  
]])
      return 1 -- program's exit code
    end
  end

  -- setup log files
  setuplog(log, Configs.loglevel, Configs.logfile)
  setuplog(oillog, Configs.oilloglevel, Configs.oillogfile)
  log:version(msg.CopyrightNotice)

  -- validate time parameters
  assert(Configs.leasetime > 0 and Configs.leasetime%1 == 0,
    msg.InvalidLeaseTime:tag{value=Configs.leasetime})
  assert(Configs.expirationgap > 0,
    msg.InvalidExpirationGap:tag{value=Configs.expirationgap})
  
  -- create a set of admin users
  local adminUsers = {}
  for _, admin in ipairs(Configs.admin) do
    adminUsers[admin] = true
    log:config(msg.AdministrativeRightsGranted:tag{entity=admin})
  end
  
  -- load all password validators to be used
  local validators = {}
  for index, package in ipairs(Configs.validator) do
    validators[#validators+1] = {
      name = package,
      validate = assert(require(package)(Configs)),
    }
    log:config(msg.PasswordValidatorLoaded:tag{name=package})
  end
  assert(#validators>0, msg.NoPasswordValidators)

  -- setup bus access
  local orb = access.initORB{ host=Configs.host, port=Configs.port }
  local legacy
  if not Configs.nolegacy then
    local legacyIDL = require "openbus.core.legacy.idl"
    legacyIDL.loadto(orb)
    local ACS = require "openbus.core.legacy.AccessControlService"
    legacy = ACS.IAccessControlService
  end
  local iceptor = access.Interceptor{
    prvkey = assert(readprivatekey(Configs.privatekey)),
    orb = orb,
    legacy = legacy,
  }
  orb:setinterceptor(iceptor, "corba")
  
  -- create SCS component
  local facets = {}
  copy(AccessControl, facets)
  copy(OfferRegistry, facets)
  newSCS{
    orb = orb,
    objkey = const.BusObjectKey,
    name = const.BusObjectKey,
    facets = facets,
    init = function()
      local params = {
        access = iceptor,
        database = assert(opendb(Configs.database)),
        leaseTime = Configs.leasetime,
        expirationGap = Configs.expirationgap,
        admins = adminUsers,
        validators = validators,
        enforceAuth = not Configs.noauthorizations,
      }
      log:config(msg.LoadedBusDatabase:tag{path=Configs.database})
      log:config(msg.LoadedBusPrivateKey:tag{path=Configs.privatekey})
      log:config(msg.SetupLoginLeaseTime:tag{value=params.leaseTime})
      log:config(msg.SetupLoginExpirationGap:tag{value=params.expirationGap})
      if not params.enforceAuth then
        log:config(msg.OfferAuthorizationDisabled)
      end
      -- these object must be initialized in this order
      facets.CertificateRegistry:__init(params)
      facets.AccessControl:__init(params)
      facets.LoginRegistry:__init(params)
      facets.InterfaceRegistry:__init(params)
      facets.EntityRegistry:__init(params)
      facets.OfferRegistry:__init(params)
    end,
  }
  
  -- create legacy SCS components
  if not Configs.nolegacy then
    local AccessControlService = require "openbus.core.legacy.AccessControlService"
    local ACS = newSCS{
      orb = orb,
      objkey = "openbus_v1_05",
      name = "AccessControlService",
      facets = AccessControlService,
      receptacles = {RegistryServiceReceptacle="IDL:scs/core/IComponent:1.0"},
      init = function()
        AccessControlService.IAccessControlService:__init{
          access = iceptor,
          admins = adminUsers,
        }
      end,
    }
    local RegistryService = require "openbus.core.legacy.RegistryService"
    local RGS = newSCS{
      orb = orb,
      objkey = "IC",
      name = "RegistryService",
      facets = RegistryService,
    }
    ACS.IReceptacles:connect("RegistryServiceReceptacle", RGS.IComponent)
    log:config(msg.LegacySupportEnabled)
  end

  -- start ORB
  log:uptime(msg.CoreServicesStarted)
  orb:run()
end
