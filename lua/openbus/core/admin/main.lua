return function(...)
  local array = require "table"
  local concat = array.concat

  local _G = require "_G"
  local print = _G.print
  local select = _G.select

  local io = require "io"
  local openfile = io.open
  local stderr = io.stderr

  local os = require "os"
  local getenv = os.getenv

  local oillog = require "oil.verbose"

  local console = require "openbus.console.utils"
  local processargs = console.processargs

  local log = require "openbus.util.logger"
  local server = require "openbus.util.server"
  local ConfigArgs = server.ConfigArgs
  local setuplog = server.setuplog
  --local sandbox = require "openbus.util.sandbox"
  --local newsandbox = sandbox.create

  local msg = require "openbus.core.services.messages"
  local openbus = require "openbus"
  local initorb = openbus.initORB

  local script = require "openbus.core.admin.script"
  local newscriptenv = script.create

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

  -- TODO: assure it uses the same error code table as 'busservices'
  local errcode = {
    IllegalConfigurationParameter = 1,
    MissingSecureConnectionAuthenticationKey = 20,
    MissingSecureConnectionAuthenticationCertificate = 21,
    InvalidSecurityLayerMode = 23,
  }

  -- configuration parameters parser
  local executables = {}
  local Configs = ConfigArgs{
    iorfile = "",
    host = "localhost",
    port = 2089,
  
    sslmode = "",
    sslcafile = "",
    sslcapath = "",
    sslcert = "",
    sslkey = "",
    
    loglevel = 1,
    logfile = "",
    oilloglevel = 0,
    oillogfile = "",

    interactive = false,
    version = false,
    noenvironment = false,

    help = false,
  }
  function Configs:execute(_, value)
    executables[#executables+1] = {kind="code", value=value}
  end
  function Configs:load(_, value)
    executables[#executables+1] = {kind="module", value=value}
  end
  Configs._alias = {
    i = "interactive",
    v = "version",
    e = "execute",
    l = "load",
    E = "noenvironment",
    h = "help",
  }

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
  local argidx, errmsg = Configs(...)
  if argidx == nil then
    stderr:write(errmsg,"\n")
    Configs.help = true
  end
  if Configs.help then
    stderr:write([[
Usage:  ]],OPENBUS_PROGNAME,[[ [options] <script file> <script args>
Options:

  -iorfile <path>            arquivo onde o IOR do barramento deve ser gerado
  -host <address>            endereço de rede usado pelo barramento
  -port <number>             número da porta usada pelo barramento

  -sslmode <mode>            ativa o suporte SSL através das opções 'supported' ou 'required'
  -sslcapath <path>          diretório com certificados de CAs a serem usados na autenticação SSL
  -sslcafile <path>          arquivo com certificados de CAs a serem usados na autenticação SSL
  -sslcert <path>            arquivo com certificado do barramento
  -sslkey <path>             arquivo com chave privada do barramento

  -loglevel <number>         nível de log gerado pelo barramento
  -logfile <path>            arquivo de log gerado pelo barramento
  -oilloglevel <number>      nível de log gerado pelo OiL (debug)
  -oillogfile <path>         arquivo de log gerado pelo OiL (debug)

  -i, -interactive           ativa modo interativo
  -e, -execute <code>        executa o código Lua
  -l, -load <module>         carrega o módulo Lua
  -v, -version               exibe a versão do probrama

  -configs <path>            arquivo de configurações adicionais

  -h, -help                  exibe essa mensagem e encerra a execução
]])
    return errcode.IllegalConfigurationParameter
  end

  if #executables == 0 and argidx > select("#", ...) then
    Configs.interactive = true
    Configs.version = true
  end

  if Configs.version then
    local idl = require "openbus.core.idl"
    local version = concat({
      idl.const.MajorVersion,
      idl.const.MinorVersion,
      0,
      OPENBUS_CODEREV,
    }, ".")
    print("OpenBus Admin Console "..version..
          "  Copyright (C) 2006-2015 Tecgraf, PUC-Rio")
  end

  -- setup log files
  local logfile = setuplog(log, Configs.loglevel, Configs.logfile)
  if logfile ~= nil then OPENBUS_SETLOGPATH(logfile) end
  log:config(msg.CoreServicesLogLevel:tag{value=Configs.loglevel})
  setuplog(oillog, Configs.oilloglevel, Configs.oillogfile)
  log:config(msg.OilLogLevel:tag{value=Configs.oilloglevel})

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
    flavor = orbflv,
    options = orbopt,
  }
  if orbopt ~= nil then
    log:config(sslmode == "required" and msg.SecureConnectionEnforced
                                      or msg.SecureConnectionEnabled)
    log:config(msg.SecureConnectionPortNumber:tag{port=orb.sslport})
  end
  log:config(msg.ServicesListeningAddress:tag{host=orb.host,port=orb.port})

  newscriptenv(orb, Configs, _G)
  OPENBUS_EXITCODE = processargs(_G, Configs.noenvironment, Configs.interactive, executables, select(argidx, ...))
  _G.quit()
end
