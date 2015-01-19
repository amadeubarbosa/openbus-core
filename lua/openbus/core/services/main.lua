-- $Id$

local _G = require "_G"
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local pcall = _G.pcall
local require = _G.require
local select = _G.select
local setmetatable = _G.setmetatable
local tostring = _G.tostring

local array = require "table"
local concat = array.concat

local string = require "string"
local format = string.format
local match = string.match
local char = string.char

local math = require "math"
local inf = math.huge

local io = require "io"
local openfile = io.open
local stderr = io.stderr

local os = require "os"
local getenv = os.getenv

local x509 = require "lce.x509"
local decodecertificate = x509.decode

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
local readfile = server.readfrom
local readprivatekey = server.readprivatekey

local idl = require "openbus.core.idl"
local BusObjectKey = idl.const.BusObjectKey
local mngidl = require "openbus.core.admin.idl"
local loadidl = mngidl.loadto
local access = require "openbus.core.services.Access"
local initorb = access.initORB
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
end

return function(...)
  log.viewer.labels[running()] = "busservices"

  local errcode = {
    IllegalConfigurationParameter = 1,
    InvalidLeaseTime = 2,
    InvalidExpirationGap = 3,
    InvalidPasswordPenaltyTime = 4,
    InvalidNumberOfPasswordLimitedTries = 5,
    MissingPasswordValidationParameter = 6,
    InvalidPasswordValidationLimit = 7,
    InvalidPasswordValidationRate = 8,
    UnableToLoadPasswordValidator = 9,
    UnableToLoadTokenValidator = 10,
    UnableToInitializePasswordValidator = 11,
    UnableToInitializeTokenValidator = 12,
    UnableToReadPrivateKey = 13,
    UnableToReadCertificate = 14,
    UnableToOpenDatabase = 15,
    DuplicatedPasswordValidators = 16,
    DuplicatedTokenValidators = 17,
    IllegalPasswordValidatorSpec = 18,
    IllegalTokenValidatorSpec = 19,
    MissingSecureConnectionAuthenticationKey = 20,
    MissingSecureConnectionAuthenticationCertificate = 21,
    NoPasswordValidatorForLegacyDomain = 22,
    InvalidSecurityLayerMode = 23,
  }

  -- configuration parameters parser
  local Configs = ConfigArgs{
    iorfile = "",
    host = "*",
    port = 0,
  
    sslmode = "",
    sslport = 0,
    sslcafile = "",
    sslcapath = "",
    sslcert = "",
    sslkey = "",
  
    privatekey = "openbus.key",
    certificate = "openbus.crt",
    database = "openbus.db",

    leasetime = 30*60,
    expirationgap = 10,
  
    badpasswordpenalty = 3*60,
    badpasswordtries = 3,
    badpasswordlimit = inf,
    badpasswordrate = inf,
  
    admin = {},
    validator = {},
    tokenvalidator = {},
  
    loglevel = 3,
    logfile = "",
    oilloglevel = 0,
    oillogfile = "",
    
    noauthorizations = false,
    logaddress = false,
    nolegacy = false,
    legacydomain = "",

    help = false,
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

  do -- parse command line parameters
    local argidx, errmsg = Configs(...)
    if argidx == nil or argidx <= select("#", ...) then
      if argidx ~= nil then
        errmsg = msg.IllegalConfigurationParameter:tag{value=select(argidx, ...)}
      end
      stderr:write(errmsg,"\n")
      Configs.help = true
    end
    if Configs.help then
      stderr:write([[
Usage:  ]],OPENBUS_PROGNAME,[[ [options]
Options:

  -iorfile <path>            arquivo onde o IOR do barramento deve ser gerado
  -host <address>            endereço de rede usado pelo barramento
  -port <number>             número da porta usada pelo barramento

  -sslmode <mode>            ativa o suporte SSL através das opções 'supported' ou 'required'
  -sslport <number>          número da porta segura usada pelo barramento
  -sslcapath <path>          diretório com certificados de CAs a serem usados na autenticação SSL
  -sslcafile <path>          arquivo com certificados de CAs a serem usados na autenticação SSL
  -sslcert <path>            arquivo com certificado do barramento
  -sslkey <path>             arquivo com chave privada do barramento

  -privatekey <path>         arquivo com chave privada do barramento
  -certificate <path>        arquivo de certificado com chave pública do barramento
  -database <path>           arquivo de dados do barramento

  -leasetime <seconds>       tempo de lease dos logins de acesso
  -expirationgap <seconds>   tempo que os logins ficam válidas após o lease

  -badpasswordpenalty <sec.> período com tentativas de login limitadas após falha de senha
  -badpasswordtries <number> número de tentativas durante o período de 'passwordpenalty'
  -badpasswordlimit <number> número máximo de autenticações simultâneas com senha incorreta
  -badpasswordrate <number>  frequência máxima de autenticações com senha incoreta (autenticação/segundo)

  -admin <user>              usuário com privilégio de administração
  -validator <name>          nome de pacote de validação de login
  -tokenvalidator <name>     nome de pacote de validação de token de cadeia externa

  -loglevel <number>         nível de log gerado pelo barramento
  -logfile <path>            arquivo de log gerado pelo barramento
  -oilloglevel <number>      nível de log gerado pelo OiL (debug)
  -oillogfile <path>         arquivo de log gerado pelo OiL (debug)

  -noauthorizations          desativa o suporte a autorizações de oferta
  -logaddress                exibe o endereço IP do requisitante no log do barramento
  -nolegacy                  desativa o suporte à versão antiga do barramento
  -legacydomain              domínio de autenticação com a versão antiga do barramento

  -configs <path>            arquivo de configurações adicionais do barramento

  -help                      exibe essa mensagem e encerra a execução
]])
    end
    return errcode.IllegalConfigurationParameter
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
    log:misconfig(errmsg)
    return errcode.UnableToReadPrivateKey
  end
  
  -- load certificate
  local certificate, errmsg = readfile(Configs.certificate)
  if certificate == nil then
    log:misconfig(msg.UnableToReadCertificate:tag{
      path = Configs.certificate,
      error = errmsg,
    })
    return errcode.UnableToReadCertificate
  end

  -- validate certificate
  do
    local result, errmsg = decodecertificate(certificate)
    if result ~= nil then
      result, errmsg = result:getpubkey()
      if result ~= nil then
        local chars = {}
        for i = 0, 128 do chars[i+1] = char(i) end
        chars = concat(chars)
        result, errmsg = result:encrypt(chars)
        if result ~= nil then
          result, errmsg = (prvkey:decrypt(result) == chars), msg.WrongPublicKey
        end
      end
    end
    if not result then
      log:misconfig(msg.WrongBusCertificate:tag{
        path = Configs.certificate,
        error = errmsg,
      })
      return errcode.WrongCertificate
    end
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

  -- load all password and token validators to be used
  local validators = {
    validator = {},
    tokenvalidator = {},
  }
  local valinfo = {
    validator = {
      loaded = msg.PasswordValidatorLoaded,
      illegalerrmsg = msg.IllegalPasswordValidatorSpec,
      illegalerrcode = errcode.IllegalPasswordValidatorSpec,
      twiceerrmsg = msg.DuplicatedPasswordValidators,
      twiceerrcode = errcode.DuplicatedPasswordValidators,
      loaderrmsg = msg.UnableToLoadPasswordValidator,
      loaderrcode = errcode.UnableToLoadPasswordValidator,
      initerrmsg = msg.UnableToInitializePasswordValidator,
      initerrcode = errcode.UnableToInitializePasswordValidator,
    },
    tokenvalidator = {
      loaded = msg.TokenValidatorLoaded,
      illegalerrmsg = msg.IllegalTokenValidatorSpec,
      illegalerrcode = errcode.IllegalTokenValidatorSpec,
      twiceerrmsg = msg.DuplicatedTokenValidators,
      twiceerrcode = errcode.DuplicatedTokenValidators,
      loaderrmsg = msg.UnableToLoadTokenValidator,
      loaderrcode = errcode.UnableToLoadTokenValidator,
      initerrmsg = msg.UnableToInitializeTokenValidator,
      initerrcode = errcode.UnableToInitializeTokenValidator,
    },
  }
  for param, list in pairs(validators) do
    local info = valinfo[param]
    for index, spec in ipairs(Configs[param]) do
      local domain, package = match(spec, "^([^:]-):?([^:]+)$")
      if domain == nil then
        log:misconfig(info.illegalerrmsg:tag{
          specification = spec,
        })
        return info.illegalerrcode
      end
      local other = list[domain]
      if other ~= nil then
        log:misconfig(info.twiceerrmsg:tag{
          domain = domain,
          validator = package,
          other = other.name,
        })
        return info.twiceerrcode
      end
      local ok, result = pcall(require, package)
      if not ok then
        log:misconfig(info.loaderrmsg:tag{
          domain = domain,
          validator = package,
          error = result,
        })
        return info.loaderrcode
      end
      local validate, errmsg = result(Configs)
      if validate == nil then
        log:misconfig(info.initerrmsg:tag{
          domain = domain,
          validator = package,
          error = errmsg,
        })
        return info.initerrcode
      end
      list[domain] = {
        name = package,
        validate = validate,
      }
      log:config(info.loaded:tag{name=package,domain=domain})
    end
    if param == "validator"
    and not Configs.nolegacy
    and list[Configs.legacydomain] == nil then
      log:misconfig(msg.NoPasswordValidatorForLegacyDomain:tag{ domain = Configs.legacydomain })
      return info.NoPasswordValidatorForLegacyDomain
    end
  end

  -- create a set of admin users
  local adminUsers = {}
  for _, admin in ipairs(Configs.admin) do
    adminUsers[admin] = true
    log:config(msg.AdministrativeRightsGranted:tag{entity=admin})
  end
  
  -- setup bus access
  local sslcfg = {
    key = getoptcfg(Configs, "sslkey", ""),
    certificate = getoptcfg(Configs, "sslcert", ""),
    cafile = getoptcfg(Configs, "sslcafile", ""),
    capath = getoptcfg(Configs, "sslcapath", ""),
  }
  local sslmode, orbflv, orbopt = Configs.sslmode
  if SSLRequiredOptions[sslmode] ~= nil then
    orbflv = "cooperative;corba;corba.intercepted;corba.ssl;kernel.ssl"
    orbopt = {
      security = Configs.sslmode == "required" and "required" or nil,
      ssl = sslcfg,
    }
    if sslcfg.key ~= nil or sslcfg.certificate ~= nil then
      if sslcfg.key == nil then
        log:misconfig(msg.MissingSecureConnectionAuthenticationKey)
        return errcode.MissingSecureConnectionAuthenticationKey
      end
      if sslcfg.certificate == nil then
        log:misconfig(msg.MissingSecureConnectionAuthenticationCertificate)
        return errcode.MissingSecureConnectionAuthenticationCertificate
      end
      log:config(msg.SecureConnectionAuthenticationKey:tag{
        path = sslcfg.key,
      })
      log:config(msg.SecureConnectionAuthenticationCertificate:tag{
        path = sslcfg.certificate,
      })
    end
    if sslcfg.cafile ~= nil then
      log:config(msg.SecureConnectionCertificationAuthorityListFile:tag{path=sslcfg.cafile})
    elseif sslcfg.capath ~= nil then
      log:config(msg.SecureConnectionCertificationAuthorityDirectory:tag{path=sslcfg.capath})
    end
  elseif sslmode ~= "" then
    log:misconfig(msg.InvalidSecurityLayerMode:tag{
      value = Configs.sslmode,
    })
    return errcode.InvalidSecurityLayerMode
  end
  local orb = initorb{
    host = Configs.host,
    port = getoptcfg(Configs, "port", 0),
    sslport = getoptcfg(Configs, "sslport", 0),
    flavor = orbflv,
    options = orbopt,
  }
  if orbopt ~= nil then
    log:config(sslmode == "required" and msg.SecureConnectionEnforced
                                      or msg.SecureConnectionEnabled)
    log:config(msg.SecureConnectionPortNumber:tag{port=orb.sslport})
  end
  log:config(msg.ServicesListeningAddress:tag{host=orb.host,port=orb.port})
  local iceptor = access.Interceptor{
    prvkey = prvkey,
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
        certificate = certificate,
        database = database,
        leaseTime = Configs.leasetime,
        expirationGap = Configs.expirationgap,
        passwordPenaltyTime = Configs.badpasswordpenalty,
        passwordLimitedTries = Configs.badpasswordtries,
        passwordFailureLimit = Configs.badpasswordlimit,
        passwordFailureRate = Configs.badpasswordrate,
        admins = adminUsers,
        passwordValidators = validators.validator,
        tokenValidators = validators.tokenvalidator,
        enforceAuth = not Configs.noauthorizations,
      }
      log:config(msg.LoadedBusDatabase:tag{path=Configs.database})
      log:config(msg.LoadedBusPrivateKey:tag{path=Configs.privatekey})
      log:config(msg.LoadedBusCertificate:tag{path=Configs.certificate})
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
    local BusObjectKey = oldidl.const.v2_0.BusObjectKey
    oldidl.loadto(orb)
    local LegacyFacets = require "openbus.core.legacy.ServiceWrappers"
    -- prepare facets to be published as CORBA objects
    do
      local params = {
        access = iceptor,
        services = facets,
        admins = adminUsers,
        domain = Configs.legacydomain,
      }
      log:config(msg.LegacyPasswordDomain:tag{value=Configs.legacydomain})
      local objkeyfmt = BusObjectKey.."/%s"
      for name, facet in pairs(LegacyFacets) do
        facet.__facet = name
        facet.__objkey = objkeyfmt:format(name)
        facet:__init(params)
      end
    end
    iceptor.legacy = LegacyFacets.AccessControl
    local legacyBus = newSCS{
      orb = orb,
      objkey = BusObjectKey,
      name = BusObjectKey,
      facets = LegacyFacets,
    }
    local legacyFacet = "LegacySupport"
    bus._facets[legacyFacet] = {
      name = legacyFacet,
      interface_name = legacyBus._facets.IComponent.interface_name,
      facet_ref = legacyBus.IComponent,
      implementation = legacyBus._facets.IComponent.implementation,
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
