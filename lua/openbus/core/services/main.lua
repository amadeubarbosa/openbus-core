-- $Id$
local removefile = os.remove
local renamefile = os.rename

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

local b64 = require "base64"
local b64encode = b64.encode
local b64decode = b64.decode

local table = require "loop.table"
local copy = table.copy
local memoize = table.memoize

local LRUCache = require "loop.collection.LRUCache"

local coroutine = require "coroutine"
local newthread = coroutine.create

local cothread = require "cothread"
local running = cothread.running
local schedule = cothread.schedule

local oil = require "oil"
local writeto = oil.writeto
local oillog = require "oil.verbose"

local CharsetContext = require("oil.corba.giop.CharsetContext")
local CORBACharsets = CharsetContext.known

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
local readfile = server.readfrom
local readprivatekey = server.readprivatekey
local sysex = require "openbus.util.sysex"
local NO_PERMISSION = sysex.NO_PERMISSION

local idl = require "openbus.core.idl"
local ServiceFailure = idl.throw.services.ServiceFailure
local BusEntity = idl.const.BusEntity
local BusObjectKey = idl.const.BusObjectKey

local mngidl = require "openbus.core.admin.idl"
local ConfigurationType = mngidl.types.services.admin.v1_0.Configuration
local AuditConfigurationType = mngidl.types.services.admin.v1_1.AuditConfiguration
local loadidl = mngidl.loadto
local access = require "openbus.core.services.Access"
local initorb = access.initORB

local AuditAgent = require "openbus.core.audit.Agent"
local AuditInterceptor = require "openbus.core.services.AuditInterceptor"

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
    InvalidChallengeTime = 24,
    InvalidSharedAuthTime = 25,
    InvalidMaximumChannelLimit = 26,
    UnableToConvertLegacyDatabase = 27,
    WrongAlternateAddress = 28,
    InvalidMaximumCacheSize = 29,
    InvalidOrbCallsTimeout = 30,
    CharsetNotSupported = 31,
    MissingAuditServiceEndpoint = 32,
    InvalidAuditAgentHttpCredentials = 33,
    InvalidAuditAgentFifoLimit = 34,
    InvalidAuditAgentPublishingTasks = 35,
    InvalidAuditAgentPublishingRetryTimeout = 36,
  }

  -- configuration parameters parser
  local Configs = ConfigArgs{
    iorfile = "",
    host = "*",
    port = 2089,

    sslmode = "",
    sslport = 2090,
    sslcafile = "",
    sslcapath = "",
    sslcert = "",
    sslkey = "",

    privatekey = "openbus.key",
    certificate = "openbus.crt",
    database = "openbus.db",

    timeout = 0,
    leasetime = 30*60,
    expirationgap = 10,
    challengetime = 0,
    sharedauthtime = 0,

    badpasswordpenalty = 3*60,
    badpasswordtries = 3,
    badpasswordlimit = inf,
    badpasswordrate = inf,

    maxchannels = 1000,
    maxcachesize = LRUCache.maxsize,

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

    nodnslookup = false,
    noipaddress = false,
    alternateaddr = {},

    enableaudit = false,
    auditendpoint = "http://localhost:8080/",
    auditcredentials = "",
    auditproxy = "",
    auditparallel = 5,
    auditretrytimeout = 5,
    auditdiscardonexit = false,
    auditfifolimit = 100000,
    auditapplication = "OPENBUS",
    auditenvironment = "",

    nativecharset = "",
  }

  log:level(Configs.loglevel)
  log:version(msg.CopyrightNotice)

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
  -- parse configuration file
  loadConfigs()

  local function validateMaxChannels(maxchannels)
    if maxchannels < 1 then
      return false,
        errcode.InvalidMaximumChannelLimit,
        msg.InvalidMaximumChannelLimit:tag{ value=maxchannels }
    end
    return true
  end

  local function validateMaxCacheSize(maxsize)
    if maxsize < 0 then
      return false,
        errcode.InvalidMaximumCacheSize,
        msg.InvalidMaximumCacheSize:tag{value=maxsize}
    end
    return true
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

  -timeout <seconds>         tempo de espera por respostas nas chamadas realizadas pelo barramento
  -leasetime <seconds>       tempo de lease dos logins de acesso
  -expirationgap <seconds>   tempo que os logins ficam válidas após o lease
  -challengetime <seconds>   tempo de duração do desafio de autenticação por certificado
  -sharedauthtime <seconds>  tempo de validade dos segredos de autenticação compartilhada

  -badpasswordpenalty <sec.> período com tentativas de login limitadas após falha de senha
  -badpasswordtries <number> número de tentativas durante o período de 'passwordpenalty'
  -badpasswordlimit <number> número máximo de autenticações simultâneas com senha incorreta
  -badpasswordrate <number>  frequência máxima de autenticações com senha incoreta (autenticação/segundo)

  -maxchannels <number>      número máximo de canais de comunicação com os sistemas
  -maxcachesize <number>     tamanho máximo das caches LRU de profiles IOR, sessões de entrada e de saída

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

  -nodnslookup               desativa a busca no DNS por apelidos da máquina para compor as referências IOR
  -noipaddress               desativa o uso de endereços IP para compor as referências IOR
  -alternateaddr <address>   endereço de rede (host:port) alternativo para compor as referências IOR

  -enableaudit               ativa a publicação de dados de auditoria em serviço HTTP externo
  -auditendpoint <url>       endereço do serviço HTTP da auditoria
  -auditproxy <url>          endereço do proxy HTTP
  -auditcredentials <auth>   credenciais para autenticação HTTP básica (ex: fulano:silva)
  -auditparallel <number>    número máximo de corotinas simultâneas para o envio de dados de auditoria
  -auditretrytimeout <sec.>  tempo de espera entre retentativas de conexão no serviço de auditoria
  -auditdiscardonexit        ativa o descarte de dados de auditoria pendentes no ato do desligamento do barramento
  -auditfifolimit <number>   tamanho máximo da fila de envio de dados para o serviço de auditoria
  -auditapplication <name>   identificação do código da solução no serviço de auditoria (padrão: OPENBUS)
  -auditenvironment <name>   identificação da instância do barramento no serviço de auditoria (padrão: valor do BusId)

  -nativecharset <name>      codificação dos caracteres usada quando um sistema solicita a conversão automática

  -configs <path>            arquivo de configurações adicionais do barramento

  -help                      exibe essa mensagem e encerra a execução
]])
      return errcode.IllegalConfigurationParameter
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
  if Configs.timeout < 0 then
    log:misconfig(msg.InvalidOrbCallsTimeout:tag{value=Configs.timeout})
    return errcode.InvalidOrbCallsTimeout
  end
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

  -- validate max channels and cache size
  do
    local ok, errcode, errmsg = validateMaxChannels(Configs.maxchannels)
    if not ok then
      log:misconfig(errmsg)
      return errcode
    end
    local ok, errcode, errmsg = validateMaxCacheSize(Configs.maxcachesize)
    if not ok then
      log:misconfig(errmsg)
      return errcode
    end
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

  -- if necessary, converting old textual database format
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

  -- loading database
  local database, errmsg = opendb(dbpath)
  if database == nil then
    log:misconfig(msg.UnableToOpenDatabase:tag{
      path = dbpath,
      error = errmsg,
    })
    return errcode.UnableToOpenDatabase
  end

  -- utility validators functions
  local validators = {
    validator = {},
    tokenvalidator = {},
  }
  local valinfo = {
    validator = {
      loaded = msg.PasswordValidatorLoaded,
      notloaded = msg.PasswordValidatorIsNotLoaded,
      unloaded = msg.PasswordValidatorUnloaded,
      failedtermination = msg.FailedPasswordValidatorTermination,
      illegalerrmsg = msg.IllegalPasswordValidatorSpec,
      illegalerrcode = errcode.IllegalPasswordValidatorSpec,
      twiceerrmsg = msg.DuplicatedPasswordValidators,
      twiceerrcode = errcode.DuplicatedPasswordValidators,
      loaderrmsg = msg.UnableToLoadPasswordValidator,
      loaderrcode = errcode.UnableToLoadPasswordValidator,
      initerrmsg = msg.UnableToInitializePasswordValidator,
      initerrcode = errcode.UnableToInitializePasswordValidator,
      legacyerrmsg = msg.NoPasswordValidatorForLegacyDomain,
      legacyerrcode = errcode.NoPasswordValidatorForLegacyDomain,
    },
    tokenvalidator = {
      loaded = msg.TokenValidatorLoaded,
      notloaded = msg.TokenValidatorIsNotLoaded,
      unloaded = msg.TokenValidatorUnloaded,
      failedtermination = msg.FailedTokenValidatorTermination,
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
  local valpattern = "^([^:]-):?([^:]+)$"
  local function loadValidator(list, spec, info)
      local domain, package = match(spec, valpattern)
      if domain == nil then
        return info.illegalerrcode, info.illegalerrmsg:tag{
          specification = spec,
        }
      end
      local other = list[domain]
      if other ~= nil then
        return info.twiceerrcode, info.twiceerrmsg:tag{
          domain = domain,
          validator = package,
          other = other.name,
        }
      end
      local ok, result = pcall(require, package)
      if not ok then
        return info.loaderrcode, info.loaderrmsg:tag{
          domain = domain,
          validator = package,
          error = result,
        }
      end
      local validate, finalize = result(Configs)
      if validate == nil then
        local errmsg = finalize
        return info.initerrcode, info.initerrmsg:tag{
          domain = domain,
          validator = package,
          error = errmsg,
        }
      end
      list[domain] = {
        name = package,
        validate = validate,
        finalize = finalize,
      }
      return 0, info.loaded:tag{name=package,domain=domain}
  end

  local function loadAllValidators(action, configs, validators)
    for param, list in pairs(validators) do
      local info = valinfo[param]
      for _, spec in ipairs(configs[param]) do
        local retcode, msg = loadValidator(list, spec, info)
        if retcode > 0 then
          return retcode, msg
        else
          log[action](log, msg)
        end
      end
      if param == "validator"
      and not configs.nolegacy
      and list[configs.legacydomain] == nil then
        return info.legacyerrcode, info.legacyerrmsg:tag{ 
          domain = configs.legacydomain 
        }
      end
    end
    return 0
  end

  do -- load all password and token validators to be used
    local retcode, errmsg = loadAllValidators("config", Configs, validators)
    if retcode > 0 then
      log:misconfig(errmsg)
      return retcode
    end
  end

  -- create a set of admin users
  local adminUsers = { [BusEntity] = true }
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
  -- validate oil objrefaddr configuration
  local objrefaddr = {
    hostname = (not Configs.nodnslookup),
    ipaddress = (not Configs.noipaddress),
  }
  local additional = {}
  for _, address in ipairs(Configs.alternateaddr) do
    local host, port = address:match("^([%w%-%_%.]+):(%d+)$")
    port = tonumber(port)
    if (host ~= nil) and (port ~= nil) then
      additional[#additional+1] = { host = host, port = port }
    else
      log:misconfig(msg.WrongAlternateAddressSyntax:tag{
        value = address,
        expected = "host:port or ip:port",
      })
      return errcode.WrongAlternateAddress
    end
  end
  if (#additional > 0) then
    objrefaddr.additional = additional
  end
  log:config(msg.AdditionalInternetAddressConfiguration:tag(objrefaddr))
  -- validate audit configuration
  if Configs.enableaudit then
    local auditendpoint = Configs.auditendpoint
    if not auditendpoint:find("^http://") then
      log:misconfig(msg.InvalidAuditAgentHttpEndpoint:tag{url=auditendpoint})
      return errcode.MissingAuditServiceEndpoint
    end
    local credentials = Configs.auditcredentials
    if credentials ~= "" then
      if not credentials:find(":") then
        log:misconfig(msg.InvalidAuditAgentHttpCredentials:tag{expected="string user:password", given=credentials})
        return errcode.InvalidAuditAgentHttpCredentials
      end
      Configs.auditcredentials = b64encode(credentials)
    end
    if Configs.auditfifolimit < 1 then
      log:misconfig(msg.InvalidAuditAgentFifoLimit:tag{expected="must be at least 1"})
      return errcode.InvalidAuditAgentFifoLimit
    end
    if Configs.auditparallel < 1 then
      log:misconfig(msg.InvalidAuditAgentPublishingTasks:tag{expected="must be at least 1"})
      return errcode.InvalidAuditAgentPublishingTasks
    end
    if Configs.auditretrytimeout <= 0 then
      log:misconfig(msg.InvalidAuditAgentPublishingRetryTimeout:tag{excepted="must be greater than zero"})
      return errcode.InvalidAuditAgentPublishingRetryTimeout
    end
    for name, value in pairs(Configs) do
      if name:find("^audit") then
        if name == "auditcredentials" and value ~= "" then
          value = "*******" -- hidden password on logs
        end
        log:config(msg.AuditAgentParameters:tag{key=name, value=value})
      end
    end
  else
    log:config(msg.AuditAgentDisabled)
  end
  -- validate charsets supported
  Configs.nativecharset = Configs.nativecharset:lower()
  local nativecharset = Configs.nativecharset
  if nativecharset ~= "" then
    if not CORBACharsets[nativecharset] then
      local list = {}
      for name in pairs(CORBACharsets) do
        if type(name) == "string" then
          list[#list+1] = name
        end
      end
      log:misconfig(msg.CharsetNotSupported:tag{supported=list, parameter=nativecharset})
      return errcode.CharsetNotSupported
    else
      log:config(msg.NativeCharsetCodeSetConfigured:tag{charset=nativecharset})
    end
  end
  -- build orb instance
  local orb = initorb{
    host = Configs.host,
    port = getoptcfg(Configs, "port", 0),
    sslport = getoptcfg(Configs, "sslport", 0),
    maxchannels = getoptcfg(Configs, "maxchannels", 0),
    charset = getoptcfg(Configs, "nativecharset", ""),
    flavor = orbflv,
    options = orbopt,
    objrefaddr = objrefaddr,
  }
  if orbopt ~= nil then
    log:config(sslmode == "required" and msg.SecureConnectionEnforced
                                      or msg.SecureConnectionEnabled)
    log:config(msg.SecureConnectionPortNumber:tag{port=orb.sslport})
  end
  log:config(msg.ServicesListeningAddress:tag{host=orb.host,port=orb.port})
  if Configs.timeout ~= 0 then
    orb:settimeout(Configs.timeout)
  end

  -- build interceptor instance
  local iceptor = AuditInterceptor{
    prvkey = prvkey,
    orb = orb,
    maxcachesize = Configs.maxcachesize,
  }
  orb:setinterceptor(iceptor, "corba")
  loadidl(orb)
  logaddress = logaddress and iceptor.callerAddressOf

  local Configuration = {
    __type = ConfigurationType,
    __facet = "Configuration",
    __objkey = BusObjectKey.."/Configuration"
  }

  local AuditConfiguration = {
    __type = AuditConfigurationType,
    __facet = "AuditConfiguration",
    __objkey = BusObjectKey.."/AuditConfiguration"
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
    facets.AuditConfiguration = AuditConfiguration
  end

  function Configuration:__init(data)
    self.access = data.access
    self.admins = data.admins
    self.passwordValidators = data.passwordValidators
    self.tokenValidators = data.tokenValidators
    self.timeout = data.timeout
    local access = self.access
    local admins = self.admins
    access:setGrantedUsers(self.__type, "reloadConfigsFile", admins)
    access:setGrantedUsers(self.__type, "grantAdminTo", admins)
    access:setGrantedUsers(self.__type, "revokeAdminFrom", admins)
    access:setGrantedUsers(self.__type, "addValidator", admins)
    access:setGrantedUsers(self.__type, "delValidator", admins)
    access:setGrantedUsers(self.__type, "setMaxChannels", admins)
    access:setGrantedUsers(self.__type, "setMaxCacheSize", admins)
    access:setGrantedUsers(self.__type, "setCallsTimeout", admins)
    access:setGrantedUsers(self.__type, "setLogLevel", admins)
    access:setGrantedUsers(self.__type, "setOilLogLevel", admins)
    -- sugar syntax for password and token validators operations
    local adaptee = function(self, func, context)
      return function(self, ...)
        return func(self, context, ...)
      end
    end
    for _, kind in pairs{"Password", "Token"} do
      local context = {
        info = (kind == "Password") and valinfo.validator or valinfo.tokenvalidator,
        list = self[kind:lower().."Validators"],
      }
      self["get"..kind.."Validators"] = adaptee(self, self.getValidators, context)
      self["add"..kind.."Validator"] = adaptee(self, self.addValidator, context)
      self["del"..kind.."Validator"] = adaptee(self, self.delValidator, context)
      self["delAll"..kind.."Validators"] = adaptee(sef, self.delAllValidators, context)
    end
  end

  function Configuration:getValidators(context)
    local specs = {}
    for domain, validator in pairs(context.list) do
      specs[#specs+1] = domain..":"..validator.name
    end
    return specs
  end

  function Configuration:addValidator(context, spec)
    local list = context.list
    local info = context.info
    local retcode, retmsg = loadValidator(list, spec, info)
    if retcode > 0 then
      ServiceFailure{ message=retmsg }
    else
      log:admin(retmsg)
    end
  end

  function Configuration:delValidator(context, spec)
    local list = context.list
    local info = context.info
    local domain, name = match(spec, valpattern)
    local validator = list[domain]
    if not domain or not name then
      ServiceFailure{
        message = info.illegalerrmsg:tag{specification=spec}
      }
    end
    if not validator or (validator and name ~= validator.name) then
      ServiceFailure{
        message = info.notloaded:tag{
          domain = domain,
          validator = name,
        }
      }
    end
    list[domain] = nil
    package.loaded[name] = nil
    if validator.finalize ~= nil then
      local ok, errmsg = pcall(validator.finalize)
      if not ok then
        local errmsg = errmsg or msg.UnspecifiedTerminationFailure
        ServiceFailure{
          message = info.failedtermination:tag{
            domain = domain,
            validator = name,
            error = errmsg,
          }
        }
      end
    end
    log:admin(info.unloaded:tag{ domain=domain, validator=name })
  end

  function Configuration:delAllValidators(context)
    for domain, validator in pairs(context.list) do
      local spec = domain..":"..validator.name
      local ok, result = pcall(self.delValidator, self, context, spec)
      if not ok then
        log:exception(tostring(result))
      end
    end
  end

  function Configuration:shutdown()
    self:delAllPasswordValidators()
    self:delAllTokenValidators()
  end

  function Configuration:updateAdmins(entities, action)
    local admins = self.admins
    for _, entity in ipairs(entities) do
      if "grant" == action then
        if not admins[entity] then
          admins[entity] = true
          log:admin(msg.AdministrativeRightsGranted:tag{entity=entity})
        end
      else
        if entity ~= BusEntity and admins[entity] then
          admins[entity] = nil 
          log:admin(msg.AdministrativeRightsRevoked:tag{entity=entity})
        end
      end
    end
  end

  local function toarray(set)
    local array = {}
    for value in pairs(set) do
      array[#array+1] = value
    end
    return array
  end

  -- IDL operations
  function Configuration:reloadConfigsFile()
    local admins = self.admins
    local passwordValidators = self.passwordValidators
    local tokenValidators = self.tokenValidators
    -- load configuration from file
    loadConfigs()
    -- reconfigure its parameters
    self:setLogLevel(Configs.loglevel)
    self:setOilLogLevel(Configs.oilloglevel)
    self:setMaxChannels(Configs.maxchannels)
    self:setMaxCacheSize(Configs.maxcachesize)
    self:updateAdmins(toarray(self.admins), "revoke")
    self:updateAdmins(Configs.admin, "grant")
    self:delAllPasswordValidators()
    self:delAllTokenValidators()
    local retcode, errmsg = loadAllValidators("admin", Configs, {
      validator = passwordValidators,
      tokenvalidator = tokenValidators,
      })
    if retcode > 0 then
      ServiceFailure{
        message = errmsg
      }
    end
    self:setCallsTimeout(Configs.timeout)

    -- FIXME: must reload AuditConfiguration also!
  end

  function Configuration:grantAdminTo(entities)
    self:updateAdmins(entities, "grant")
  end

  function Configuration:revokeAdminFrom(entities)
    self:updateAdmins(entities, "revoke")
  end

  function Configuration:getAdmins()
    return toarray(self.admins)
  end

  function Configuration:setMaxChannels(maxchannels)
    local orb = self.access.orb
    local ok, errcode, errmsg = validateMaxChannels(maxchannels)
    if not ok then
      ServiceFailure{
        message = errmsg
      }
    end
    orb.ResourceManager.inuse.maxsize = maxchannels
    log:admin(msg.MaximumChannelLimit:tag{value=maxchannels})
  end

  function Configuration:getMaxChannels()
    local orb = self.access.orb
    return orb.ResourceManager.inuse.maxsize
  end

  function Configuration:setMaxCacheSize(maxsize)
    local ok, errcode, errmsg = validateMaxCacheSize(maxsize)
    if not ok then
      ServiceFailure{
        message = errmsg
      }
    end
    self.access:maxCacheSize(maxsize)
    log:admin(msg.MaximumCacheSize:tag{value=maxsize})
  end

  function Configuration:getMaxCacheSize()
    return self.access:maxCacheSize()
  end

  function Configuration:setCallsTimeout(timeout)
    local orb = self.access.orb
    if timeout == 0 then
      orb:settimeout(nil)
    elseif timeout > 0 then
      orb:settimeout(timeout)
    else
      ServiceFailure{
        message = msg.InvalidOrbCallsTimeout:tag{value=timeout}
      }
    end
    self.timeout = timeout
    log:admin(msg.OrbCallsTimeout:tag{value=timeout})
  end

  function Configuration:getCallsTimeout()
    return self.timeout
  end

  function Configuration:setLogLevel(loglevel)
    if loglevel >= 0 then
      log:level(loglevel)
      log:admin(msg.CoreServicesLogLevel:tag{value=loglevel})
    else
      ServiceFailure{
        message = msg.InvalidLogLevel:tag{value=loglevel}
      }
    end
  end

  function Configuration:getLogLevel()
    return log:level()
  end

  function Configuration:setOilLogLevel(loglevel)
    if loglevel >= 0 then
      oillog:level(loglevel)
      log:admin(msg.OilLogLevel:tag{value=loglevel})
    else
      ServiceFailure{
        message = msg.InvalidLogLevel:tag{value=loglevel}
      }
    end
  end

  function Configuration:getOilLogLevel()
    return oillog:level()
  end

  function AuditConfiguration:__init(data)
    local admins = data.admins
    local access = data.access
    local busid = access.busid
    -- grant permissions to admin
    access:setGrantedUsers(self.__type, "setAuditEnabled", admins)
    access:setGrantedUsers(self.__type, "setAuditHttpProxy", admins)
    access:setGrantedUsers(self.__type, "setAuditHttpAuth", admins) -- encrypted payload
    access:setGrantedUsers(self.__type, "getAuditHttpAuth", admins) -- encrypted payload
    access:setGrantedUsers(self.__type, "setAuditServiceURL", admins)
    access:setGrantedUsers(self.__type, "setAuditFIFOLimit", admins)
    access:setGrantedUsers(self.__type, "setAuditDiscardOnExit", admins)
    access:setGrantedUsers(self.__type, "setAuditPublishingTasks", admins)
    access:setGrantedUsers(self.__type, "setAuditPublishingRetryTimeout", admins)
    access:setGrantedUsers(self.__type, "setAuditEventTemplate", admins)
    -- audit configuration
    self.config = {
      agent = { -- see details at openbus.core.audit.Agent
        httpendpoint = Configs.auditendpoint,
        httpproxy = Configs.auditproxy ~= "" and Configs.auditproxy,
        httpcredentials = Configs.auditcredentials ~= "" and Configs.auditcredentials,
        concurrency = Configs.auditparallel,
        retrytimeout = Configs.auditretrytimeout,
        discardonexit = Configs.auditdiscardonexit,
        fifolimit = Configs.auditfifolimit,
      },
      event = { -- see details at openbus.core.audit.Event
        application = Configs.auditapplication,
        environment = Configs.auditenvironment ~= "" and Configs.auditenvironment or busid,
      },
    }
    -- initialize the event configuration
    self.access = access
    self.access.eventconfig = self.config.event
    -- start agent according to configuration
    self:setAuditEnabled(Configs.enableaudit, "config")
  end

  local function getCallerLoginInfo(self)
    local caller = self.access:getCallerChain().caller
    return {login=caller.id, entity=caller.entity}
  end

  function AuditConfiguration:setAuditEnabled(flag, loglevel)
    local tag = loglevel or "admin"
    local access = self.access -- bus interceptor with builtin audit feature
    local details = (tag == "admin" and getCallerLoginInfo(self)) or {entity=BusEntity}

    local agent = access.auditagent
    if not agent and (flag == true) then -- start
      access.auditagent = AuditAgent{ config = self.config.agent }
      log[tag](log, msg.AuditAgentEnabled:tag(details))
    end
    if agent and (flag == false) then -- stop
      access.auditagent = false
      agent:shutdown()
      log[tag](log, msg.AuditAgentDisabled:tag(details))
    end
  end

  function AuditConfiguration:getAuditEnabled()
    return self.access.auditagent ~= false
  end

  function AuditConfiguration:setAuditHttpProxy(proxy)
    self.config.agent.httpproxy = (proxy ~= "") and proxy
    local details = getCallerLoginInfo(self)
    details.proxy = proxy
    log:admin(msg.AuditAgentHttpProxyUpdated:tag(details))
  end

  function AuditConfiguration:getAuditHttpProxy()
    return self.config.agent.httpproxy or ""
  end

  function AuditConfiguration:setAuditHttpAuth(encrypted)
    local details = getCallerLoginInfo(self)
    local agentconfig = self.config.agent
    local buskey = self.access.prvkey
    local result, errmsg = buskey:decrypt(encrypted)
    if not result then
      ServiceFailure{
        message = msg.UnableToDecryptDataUsingBusPrivateKey:tag{error=errmsg}
      }
    end
    if result == "" or (result:find("\0") == 1) then
      agentconfig.httpcredentials = false
      log:admin(msg.AuditAgentHttpCredentialsRemoved:tag(details))
    else
      if not result:find(":") then
        ServiceFailure{
          message = msg.InvalidAuditAgentHttpCredentials:tag{
            expected="string user:password encrypted using bus public key"
          }
        }
      end
      agentconfig.httpcredentials = b64encode(result)
      log:admin(msg.AuditAgentHttpCredentialsUpdated:tag(details))
    end
  end

  function AuditConfiguration:getAuditHttpAuth()
    local caller = self.access:getCallerChain().caller
    local credentials = self.config.agent.httpcredentials or ""
    local pubkey = caller.pubkey
    if not pubkey then
      ServiceFailure{
        message = msg.MissingRemotePublicKey:tag{login=caller.id, entity=caller.entity}
      }
    else
      local encrypted, errmsg = pubkey:encrypt(b64decode(credentials))
      if not encrypted then
        ServiceFailure{
          message = msg.UnableToEncryptDataUsingRemotePublicKey:tag{login=caller.id, entity=caller.entity, error=errmsg}
        }
      else
        return encrypted
      end
    end
  end

  function AuditConfiguration:setAuditServiceURL(url)
    if not url:find("^http://") then
      ServiceFailure{
        message = msg.InvalidAuditAgentHttpEndpoint:tag{url=url, expected="a string starting with http://"}
      }
    end
    self.config.agent.httpendpoint = url
    local details = getCallerLoginInfo(self)
    details.url = url
    log:admin(msg.AuditAgentHttpEndpointUpdated:tag(details))
  end

  function AuditConfiguration:getAuditServiceURL()
    return self.config.agent.httpendpoint
  end

  function AuditConfiguration:setAuditFIFOLimit(limit)
    if limit < 1 then
      ServiceFailure{
        message = msg.InvalidAuditAgentFifoLimit:tag{expected="must be at least 1", given=limit}
      }
    end
    self.config.agent.fifolimit = limit
    local details = getCallerLoginInfo(self)
    details.limit = limit
    log:admin(msg.AuditAgentFifoLimitUpdated:tag(details))
  end

  function AuditConfiguration:getAuditFIFOLimit()
    return self.config.agent.fifolimit
  end

  function AuditConfiguration:getAuditFIFOLength()
    local agent = self.access.auditagent
    if not agent then
      ServiceFailure{
        message = msg.AuditAgentDisabled,
      }
    else
      return agent:fifolength()
    end
  end

  function AuditConfiguration:setAuditDiscardOnExit(flag)
    self.config.agent.discardonexit = flag
    local details = getCallerLoginInfo(self)
    details.activated = flag
    log:admin(msg.AuditAgentDiscardOnExitUpdated:tag(details))
  end

  function AuditConfiguration:getAuditDiscardOnExit()
    return self.config.agent.discardonexit
  end

  function AuditConfiguration:setAuditPublishingTasks(tasks)
    local current = self.config.agent.concurrency
    if self:getAuditEnabled() then
      ServiceFailure{
        message = msg.UnableToChangePublishingTasksWhileAgentIsRunning:tag{current=current}
      }
    end
    if tasks < 1 then
      ServiceFailure{
        message = msg.InvalidAuditAgentPublishingTasks:tag{expected="must be at least 1"}
      }
    end
    self.config.agent.concurrency = tasks
    local details = getCallerLoginInfo(self)
    details.concurrency = tasks
    log:admin(msg.AuditAgentPublishingTasksUpdated:tag(details))
  end

  function AuditConfiguration:getAuditPublishingTasks()
    return self.config.agent.concurrency
  end

  function AuditConfiguration:setAuditPublishingRetryTimeout(timeout)
    if timeout <= 0 then
      ServiceFailure{
        message = msg.InvalidAuditAgentPublishingRetryTimeout:tag{expected="must be greater than zero"}
      }
    end
    self.config.agent.retrytimeout = timeout
    local details = getCallerLoginInfo(self)
    details.retrytimeout = timeout
    log:admin(msg.AuditAgentPublishingRetryTimeoutUpdated:tag(details))
  end

  function AuditConfiguration:getAuditPublishingRetryTimeout()
    return self.config.agent.retrytimeout
  end

  function AuditConfiguration:setAuditEventTemplate(field, value)
    local eventconfig = self.config.event
    if not eventconfig[field] then
      ServiceFailure{
        message = msg.InvalidAuditEventTemplateFieldName:tag{name=field}
      }
    end
    self.config.event[field] = value
    local details = getCallerLoginInfo(self)
    details.field = field
    details.value = value
    log:admin(msg.AuditEventTemplateUpdated:tag(details))
  end

  function AuditConfiguration:getAuditEventTemplate()
    local result = {}
    for k,v in pairs(self.config.event) do
      result[#result+1] = {name=k, value=v}
    end
    log:print("getAuditEventTemplate=",result)
    return result
  end

  function AuditConfiguration:shutdown()
    schedule(newthread(function() self:setAuditEnabled(false) end), "last")
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
        timeout = Configs.timeout,
        leaseTime = Configs.leasetime,
        expirationGap = Configs.expirationgap,
        challengeTime = Configs.challengetime,
        sharedAuthTime = Configs.sharedauthtime,
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
      log:config(msg.OrbCallsTimeout:tag{value=params.timeout})
      log:config(msg.SetupLoginLeaseTime:tag{seconds=params.leaseTime})
      log:config(msg.SetupLoginExpirationGap:tag{seconds=params.expirationGap})
      log:config(msg.SetupLoginChallengeTime:tag{seconds=params.challengeTime})
      log:config(msg.SetupLoginSharedAuthTime:tag{seconds=params.sharedAuthTime})
      log:config(msg.BadPasswordPenaltyTime:tag{seconds=Configs.badpasswordpenalty})
      log:config(msg.BadPasswordLimitedTries:tag{limit=Configs.badpasswordtries})
      log:config(msg.BadPasswordTotalLimit:tag{value=Configs.badpasswordlimit})
      log:config(msg.BadPasswordMaxRate:tag{value=Configs.badpasswordrate})
      log:config(msg.MaximumChannelLimit:tag{value=Configs.maxchannels})
      log:config(msg.MaximumCacheSize:tag{value=Configs.maxcachesize})
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
      facets.AuditConfiguration:__init(params)
    end,
    shutdown = function(self)
      if iceptor:getCallerChain().caller.entity ~= BusEntity then
        NO_PERMISSION{ completed = "COMPLETED_NO" }
      end
      self.context:deactivateComponent()
      orb:shutdown()
      facets.AccessControl:shutdown()
      facets.Configuration:shutdown()
      facets.AuditConfiguration:shutdown()
      log:uptime(msg.CoreServicesTerminated)
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

  -- start services
  bus.IComponent:startup()
  log:uptime(msg.CoreServicesStarted)
end
