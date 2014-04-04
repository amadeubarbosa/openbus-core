-- $Id$

local _G = require "_G"
local assert = _G.assert
local ipairs = _G.ipairs
local require = _G.require
local select = _G.select
local setmetatable = _G.setmetatable

local io = require "string"
local format = io.format

local math = require "math"
local inf = math.huge

local io = require "io"
local stderr = io.stderr

local os = require "os"
local getenv = os.getenv

local table = require "loop.table"
local copy = table.copy
local memoize = table.memoize

local cothread = require "cothread"
local running = cothread.running

local oillog = require "oil.verbose"

local log = require "openbus.util.logger"
local database = require "openbus.util.database"
local opendb = database.open
local server = require "openbus.util.server"
local ConfigArgs = server.ConfigArgs
local newSCS = server.newSCS
local setuplog = server.setuplog
local readprivatekey = server.readprivatekey

local idl = require "openbus.core.idl"
local BusObjectKey = idl.const.BusObjectKey
local mngidl = require "openbus.core.admin.idl"
local loadidl = mngidl.loadto
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
  
    passwordpenalty = 3*60,
    passwordtries = 3,
    validationburst = inf,
    validationrate = inf,
  
    admin = {},
    validator = {},
  
    loglevel = 3,
    logfile = "",
    oilloglevel = 0,
    oillogfile = "",
    
    noauthorizations = false,
    nolegacy = false,
    logaddress = false,
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

  -host <address>            endere�o de rede usado pelo barramento
  -port <number>             n�mero da porta usada pelo barramento

  -database <path>           arquivo de dados do barramento
  -privatekey <path>         arquivo com chave privada do barramento

  -leasetime <seconds>       tempo de lease dos logins de acesso
  -expirationgap <seconds>   tempo que os logins ficam v�lidas ap�s o lease

  -passwordpenalty <seconds> per�odo com tentativas de login limitadas ap�s falha de senha
  -passwordtries <number>    n�mero de tentativas durante o per�odo de 'passwordpenalty'
  -validationburst <number>  n�mero m�ximo de valida��es de senha simult�neas
  -validationrate <number>   frequ�ncia m�xima de valida��es de senha (valida��o/segundo)

  -admin <user>              usu�rio com privil�gio de administra��o
  -validator <name>          nome de pacote de valida��o de login

  -loglevel <number>         n�vel de log gerado pelo barramento
  -logfile <path>            arquivo de log gerado pelo barramento
  -oilloglevel <number>      n�vel de log gerado pelo OiL (debug)
  -oillogfile <path>         arquivo de log gerado pelo OiL (debug)

  -noauthorizations          desativa o suporte a autoriza��es de oferta
  -nolegacy                  desativa o suporte � vers�o antiga do barramento
  -logaddress                exibe o endere�o IP do requisitante no log do barramento

  -configs <path>            arquivo de configura��es adicionais do barramento
  
]])
      return 1 -- program's exit code
    end
  end

  local logaddress = Configs.logaddress and {}
  if logaddress then
    local function writeCallerAddress(verbose)
      local viewer = verbose.viewer
      local output = viewer.output
      local address = logaddress[running()]
      if address == nil then
        output:write("                      ")
      else
        output:write(format("%15s:%5d ", address.host, address.port))
      end
      return true
    end
    local backup = log.custom
    log.custom = memoize(function(tag)
      local custom = backup[tag]
      if custom ~= nil then
        return function (self, ...)
          writeCallerAddress(self)
          return custom(self, ...)
        end
      end
      return writeCallerAddress
    end)
  end

  -- setup log files
  setuplog(log, Configs.loglevel, Configs.logfile)
  log:version(msg.CopyrightNotice)
  log:config(msg.CoreServicesLogLevel:tag{value=Configs.loglevel})
  setuplog(oillog, Configs.oilloglevel, Configs.oillogfile)
  log:config(msg.OilLogLevel:tag{value=Configs.oilloglevel})

  -- validate time parameters
  assert(Configs.leasetime > 0 and Configs.leasetime%1 == 0,
    msg.InvalidLeaseTime:tag{value=Configs.leasetime})
  assert(Configs.expirationgap > 0,
    msg.InvalidExpirationGap:tag{value=Configs.expirationgap})
  assert(Configs.passwordpenalty >= 0,
    msg.InvalidPasswordPenaltyTime:tag{value=Configs.passwordpenalty})
  assert(Configs.passwordtries > 0 and Configs.passwordtries%1 == 0,
    msg.InvalidNumberOfPasswordLimitedTries:tag{value=Configs.passwordtries})
  assert((Configs.validationburst ~= inf) == (Configs.validationrate ~= inf),
    msg.MissingPasswordValidationParameter:tag{
      missing = (Configs.validationburst == inf)
                and "validationburst"
                or "validationrate"
    })
  assert(Configs.validationburst >= 1,
    msg.InvalidPasswordValidationLimit:tag{value=Configs.validationburst})
  assert(Configs.validationrate > 0,
    msg.InvalidPasswordValidationRate:tag{value=Configs.validationrate})
  
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
  local address = { host=Configs.host, port=Configs.port }
  log:config(msg.ServicesListeningAddress:tag(address))
  local orb = access.initORB(address)
  local legacy
  if not Configs.nolegacy then
    local legacyIDL = require "openbus.core.legacy.idl"
    legacyIDL.loadto(orb)
    local ACS = require "openbus.core.legacy.AccessControlService"
    legacy = ACS.IAccessControlService
  end
  iceptor = access.Interceptor{
    prvkey = assert(readprivatekey(Configs.privatekey)),
    orb = orb,
    legacy = legacy,
  }
  orb:setinterceptor(iceptor, "corba")
  loadidl(orb)
  logaddress = logaddress and iceptor.callerAddressOf

  -- prepare facets to be published as CORBA objects
  local facets = {}
  do
    local facetmodules = {
      access_control = AccessControl,
      offer_registry = OfferRegistry,
    }
    local objkeyfmt = BusObjectKey.."/%s"
    for modname, modfacets in pairs(facetmodules) do
      for name, facet in pairs(modfacets) do
        facet.__facet = name
        facet.__objkey = objkeyfmt:format(name)
        facets[name] = facet
      end
    end
  end

  -- create SCS component
  newSCS{
    orb = orb,
    objkey = BusObjectKey,
    name = BusObjectKey,
    facets = facets,
    init = function()
      local params = {
        access = iceptor,
        database = assert(opendb(Configs.database)),
        leaseTime = Configs.leasetime,
        expirationGap = Configs.expirationgap,
        passwordPenaltyTime = Configs.passwordpenalty,
        passwordTries = Configs.passwordtries,
        passwordFailureLimit = Configs.validationrate,
        passwordFailureRate = Configs.validationrate,
        admins = adminUsers,
        validators = validators,
        enforceAuth = not Configs.noauthorizations,
      }
      log:config(msg.LoadedBusDatabase:tag{path=Configs.database})
      log:config(msg.LoadedBusPrivateKey:tag{path=Configs.privatekey})
      log:config(msg.SetupLoginLeaseTime:tag{seconds=params.leaseTime})
      log:config(msg.SetupLoginExpirationGap:tag{seconds=params.expirationGap})
      log:config(msg.WrongPasswordPenaltyTime:tag{seconds=Configs.passwordpenalty})
      log:config(msg.WrongPasswordLimitedTries:tag{maxtries=Configs.passwordtries})
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
          access = iceptor.context,
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
end
