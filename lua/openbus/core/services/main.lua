-- $Id$
local removefile = os.remove
local renamefile = os.rename

local _G = require "_G"
local ipairs = _G.ipairs
local pairs = _G.pairs
local pcall = _G.pcall
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
local dbconverter = require "openbus.util.database_converter"
local dbconvert = dbconverter.convert
local database = require "openbus.util.database"
local opendb = database.open
local database_legacy = require "openbus.util.database_legacy"
local opendb_legacy = database_legacy.open
local server = require "openbus.util.server"
local ConfigArgs = server.ConfigArgs
local newSCS = server.newSCS
local setuplog = server.setuplog
local readprivatekey = server.readprivatekey
local sysex = require "openbus.util.sysex"
local NO_PERMISSION = sysex.NO_PERMISSION

local idl = require "openbus.core.idl"
local ServiceFailure = idl.throw.services.ServiceFailure
local BusEntity = idl.const.BusEntity
local BusObjectKey = idl.const.BusObjectKey
local mngidl = require "openbus.core.admin.idl"
local ConfigurationType = mngidl.types.services.admin.v1_0.Configuration
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
    InvalidChallengeTime = 14,
    InvalidSharedAuthTime = 15,
    InvalidMaximumChannelLimit = 16,
    UnableToConvertLegacyDatabase = 17,
  }

  local reloadConfigs = {
    admin = {},
    validator = {},
    maxchannels = 0,
    loglevel = 3,
    oilloglevel = 0,
  }

  local defConfigs = {
    host = "*",
    port = 2089,
  
    database = "openbus.db",
    privatekey = "openbus.key",
  
    leasetime = 30*60,
    expirationgap = 10,
    challengetime = 0,
    sharedauthtime = 0,

    badpasswordpenalty = 3*60,
    badpasswordtries = 3,
    badpasswordlimit = inf,
    badpasswordrate = inf,

    logfile = "",
    oillogfile = "",
    
    noauthorizations = false,
    nolegacy = false,
    logaddress = false,
  }
  for k, v in pairs(reloadConfigs) do
    defConfigs[k] = v
  end
  
  -- configuration parameters parser
  local Configs = ConfigArgs(defConfigs)

  log:level(Configs.loglevel)
  log:version(msg.CopyrightNotice)

  local function revokeAdmin(user, admins)
    admins[user] = nil 
    log:config(msg.AdministrativeRightsRevoked:tag{entity=user})
  end

  local function grantAdmin(user, admins)
    if not admins[user] then
      admins[user] = true
      log:config(msg.AdministrativeRightsGranted:tag{entity=user})
    end
  end
  
  local function resetAdminUsers(admins)
    local updatedAdminUsers = {}
    for _, admin in pairs(Configs.admin) do
      updatedAdminUsers[admin] = true
      grantAdmin(admin, admins)
    end
    for admin,_ in pairs(admins) do
      if admin ~= BusEntity and not updatedAdminUsers[admin] then
        revokeAdmin(admin, admins)
      end
    end
  end

  local function loadValidator(package, validators)
    local ok, result = pcall(require, package)
    if not ok then
      log:misconfig(msg.UnableToLoadPasswordValidator:tag{
        validator = package,
        error = result,
      })
      return false, errcode.UnableToLoadPasswordValidator, result
    end
    
    local ok, validate, finalize = pcall(result, Configs)
    if not ok or validate == nil then
      local errmsg = (not ok and validate) or finalize
      log:misconfig(msg.UnableToInitializePasswordValidator:tag{
        validator = package,
        error = errmsg,
      })
      return false, errcode.UnableToInitializePasswordValidator, errmsg
    end
    
    validators[package] = {
      name = package,
      validate = validate,
      finalize = finalize,
    }

    return true
  end

  local function loadValidators(validators)
    local hasValidator = false
    for _, package in pairs(Configs.validator) do
      if not hasValidator then hasValidator = true end
      local ok, errcode, errmsg = loadValidator(package, validators)
      if not ok then return false, errcode, errmsg end
      log:config(msg.PasswordValidatorLoaded:tag{ validator = package })
    end
    if not hasValidator then
      log:misconfig(msg.NoPasswordValidators)
      return false, errcode.NoPasswordValidators
    end
    return true
  end
  
  local function setLogLevel(logtype, loglevel)
    local logobj, logmsg
    if logtype == "oil" then
      logobj = oillog
      logmsg = msg.OilLogLevel
    elseif logtype == "core" then
      logobj = log
      logmsg = msg.CoreServicesLogLevel
    end
    local currLogLevel = logobj:level()
    if currLogLevel ~= loglevel then
      logobj:level(loglevel)
      log:config(logmsg:tag{value=loglevel})
    end
    return true
  end

  local function validateMaxChannels(maxchannels)
    if maxchannels < 0 then
      log:misconfig(msg.InvalidMaximumChannelLimit:tag{
        value = maxchannels,
      })
      return false, errcode.InvalidMaximumChannelLimit
    end
    return true
  end

  local function resetMaxChannels(orb, maxchannels)
    local ok, errcode = validateMaxChannels(maxchannels)
    if not ok then
      return false, errcode
    else
      orb.ResourceManager.inuse.maxsize = maxchannels
      log:config(msg.MaximumChannelLimit:tag{value=maxchannels})
    end
    return true
  end

  local function loadConfigs()
    local path = getenv("OPENBUS_CONFIG")
    if path == nil then
      path = "openbus.cfg"
      local file = openfile(path)
      if file == nil then return end
      file:close()
    end
    Configs:configs("configs", path)
  end

  loadConfigs()
  
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
  -challengetime <seconds>   tempo de duração do desafio de autenticação por certificado
  -sharedauthtime <seconds>  tempo de validade dos segredos de autenticação compartilhada

  -badpasswordpenalty <sec.> período com tentativas de login limitadas após falha de senha
  -badpasswordtries <number> número de tentativas durante o período de 'passwordpenalty'
  -badpasswordlimit <number> número máximo de autenticações simultâneas com senha incorreta
  -badpasswordrate <number>  frequência máxima de autenticações com senha incoreta (autenticação/segundo)

  -maxchannels <number>      número máximo de canais de comunicação com os sistemas

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
  if Configs.challengetime == 0 then
    Configs.challengetime = Configs.expirationgap
  end
  if Configs.sharedauthtime == 0 then
    Configs.sharedauthtime = Configs.leasetime
  end
  if Configs.leasetime%1 ~= 0 or Configs.leasetime < 1 then
    log:misconfig(msg.InvalidLeaseTime:tag{value = Configs.leasetime})
    return errcode.InvalidLeaseTime
  elseif Configs.expirationgap <= 0 then
    log:misconfig(msg.InvalidExpirationGap:tag{value = Configs.expirationgap})
    return errcode.InvalidExpirationGap
  elseif Configs.challengetime <= 0 then
    log:misconfig(msg.InvalidChallengeTime:tag{value = Configs.challengetime})
    return errcode.InvalidChallengeTime
  elseif Configs.sharedauthtime%1 ~= 0 or Configs.sharedauthtime < 1 then
    log:misconfig(msg.InvalidSharedAuthTime:tag{value = Configs.sharedauthtime})
    return errcode.InvalidSharedAuthTime
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

  do
    local res, errcode = validateMaxChannels(Configs.maxchannels)
    if not res then return errcode end
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

  local dbpath = Configs.database
  local dblegacy = opendb_legacy(dbpath)
  local converted
  if dblegacy then
     local dbtmppath = dbpath..".convert"
    local res, errmsg = opendb(dbtmppath)
    if not res then
      dbpath = dbtmppath
    else
      local dbtmp = res
      res, errmsg = pcall(dbconvert, dblegacy, dbtmp)
      if res then
        local dbbakpath = dbpath..".bak"
        res, errmsg = renamefile(dbpath, dbbakpath)
        if not res then
          errmsg = "unable to rename legacy database to '"..dbbakpath
             .."' ("..errmsg..")"
        else
          res, errmsg = renamefile(dbtmppath, dbpath)
          if not res then
            errmsg = "unable to promote the converted database to '"..dbpath
              .."' ("..errmsg..")"
          else
            converted = true
            log:config(msg.ConvertedLegacyBusDatabase:tag{path=dbbakpath})
          end 
        end
      end
    end
    
    if not converted then
      removefile(dbtmppath)
      log:misconfig(msg.UnableToConvertLegacyDatabase:tag{
        path = dbpath,
        error = errmsg,
      })
      return errcode.UnableToConvertLegacyDatabase
    end
  end

  local database, errmsg = opendb(dbpath)
  if database == nil then
    log:misconfig(msg.UnableToOpenDatabase:tag{
      path = dbpath,
      error = errmsg,
    })
    return errcode.UnableToOpenDatabase
  end

  -- load all password validators to be used
  local validators = {}
  do
    local res, errcode = loadValidators(validators)
    if not res then return errcode end
  end
  
  -- create a set of admin users
  local adminUsers = { [BusEntity] = true }
  resetAdminUsers(adminUsers)
  
  -- setup bus access
  local orbcfg = { host=Configs.host, port=Configs.port }
  log:config(msg.ServicesListeningAddress:tag(orbcfg))
  if Configs.maxchannels > 0 then
    orbcfg.maxchannels = Configs.maxchannels
  end
  local orb = access.initORB(orbcfg)
  local legacy
  if not Configs.nolegacy then
    local legacyIDL = require "openbus.core.legacy.idl"
    legacyIDL.loadto(orb)
    local ACS = require "openbus.core.legacy.AccessControlService"
    legacy = ACS.IAccessControlService
  end
  local iceptor = access.Interceptor{
    prvkey = prvkey,
    orb = orb,
    legacy = legacy,
  }
  orb:setinterceptor(iceptor, "corba")
  loadidl(orb)
  logaddress = logaddress and iceptor.callerAddressOf

  local Configuration = {
    __type = ConfigurationType,
    __facet = "Configuration",
    __objkey = BusObjectKey.."/Configuration"
  }

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
    facets.Configuration = Configuration
  end

  function Configuration:__init(data)
    self.access = data.access
    self.admins = data.admins
    self.validators = data.validators
    local access = self.access
    local admins = self.admins
    access:setGrantedUsers(self.__type, "reloadConfigsFile", admins)
    access:setGrantedUsers(self.__type, "grantAdminTo", admins)
    access:setGrantedUsers(self.__type, "revokeAdminFrom", admins)
    access:setGrantedUsers(self.__type, "addValidator", admins)
    access:setGrantedUsers(self.__type, "delValidator", admins)
    access:setGrantedUsers(self.__type, "setMaxChannels", admins)
    access:setGrantedUsers(self.__type, "setLogLevel", admins)
    access:setGrantedUsers(self.__type, "setOilLogLevel", admins)
  end
  
  -- local operations
  local function updateLogLevel(log, loglevel)
    if not setLogLevel(log, loglevel) then
      ServiceFailure{
        message = msg.InvalidLogLevel:tag{value=loglevel}
      }
    end
  end

  local function updateAdmins(users, action, admins)
    for _, admin in ipairs(users) do
      if "grant" == action then
        grantAdmin(admin, admins)
      else
        if admin ~= BusEntity and admins[admin] then
          revokeAdmin(admin, admins)
        end
      end
    end   
  end
  
  local function getList(t)
    local list = {}
    for e in pairs(t) do
      list[#list+1] = e
    end
    return list
  end

  local function unloadValidator(name, validators)
    local module = validators[name]
    validators[name] = nil
    package.loaded[name] = nil
    if module.finalize ~= nil then
      local ok, errmsg = pcall(module.finalize)
      if not ok then
        ServiceFailure{
          message = msg.FailedPasswordValidatorTermination:tag{
            validator = name,
            errmsg = errmsg or msg.UnspecifiedTerminationFailure,
          }
        }
      end
    end
    return true
  end

  local function unloadValidators(validators)
    for name, validator in pairs(validators) do
      local ok, errmsg = pcall(unloadValidator, name, validators)
      if not ok then
        log:exception(errmsg)
      end
      log:admin(msg.PasswordValidatorUnloaded:tag{
          validator = name
      })
    end
  end

  function Configuration:shutdown()
    unloadValidators(self.validators)
  end

  -- public operations
  function Configuration:reloadConfigsFile()
    local orb = self.access.orb
    local admins = self.admins
    local validators = self.validators
    -- load configuration from file
    loadConfigs()
    -- reconfigure its parameter
    setLogLevel("core", Configs.loglevel)
    setLogLevel("oil", Configs.oilloglevel)
    resetMaxChannels(orb, Configs.maxchannels)
    resetAdminUsers(admins)
    unloadValidators(validators)
    loadValidators(validators)
  end

  function Configuration:grantAdminTo(users)
    updateAdmins(users, "grant", self.admins)
  end

  function Configuration:revokeAdminFrom(users)
    updateAdmins(users, "revoke", self.admins)
  end

  function Configuration:getAdmins()
    return getList(self.admins)
  end

  function Configuration:addValidator(name)
    local validators = self.validators
    if not validators[name] then
      local ok, _, errmsg = loadValidator(name, validators)
      if not ok then
        ServiceFailure{
          message = msg.UnableToLoadPasswordValidator:tag{
            validator = name,
            error = errmsg,
          }
        }
      end
      log:admin(msg.PasswordValidatorLoaded:tag{validator = name})
    end
  end

  function Configuration:delValidator(name)
    local validators = self.validators
    if validators[name] then
      unloadValidator(name, validators)
      log:admin(msg.PasswordValidatorUnloaded:tag{validator = name})
    end
  end

  function Configuration:getValidators()
    return getList(self.validators)
  end

  function Configuration:setMaxChannels(maxchannels)
    if not resetMaxChannels(orb, maxchannels) then
      ServiceFailure{
        message = msg.InvalidMaximumChannelLimit:tag{value=maxchannels}
      }
    end
  end

  function Configuration:getMaxChannels()
    return orb.ResourceManager.inuse.maxsize
  end

  function Configuration:setLogLevel(loglevel)
    return updateLogLevel("core", loglevel)
  end

  function Configuration:getLogLevel()
    return log:level()
  end

  function Configuration:setOilLogLevel(loglevel)
    return updateLogLevel("oil", loglevel)
  end

  function Configuration:getOilLogLevel()
    return oillog:level()
  end

  -- create SCS component
  local OBSCS = newSCS{
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
        challengeTime = Configs.challengetime,
        sharedAuthTime = Configs.sharedauthtime,
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
      log:config(msg.SetupLoginChallengeTime:tag{seconds=params.challengeTime})
      log:config(msg.SetupLoginSharedAuthTime:tag{seconds=params.sharedAuthTime})
      log:config(msg.BadPasswordPenaltyTime:tag{seconds=Configs.badpasswordpenalty})
      log:config(msg.BadPasswordLimitedTries:tag{limit=Configs.badpasswordtries})
      log:config(msg.BadPasswordTotalLimit:tag{value=Configs.badpasswordlimit})
      log:config(msg.BadPasswordMaxRate:tag{value=Configs.badpasswordrate})
      if Configs.maxchannels > 0 then
        log:config(msg.MaximumChannelLimit:tag{value=Configs.maxchannels})
      end
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
      facets.Configuration:__init(params)
    end,
    shutdown = function(self)
      if iceptor:getCallerChain().caller.entity ~= BusEntity then
        NO_PERMISSION{ completed = "COMPLETED_NO" }
      end
      self.context:deactivateComponent()
      orb:shutdown()
      facets.AccessControl:shutdown()
      facets.Configuration:shutdown()
      log:uptime(msg.CoreServicesTerminated)
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

  -- start services
  OBSCS.IComponent:startup()
  log:uptime(msg.CoreServicesStarted)
end
