-- $Id$

local _G = require "_G"
local ipairs = _G.ipairs
local require = _G.require
local select = _G.select
local setmetatable = _G.setmetatable

local io = require "string"
local format = io.format

local math = require "math"
local inf = math.huge

local io = require "io"
local openfile = io.open
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

  local errcode = {
    InvalidLeaseTime = 2,
    InvalidExpirationGap = 3,
    InvalidPasswordPenaltyTime = 4,
    InvalidNumberOfPasswordLimitedTries = 5,
    MissingPasswordValidationParameter = 6,
    InvalidPasswordValidationLimit = 7,
    InvalidPasswordValidationRate = 8,
    UnableToLoadPasswordValidator = 9,
    UnableToInitializePasswordValidator = 10,
    UnableToReadPrivateKey = 11,
    UnableToOpenDatabase = 12,
    NoPasswordValidators = 13,
  }

  -- configuration parameters parser
  local Configs = ConfigArgs{
    host = "*",
    port = 2089,
  
    database = "openbus.db",
    privatekey = "openbus.key",
  
    leasetime = 30*60,
    expirationgap = 10,
  
    badpasswordpenalty = 3*60,
    badpasswordtries = 3,
    badpasswordlimit = inf,
    badpasswordrate = inf,
  
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

  log:level(Configs.loglevel)
  log:version(msg.CopyrightNotice)

  do -- parse configuration file
    local path = getenv("OPENBUS_CONFIG")
    if path == nil then
      path = "openbus.cfg"
      local file = openfile(path)
      if file == nil then goto done end
      file:close()
    end
    Configs:configs("configs", path)
    ::done::
  end

  -- parse command line parameters
  do
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

  -badpasswordpenalty <sec.> período com tentativas de login limitadas após falha de senha
  -badpasswordtries <number> número de tentativas durante o período de 'passwordpenalty'
  -badpasswordlimit <number> número máximo de autenticações simultâneas com senha incorreta
  -badpasswordrate <number>  frequência máxima de autenticações com senha incoreta (autenticação/segundo)

  -admin <user>              usuário com privilégio de administração
  -validator <name>          nome de pacote de validação de login

  -loglevel <number>         nível de log gerado pelo barramento
  -logfile <path>            arquivo de log gerado pelo barramento
  -oilloglevel <number>      nível de log gerado pelo OiL (debug)
  -oillogfile <path>         arquivo de log gerado pelo OiL (debug)

  -noauthorizations          desativa o suporte a autorizações de oferta
  -nolegacy                  desativa o suporte à versão antiga do barramento
  -logaddress                exibe o endereço IP do requisitante no log do barramento

  -configs <path>            arquivo de configurações adicionais do barramento
  
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
  local logfile = setuplog(log, Configs.loglevel, Configs.logfile)
  if logfile ~= nil then OPENBUS_SETLOGPATH(logfile) end
  log:config(msg.CoreServicesLogLevel:tag{value=Configs.loglevel})
  setuplog(oillog, Configs.oilloglevel, Configs.oillogfile)
  log:config(msg.OilLogLevel:tag{value=Configs.oilloglevel})

  -- validate time parameters
  if Configs.leasetime%1 ~= 0 or Configs.leasetime < 1 then
    log:misconfig(msg.InvalidLeaseTime:tag{value = Configs.leasetime})
    return errcode.InvalidLeaseTime
  elseif Configs.expirationgap <= 0 then
    log:misconfig(msg.InvalidExpirationGap:tag{value = Configs.expirationgap})
    return errcode.InvalidExpirationGap
  elseif Configs.badpasswordpenalty < 0 then
    log:misconfig(msg.InvalidPasswordPenaltyTime:tag{
      value = Configs.badpasswordpenalty,
    })
    return errcode.InvalidPasswordPenaltyTime
  elseif Configs.badpasswordtries%1 ~= 0 or Configs.badpasswordtries < 1 then
    log:misconfig(msg.InvalidNumberOfPasswordLimitedTries:tag{
      value = Configs.badpasswordtries,
    })
    return errcode.InvalidNumberOfPasswordLimitedTries
  elseif (Configs.badpasswordlimit~=inf) ~= (Configs.badpasswordrate~=inf) then
    log:misconfig(msg.MissingPasswordValidationParameter:tag{
      missing = (Configs.badpasswordlimit == inf)
                and "badpasswordlimit"
                or "badpasswordrate"
    })
    return errcode.MissingPasswordValidationParameter
  elseif Configs.badpasswordlimit < 1 then
    log:misconfig(msg.InvalidPasswordValidationLimit:tag{
      value = Configs.badpasswordlimit,
    })
    return errcode.InvalidPasswordValidationLimit
  elseif Configs.badpasswordrate <= 0 then
    log:misconfig(msg.InvalidPasswordValidationRate:tag{
      value = Configs.badpasswordlimitrate,
    })
    return errcode.InvalidPasswordValidationRate
  end
  
  -- load private key
  local prvkey, errmsg = readprivatekey(Configs.privatekey)
  if prvkey == nil then
    log:misconfig(msg.UnableToReadPrivateKey:tag{
      path = Configs.privatekey,
      error = errmsg,
    })
    return errcode.UnableToReadPrivateKey
  end
  
  -- open database
  local database, errmsg = opendb(Configs.database)
  if database == nil then
    log:misconfig(msg.UnableToOpenDatabase:tag{
      path = Configs.database,
      error = errmsg,
    })
    return errcode.UnableToOpenDatabase
  end

  -- load all password validators to be used
  local validators = {}
  for index, package in ipairs(Configs.validator) do
    local ok, result = pcall(require, package)
    if not ok then
      log:misconfig(msg.UnableToLoadPasswordValidator:tag{
        validator = package,
        error = result,
      })
      return errcode.UnableToLoadPasswordValidator
    end
    local validate, errmsg = result(Configs)
    if validate == nil then
      log:misconfig(msg.UnableToInitializePasswordValidator:tag{
        validator = package,
        error = errmsg,
      })
      return errcode.UnableToInitializePasswordValidator
    end
    validators[#validators+1] = {
      name = package,
      validate = validate,
    }
    log:config(msg.PasswordValidatorLoaded:tag{name=package})
  end
  if #validators == 0 then
    log:misconfig(msg.NoPasswordValidators)
    return errcode.NoPasswordValidators
  end

  -- create a set of admin users
  local adminUsers = {}
  for _, admin in ipairs(Configs.admin) do
    adminUsers[admin] = true
    log:config(msg.AdministrativeRightsGranted:tag{entity=admin})
  end
  
  -- setup bus access
  local address = { host=Configs.host, port=Configs.port }
  log:config(msg.ServicesListeningAddress:tag(address))
  address.tcpoptions = {timeout=1,reuseaddr=true}
  local orb = access.initORB(address)
  local legacy
  if not Configs.nolegacy then
    local legacyIDL = require "openbus.core.legacy.idl"
    legacyIDL.loadto(orb)
    local ACS = require "openbus.core.legacy.AccessControlService"
    legacy = ACS.IAccessControlService
  end
  iceptor = access.Interceptor{
    prvkey = prvkey,
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
        database = database,
        leaseTime = Configs.leasetime,
        expirationGap = Configs.expirationgap,
        passwordPenaltyTime = Configs.badpasswordpenalty,
        passwordLimitedTries = Configs.badpasswordtries,
        passwordFailureLimit = Configs.badpasswordlimit,
        passwordFailureRate = Configs.badpasswordrate,
        admins = adminUsers,
        validators = validators,
        enforceAuth = not Configs.noauthorizations,
      }
      log:config(msg.LoadedBusDatabase:tag{path=Configs.database})
      log:config(msg.LoadedBusPrivateKey:tag{path=Configs.privatekey})
      log:config(msg.SetupLoginLeaseTime:tag{seconds=params.leaseTime})
      log:config(msg.SetupLoginExpirationGap:tag{seconds=params.expirationGap})
      log:config(msg.BadPasswordPenaltyTime:tag{seconds=Configs.badpasswordpenalty})
      log:config(msg.BadPasswordLimitedTries:tag{limit=Configs.badpasswordtries})
      log:config(msg.BadPasswordTotalLimit:tag{value=Configs.badpasswordlimit})
      log:config(msg.BadPasswordMaxRate:tag{value=Configs.badpasswordrate})
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
