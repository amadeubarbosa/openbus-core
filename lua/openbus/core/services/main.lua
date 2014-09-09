-- $Id$

local _G = require "_G"
local assert = _G.assert
local ipairs = _G.ipairs
local require = _G.require
local select = _G.select
local setmetatable = _G.setmetatable
local tostring = _G.tostring

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

local oil = require "oil"
local writeto = oil.writeto
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

local SSLRequiredOptions = {
  required = true,
  supported = true,
}

local function getoptcfg(configs, field, default)
  local value = configs[field]
  if value ~= default then
    return value
  end
  --return default
end

return function(...)
  log.viewer.labels[running()] = "busservices"
  
  -- configuration parameters parser
  local Configs = ConfigArgs{
    iorfile = "",
    host = "*",
    port = 0,
  
    sslenabled = "",
    sslport = 0,
    sslcafile = "",
    sslcapath = "",
    sslcert = "",
    sslkey = "",
  
    privatekey = "openbus.key",
    database = "openbus.db",

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

  -iorfile <path>            arquivo onde o IOR do barramento deve ser gerado
  -host <address>            endereço de rede usado pelo barramento
  -port <number>             número da porta usada pelo barramento

  -sslenabled <mode>         ativa o suporte SSL através das opções 'supported' ou 'required'
  -sslport <number>          número da porta segura usada pelo barramento
  -sslcapath <path>          diretório com certificados de CAs a serem usados na autenticação SSL
  -sslcafile <path>          arquivo com certificados de CAs a serem usados na autenticação SSL
  -sslcert <path>            arquivo com certificado do barramento
  -sslkey <path>             arquivo com chave privada do barramento

  -privatekey <path>         arquivo com chave privada do barramento
  -database <path>           arquivo de dados do barramento

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
  assert(Configs.badpasswordpenalty >= 0,
    msg.InvalidPasswordPenaltyTime:tag{value=Configs.badpasswordpenalty})
  assert(Configs.badpasswordtries > 0 and Configs.badpasswordtries%1 == 0,
    msg.InvalidNumberOfPasswordLimitedTries:tag{value=Configs.badpasswordtries})
  assert((Configs.badpasswordlimit ~= inf) == (Configs.badpasswordrate ~= inf),
    msg.MissingPasswordValidationParameter:tag{
      missing = (Configs.badpasswordlimit == inf)
                and "badpasswordlimit"
                or "badpasswordrate"
    })
  assert(Configs.badpasswordlimit >= 1,
    msg.InvalidPasswordValidationLimit:tag{value=Configs.badpasswordlimit})
  assert(Configs.badpasswordrate > 0,
    msg.InvalidPasswordValidationRate:tag{value=Configs.badpasswordlimitrate})
  
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
  local sslcfg = {
    port = getoptcfg(Configs, "sslport", 0),
    key = getoptcfg(Configs, "sslkey", ""),
    certificate = getoptcfg(Configs, "sslcert", ""),
    cafile = getoptcfg(Configs, "sslcafile", ""),
    capath = getoptcfg(Configs, "sslcapath", ""),
  }
  local orbflv, orbopt
  if SSLRequiredOptions[Configs.sslenabled] or next(sslcfg) ~= nil then
    if Configs.sslenabled == "required" then
      log:config(msg.SecureConnectionEnforced)
    else
      log:config(msg.SecureConnectionEnabled)
    end
    orbflv = "cooperative;corba;corba.intercepted;corba.ssl;kernel.ssl"
    orbopt = {
      security = Configs.sslenabled == "required" and "required" or nil,
      ssl = sslcfg,
    }
    log:config(msg.SecureConnectionPortNumber:tag{path=Configs.sslport})
    if sslcfg.key ~= nil or sslcfg.certificate ~= nil then
      log:config(msg.SecureConnectionAuthenticationKey:tag{
        path = assert(sslcfg.key,
                      msg.MissingSecureConnectionAuthenticationKey),
      })
      log:config(msg.SecureConnectionAuthenticationCertificate:tag{
        path = assert(sslcfg.certificate,
                      msg.MissingSecureConnectionAuthenticationCertificate),
      })
    end
    if sslcfg.cafile ~= nil then
      log:config(msg.SecureConnectionCertificationAuthorityListFile:tag{path=sslcfg.cafile})
    elseif sslcfg.capath ~= nil then
      log:config(msg.SecureConnectionCertificationAuthorityDirectory:tag{path=sslcfg.capath})
    end
  end
  local orb = access.initORB{
    host = Configs.host,
    port = getoptcfg(Configs, "port", 0),
    flavor = orbflv,
    options = orbopt,
  }
  log:config(msg.ServicesListeningAddress:tag{host=orb.host,port=orb.port})
  iceptor = access.Interceptor{
    prvkey = assert(readprivatekey(Configs.privatekey)),
    orb = orb,
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
  local bus = newSCS{
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
    local oldidl = require "openbus.core.legacy.idl"
    local BusObjectKey = oldidl.const.BusObjectKey
    oldidl.loadto(orb)
    local LegacyFacets = require "openbus.core.legacy.ServiceWrappers"
    -- prepare facets to be published as CORBA objects
    do
      local params = {
        access = iceptor,
        services = facets,
        admins = adminUsers,
      }
      local objkeyfmt = BusObjectKey.."/%s"
      for name, facet in pairs(LegacyFacets) do
        facet.__facet = name
        facet.__objkey = objkeyfmt:format(name)
        facet:__init(params)
      end
    end
    local legacyBus = newSCS{
      orb = orb,
      objkey = BusObjectKey,
      name = BusObjectKey,
      facets = LegacyFacets,
    }
    log:config(msg.LegacySupportEnabled)
  end

  local iorfile = Configs.iorfile
  if iorfile ~= "" then
    writeto(iorfile, bus.IComponent)
    log:config(msg.BusCoreReferenceWrittenTo:tag{path=iorfile})
  else
    log:config(msg.BusCoreReferenceGenerated:tag{ior=tostring(bus.IComponent)})
  end

  -- start ORB
  log:uptime(msg.CoreServicesStarted)
end
